require Rails.root.join('app', 'models', 'services', 'facebook')

class FacebookController < ApplicationController

  layout "service"

# http://developers.facebook.com/docs/authentication/
# http://developers.facebook.com/docs/reference/api/permissions/
# http://developers.facebook.com/docs/reference/api/
# http://developers.facebook.com/docs/reference/api/user/
# http://developers.facebook.com/docs/reference/api/FriendList/
# http://stackoverflow.com/questions/7717881/facebook-object-graph-https-request-from-ruby
# Facebook utilizes a two stage authentication
# stage 1 - User Authenticates and Allows Application Component Access. Returns an Access Code.
# Note: That the user grants the permissions requested in the scope variable of the authentication/authorization request.
# Stage 2 - The Stage 1 Access Code and the Application Id are utilized to request an Access Token, returns an Access Token.
# Note: This is a token for the user/app to access the permitted components. It expires and can be revoked!
# After a token has been acquired, one may utilize the Facebook API to access permitted components. i.e. User, FriendList
  
  def authorizeAccess
    # Retrieve Request Token from Facebook and Re-Direct to Facebook for Authentication
    begin
      # Generate and Store nonce
      url = FacebookSocialService.accessURL
      redirect_to url
    rescue
      errorMsg = "Unable to retrieve Access URL"
      flash[:error_description] = errorMsg
      redirect_to :action => :index
    end

  end
  
  def authorizationStatus
    #PP::pp session, $stderr, 50
    # Test the referrer
    # Retrieve and Test nonce
    if(params[:code] and params[:code] != '')
      # Store User Authoization Code
      session[:facebookAccessCode] = params[:code]
      if(session[:facebookAccessCode] and !session[:facebookAccessToken])
        authCode = session[:facebookAccessCode]
        session[:facebookTokenBirth] = Time.now
        accessToken = FacebookSocialService.newAccessToken authCode
        #PP::pp accessToken, $stderr, 50

        session[:facebookAccessToken] = accessToken.token
        session[:facebookTokenExpiresIn] = 3600
        #PP::pp session, $stderr, 50
        if !accessToken
          flash[:error] = "Error Retrieving Access Token.  Authorization Code Present. FacebookSocialService.accessToken authCode failed to Return Token."
          redirect_to :action => :accessDenied        
        end
      else
        flash[:error] = "Error Retrieving Access Token.  No Authorization Code Found."
        redirect_to :action => :accessDenied
      end 
    end
    if !session[:facebookAccessCode]
      flash[:error] = params[:error]
    end
  end


  def revokeAccess
    session[:facebookAccessToken] = nil
    session[:facebookAccessCode] = nil
    session[:facebookTokenBirth] = nil
    session[:facebookTokenExpiresIn] = nil
    redirect_to :action => :index    
  end

  def retrieveFacebookFriends
    #PP::pp params, $stderr, 50
    accessToken = FacebookSocialService.accessToken session[:facebookAccessToken]
    #PP::pp accessToken, $stderr, 50
 
    # Retrieve Facebook Profile and Friends
    @facebookId = ''
    @facebookName = ''
    @facebookFriends = []
    #gotToken = false
    if accessToken
      facebookMe = FacebookSocialService.facebookMe accessToken
      @facebookId = facebookMe['id']
      @facebookName = facebookMe['name']
      @facebookFriends = FacebookSocialService.facebookFriends accessToken
      #PP::pp @facebookFriends, $stderr, 50
    end
  end


  def accessDenied
    
  end

  def signin
    # Retrieve Request Token from Facebook and Re-Direct to Facebook for Authentication
    begin
      # Generate and Store nonce
      url = FacebookSocialService.signinURL
      redirect_to url
    rescue
      errorMsg = "Unable to retrieve Signin URL"
      flash[:error_description] = errorMsg
      redirect_to :action => :index
    end   
  end
  
  def userAuthenticated
   #PP::pp params, $stderr, 50
   #PP::pp session, $stderr, 50
    # Test the referrer
    # Retrieve and Test nonce
    if(params[:code] and params[:code] != '')
      # Store User Authoization Code
      session[:facebookSigninCode] = params[:code]
      session[:facebookSigninToken] = nil
      if(session[:facebookSigninCode] and !session[:facebookSigninToken])
        signinCode = session[:facebookSigninCode]
        #PP::pp authCode, $stderr, 50
        signinToken = FacebookSocialService.newSigninToken signinCode
        #PP::pp signinToken, $stderr, 50

        session[:facebookSigninToken] = signinToken.token
        if !signinToken
          flash[:error] = "Error Retrieving Signin Token.  Authorization Code Present. FacebookSocialService.accessToken authCode failed to Return Token."
          redirect_to :action => :accessDenied
          return   
        end
      else
        flash[:error] = "Error Retrieving Signin Token.  No Authorization Code Found."
        redirect_to :action => :accessDenied
        return
      end 
    end
    if !session[:facebookSigninCode]
      flash[:error] = params[:error]
    end
    
    # Retrieve the Use Email Address
    signinToken = FacebookSocialService.signinToken session[:facebookSigninToken]
    if signinToken
      facebookMe = FacebookSocialService.facebookMe signinToken
    end
    
    # Factory a User_Session
    if facebookMe
      #PP::pp facebookMe, $stderr, 50
      @facebookId = facebookMe['id']
      @facebookUserName = facebookMe['username']
      @facebookEMail = facebookMe['email']
      session[:facebookId] = @facebookId
      session[:facebookUserName] = @facebookUserName
      session[:facebookEMail] = @facebookEMail
    end
    
    
    redirect_to :controller => 'Welcome'
    
  end

private
      
  
end
