require Rails.root.join('app', 'models', 'services', 'twitter')

class TwitterController < ApplicationController
  
  layout "service"
    
# https://dev.twitter.com/
# https://dev.twitter.com/docs
# https://dev.twitter.com/docs/auth/oauth
# https://dev.twitter.com/docs/api
#
# https://dev.twitter.com/docs/api/1/get/friends/ids

  def authorizeAccess
    # Retrieve Request Token from LinkedIn and Re-Direct to LinkedIn for Authentication    
    requestToken = TwitterSocialService.accessRequestToken
    #PP::pp requestToken, $stderr, 50
    if requestToken
      session[:twitterRequestToken] = requestToken.token
      session[:twitterRequestTokenSecret] = requestToken.secret
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
    # Compare session[:twitterRequestToken], params[:oauth_token]
    if (params[:oauth_token] and params[:oauth_verifier] and !session[:twitterAccessToken])
      # Store User Authoization Code
      session[:twitterOAuthToken] = params[:oauth_token]
      session[:twitterVerifier] = params[:oauth_verifier]
      session[:twitterTokenBirth] = Time.now
      accessToken = TwitterSocialService.newAccessToken( session[:twitterRequestToken], session[:twitterRequestTokenSecret], session[:twitterVerifier] )
      #PP::pp accessToken, $stderr, 50

      session[:twitterAccessToken] = accessToken.token
      session[:twitterAccessTokenSecret] = accessToken.secret
      session[:twitterUserId] = accessToken.params[:user_id]
      session[:twitterScreenName] = accessToken.params[:screen_name]
    end

    if !accessToken
      flash[:error] = params[:error]
    end
  end

  def revokeAccess
    # Housekeeping
    session[:twitterUserId] = nil
    session[:twitterScreenName] = nil
    session[:twitterRequestToken] = nil
    session[:twitterRequestTokenSecret] = nil
    session[:twitterOAuthToken] = nil
    # The one that really matters
    session[:twitterVerifier] = nil  
    session[:twitterAccessToken]  = nil
    session[:twitterAccessTokenSecret] = nil
    
    redirect_to :action => :index    
  end
  
  def accessDenied
    
  end

  def retrieveTwitterFriends
    # Retrieve Token and Verifier from URL     
    accessToken = TwitterSocialService.accessToken(session[:twitterAccessToken], session[:twitterAccessTokenSecret])
    #PP::pp accessToken, $stderr, 50
    
    # Retrieve Twitter GUID and Contacts
    @twitterName = ''
    @twitterId = ''
    @twitterScreenName = ''
    @twitterFriends = []
    if accessToken
      @twitterScreenName = session[:twitterScreenName]
      
      userArray = TwitterSocialService.twitterUser( accessToken, session[:twitterUserId] )
      #PP::pp userArray, $stderr, 50
      
      user = userArray[0]
      #PP::pp user, $stderr, 50
      @twitterName = user['name']
      @twitterId = user['id_str']
      
      friends = TwitterSocialService.twitterFriends( accessToken, session[:twitterUserId] )
      #PP::pp friends, $stderr, 50
      @twitterFriends = friends
    end
    
  end

  def signin
   # Retrieve Request Token from LinkedIn and Re-Direct to LinkedIn for Authentication    
    requestToken = TwitterSocialService.signinRequestToken
    #PP::pp requestToken, $stderr, 50
    if requestToken
      session[:twitterRequestToken] = requestToken.token
      session[:twitterRequestTokenSecret] = requestToken.secret
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
    # Compare session[:twitterRequestToken], params[:oauth_token]
    session[:twitterSigninToken] = nil
    if (params[:oauth_token] and params[:oauth_verifier] and !session[:twitterSigninToken])
      # Store User Authoization Code
      session[:twitterOAuthToken] = params[:oauth_token]
      session[:twitterVerifier] = params[:oauth_verifier]
      signinToken = TwitterSocialService.newSigninToken( session[:twitterRequestToken], session[:twitterRequestTokenSecret], session[:twitterVerifier] )
      #PP::pp signinToken, $stderr, 50

      session[:twitterSigninToken] = signinToken.token
      session[:twitterSigninTokenSecret] = signinToken.secret
      session[:twitterUserId] = signinToken.params[:user_id]
      session[:twitterScreenName] = signinToken.params[:screen_name]
    end

    if !signinToken
      flash[:error] = params[:error]
      redirect_to :action => :accessDenied
      return
    end

    if signinToken
      userArray = TwitterSocialService.twitterUser( signinToken, session[:twitterUserId] )
      #PP::pp userArray, $stderr
    end
    
    if userArray
      @twitterScreenName = session[:twitterScreenName]
      user = userArray[0]
      @twitterName = user['name']
      @twitterId = user['id_str']
      session[:twitterUserName] = @twitterName
    end

    redirect_to :controller => 'Welcome'
  end
  
private
  
  
end
