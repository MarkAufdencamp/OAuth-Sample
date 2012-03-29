require Rails.root.join('app', 'models', 'services', 'google')

class GoogleController < ApplicationController
  
  layout "service"

# http://code.google.com/apis/contacts
# http://code.google.com/apis/contactsdocs/3.0/developers_guide_protocol.html
# http://code.google.com/apis/gdata/articles/using_ruby.html
# http://code.google.com/apis/accounts/docs/OAuth.html
# http://code.google.com/apis/gdata/articles/oauth.html
# http://code.google.com/apis/gdata/faq.html#AuthScopes
# http://code.google.com/apis/gdata/docs/auth/oauth.html#Scope
#
# http://code.google.com/apis/accounts/docs/OAuth2.html
# http://code.google.com/apis/accounts/docs/OAuth2Login.html
# https://code.google.com/apis/console/


  def authorizeAccess
    begin
      url = GoogleSocialService.accessURL
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
      session[:googleAccessCode] = params[:code]
      if(session[:googleAccessCode] and !session[:googleAccessToken])
        authCode = session[:googleAccessCode]
        session[:googleTokenBirth] = Time.now
        accessToken = GoogleSocialService.newAccessToken authCode
        #PP::pp accessToken, $stderr, 50

        session[:googleAccessToken] = accessToken.token
        session[:googleRefreshToken] = accessToken.refresh_token
        session[:googleTokenExpiresIn] = accessToken.expires_in
        session[:googleIdToken] = accessToken.params['id_token']
        #PP::pp session, $stderr, 50
        # TODO: Save the Access Token
        if !accessToken
          flash[:error] = "Error Retrieving Access Token.  Authorization Code Present. GoogleSocialService.accessToken authCode failed to Return Token."
          redirect_to :action => :accessDenied        
        end
      else
        flash[:error] = "Error Retrieving Access Token.  No Authorization Code Found."
        redirect_to :action => :accessDenied
      end 

    end
    if !session[:googleAccessCode]
      flash[:error] = params[:error]
    end
  end

  def revokeAccess
    session[:googleRefreshToken] = nil
    session[:googleAccessToken] = nil
    session[:googleAccessCode] = nil
    session[:googleTokenExpiresIn] = nil
    session[:googleTokenBirth] = nil
    
    redirect_to :action => :index    
  end
  
  def retrieveGoogleContacts
    accessToken = GoogleSocialService.accessToken session[:googleAccessToken]
    #PP::pp accessToken, $stderr, 50
           
    # Retrieve Google GUID and Contacts
    @googleId = ''
    @googleName = ''
    @googleContacts = []
    if accessToken
      userProfile = GoogleSocialService.googleProfile accessToken
      @googleId = userProfile['id']
      googleName = userProfile['name']
      @googleContacts = GoogleSocialService.googleContacts accessToken
      #PP::pp @googleContacts, $stderr, 50
    end
  end
  
  def accessDenied
    
  end

  def signin
    begin
      url = GoogleSocialService.signinURL
      redirect_to url
    rescue
      errorMsg = "Unable to retrieve Signin URL"
      flash[:error_description] = errorMsg
      redirect_to :action => :index
    end    
  end
  
  def userAuthenticated
    #PP::pp session, $stderr, 50
    # Test the referrer
    # Retrieve and Test nonce
    if(params[:code] and params[:code] != '')
      # Store User Authoization Code
      session[:googleSigninCode] = params[:code]
      session[:googleSigninToken] = nil
      if(session[:googleSigninCode] and !session[:googleSigninToken])
        signinCode = session[:googleSigninCode]
        signinToken = GoogleSocialService.newSigninToken signinCode
        #PP::pp signinToken, $stderr, 50

        session[:googleSigninToken] = signinToken.token
        session[:googleIdToken] = signinToken.params['id_token']
        #PP::pp session, $stderr, 50

        if !signinToken
          flash[:error] = "Error Retrieving Signin Token.  Authorization Code Present. GoogleSocialService.signinToken authCode failed to Return Token."
          redirect_to :action => :accessDenied        
        end
      else
        flash[:error] = "Error Retrieving Signin Token.  No Authorization Code Found."
        redirect_to :action => :accessDenied
      end 

    end
    if !session[:googleSigninCode]
      flash[:error] = params[:error]
    end
    
    
    # Retrieve the Use Email Address
    signinToken = GoogleSocialService.signinToken session[:googleSigninToken]
    if signinToken
      userProfile = GoogleSocialService.googleProfile signinToken
    end
    
    # Factory a User_Session
    if userProfile
      #PP::pp userProfile, $stderr, 50
      @googleId = userProfile['id']
      @googleName = userProfile['name']
      @googleEMail = userProfile['email']
      session[:googleId] = @googleId
      session[:googleUserName] = @googleName
      session[:googleEMail] = @googleEMail
    end
    
    redirect_to :controller => 'Welcome'
     
  end

private
  
  
end
