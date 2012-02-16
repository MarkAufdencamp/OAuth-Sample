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
      url = FacebookSocialService.authCodeURL
      redirect_to url
    rescue
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
      session[:facebookAuthCode] = params[:code]
      if(session[:facebookAuthCode] and !session[:facebookAccessToken])
        authCode = session[:facebookAuthCode]
        session[:facebookTokenBirth] = Time.now
        accessToken = FacebookSocialService.newAccessToken authCode
        PP::pp accessToken, $stderr, 50

        session[:facebookAccessToken] = accessToken.token
        session[:facebookTokenExpiresIn] = 3600
        #PP::pp session, $stderr, 50
        if !accessToken
          flash[:error] = "Error Retrieving AccessToken.  Authorization Code Present. FacebookSocialService.accessToken authCode failed to Return Token."
          redirect_to :action => :accessDenied        
        end
      else
        flash[:error] = "Error Retrieving Access Token.  No Authorization Code Found."
        redirect_to :action => :accessDenied
      end 
    end
    if !session[:facebookAuthCode]
      flash[:error] = params[:error]
    end
  end


  def revokeAccess
    session[:facebookAccessToken] = nil
    session[:facebookAuthCode] = nil
    redirect_to :action => :index    
  end

  def retrieveFacebookFriends
    #PP::pp params, $stderr, 50
    accessToken = FacebookSocialService.accessToken session[:facebookAccessToken]
    PP::pp accessToken, $stderr, 50
 
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


private
      
  
end
