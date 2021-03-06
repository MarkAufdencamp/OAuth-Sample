require Rails.root.join('app', 'models', 'services', 'yahoo')

class YahooController < ApplicationController

  layout "service"

  def authorizeAccess
    # Retrieve Request Token from LinkedIn and Re-Direct to LinkedIn for Authentication    
    requestToken = YahooSocialService.accessRequestToken
    #PP::pp requestToken, $stderr, 50
    if requestToken
      session[:yahooRequestToken] = requestToken.token
      session[:yahooRequestTokenSecret] = requestToken.secret
      redirect_to requestToken.authorize_url  
    else
      errorMsg = "Unable to retrieve Access Request Token"
      flash.now[:error] = errorMsg            
      redirect_to :action => :index
    end
  end
  
  def authorizationStatus
    #PP::pp session, $stderr, 50
    # Test the referrer
    # Retrieve and Test nonce
    # Compare session[:yahooRequestToken], params[:oauth_token]
    if (params[:oauth_token] and params[:oauth_verifier] and !session[:yahooAccessToken])
      # Store User Authoization Code
      session[:yahooOAuthToken] = params[:oauth_token]
      session[:yahooVerifier] = params[:oauth_verifier]
      # Timestamp Token Instantiation
      session[:yahooTokenBirth] = Time.now
      accessToken = YahooSocialService.newAccessToken( session[:yahooRequestToken], session[:yahooRequestTokenSecret], session[:yahooVerifier] )
      #PP::pp accessToken, $stderr, 50

      session[:yahooAccessToken] = accessToken.token
      session[:yahooAccessTokenSecret] = accessToken.secret

      session[:yahooGUId] = accessToken.params['xoauth_yahoo_guid']

      session[:yahooSessionHandle] = accessToken.params['oauth_session_handle']
      session[:yahooExpiresIn] = accessToken.params['oauth_expires_in']
      session[:yahooAuthorizationExpiresIn] = accessToken.params['oauth_authorization_expires_in']
    end

    if !accessToken
      flash[:error] = params[:error]
    end
  end

  def revokeAccess
    # Housekeeping
    session[:yahooRequestToken] = nil
    session[:yahooRequestTokenSecret] = nil
    session[:yahooOAuthToken] = nil
    # The one that really matters
    session[:yahooVerifier] = nil  
    session[:yahooAccessToken]  = nil
    session[:yahooAccessTokenSecret] = nil
    
    redirect_to :action => :index    
  end
  
  def accessDenied
    
  end


  def retrieveYahooContacts    
    # Retrieve Token and Verifier from URL
    accessToken = YahooSocialService.accessToken(session[:yahooAccessToken], session[:yahooAccessTokenSecret], session[:yahooSessionHandle])
    #PP::pp accessToken, $stderr, 50
    
    # Retrieve Yahoo GUID  and Contacts
    @yahooGUId = ''
    @yahooName = ''
    @yahooContacts = []
    @yahooGUId = YahooSocialService.yahooGUID accessToken
    profile = YahooSocialService.yahooProfile accessToken, @yahooGUId
    @yahooName = profile['profile']['nickname']
    @yahooContacts = YahooSocialService.yahooContacts accessToken, @yahooGUId
  end

  def signin
    # Retrieve Request Token from LinkedIn and Re-Direct to LinkedIn for Authentication    
    requestToken = YahooSocialService.signinRequestToken
    #PP::pp requestToken, $stderr, 50
    if requestToken
      session[:yahooRequestToken] = requestToken.token
      session[:yahooRequestTokenSecret] = requestToken.secret
      redirect_to requestToken.authorize_url  
    else
      errorMsg = "Unable to retrieve Signin Request Token"
      flash.now[:error] = errorMsg            
      redirect_to :action => :index
    end
  end

  def userAuthenticated
    #PP::pp session, $stderr, 50
    # Test the referrer
    # Retrieve and Test nonce
    # Compare session[:yahooRequestToken], params[:oauth_token]
    session[:yahooSigninToken] = nil
    if (params[:oauth_token] and params[:oauth_verifier] and !session[:yahooSigninToken])
      # Store User Authoization Code
      session[:yahooOAuthToken] = params[:oauth_token]
      session[:yahooVerifier] = params[:oauth_verifier]
      signinToken = YahooSocialService.newSigninToken( session[:yahooRequestToken], session[:yahooRequestTokenSecret], session[:yahooVerifier] )
      #PP::pp signinToken, $stderr, 50

      session[:yahooSigninToken] = signinToken.token
      session[:yahooSigninTokenSecret] = signinToken.secret
      session[:yahooSessionHandle] = signinToken.params['oauth_session_handle']

      session[:yahooGUId] = signinToken.params['xoauth_yahoo_guid']
    end

    signinToken = YahooSocialService.signinToken(session[:yahooSigninToken], session[:yahooSigninTokenSecret], session[:yahooSessionHandle])
    

    if !signinToken
      flash[:error] = params[:error]
      redirect_to :action => :accessDenied
      return
    end
    
    if signinToken
      @yahooGUId = YahooSocialService.yahooGUID signinToken
      profile = YahooSocialService.yahooProfile( signinToken, @yahooGUId )    
      #PP::pp profile, $stderr
    end
    
    if profile
      @yahooName = profile['profile']['nickname']
      session[:yahooGUId] = @yahooGUId
      session[:yahooUserName] = @yahooName
    end

    redirect_to :controller => 'Welcome'
  end
  
private
  
end