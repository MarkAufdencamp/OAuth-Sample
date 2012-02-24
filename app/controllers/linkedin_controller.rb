require Rails.root.join('app', 'models', 'services', 'linkedin')

class LinkedinController < ApplicationController

  layout "service"

# http://developer.linkedin.com
# http://developer.linkedin.com/documents/authentication
# https://developer.linkedin.com/documents/oauth-overview
# https://developer.linkedin.com/documents/linkedins-oauth-details
# https://developer.linkedin.com/documents/getting-oauth-token
# https://developer.linkedin.com/documents/making-api-call-oauth-token
# https://developer.linkedin.com/documents/profile-api
# https://developer.linkedin.com/documents/connections-api


  def authorizeAccess
    # Retrieve Request Token from LinkedIn and Re-Direct to LinkedIn for Authentication    
    requestToken = LinkedInSocialService.requestToken
    #PP::pp requestToken, $stderr, 50
    if requestToken
      session[:linkedInRequestToken] = requestToken.token
      session[:linkedInRequestTokenSecret] = requestToken.secret
      redirect_to requestToken.authorize_url  
    else
      errorMsg = "Unable to retrieve Request Token"
      flash.now[:error] = errorMsg            
      redirect_to :action => :index
    end
  end
  
  def authorizationStatus
    # PP::pp session, $stderr, 50
    # Test the referrer
    # Retrieve and Test nonce
    # Compare session[:linkedInRequestToken], params[:oauth_token]
    if (params[:oauth_token] and params[:oauth_verifier] and !session[:linkedInAccessToken])
      # Store User Authoization Code
      session[:linkedInOAuthToken] = params[:oauth_token]
      session[:linkedInVerifier] = params[:oauth_verifier]
      session[:linkedInTokenBirth] = Time.now
      accessToken = LinkedInSocialService.newAccessToken( session[:linkedInRequestToken], session[:linkedInRequestTokenSecret], session[:linkedInVerifier] )
      PP::pp accessToken, $stderr, 50
      session[:linkedInAccessToken] = accessToken.token
      session[:linkedInAccessTokenSecret] = accessToken.secret
      session[:linkedInExpiresIn] = accessToken.params['oauth_expires_in']
      session[:linkedInAuthorizationExpiresIn] = accessToken.params['oauth_authorization_expires_in']
    end

    if !accessToken
      flash[:error] = params[:error]
    end
  end

  def revokeAccess
    # Housekeeping
    session[:linkedInRequestToken] = nil
    session[:linkedInRequestTokenSecret] = nil
    session[:linkedInOAuthToken] = nil
    # The one that really matters
    session[:linkedInVerifier] = nil  
    session[:linkedInAccessToken]  = nil
    session[:linkedInAccessTokenSecret] = nil
    
    redirect_to :action => :index    
  end

  def accessDenied
    
  end

  def retrieveLinkedInConnections
    # Retrieve Token and Verifier from URL     
    accessToken = LinkedInSocialService.accessToken(session[:linkedInAccessToken], session[:linkedInAccessTokenSecret])
    PP::pp accessToken, $stderr, 50
  
    # Retrieve LinkedIn ID and Connections
    @linkedInId = ''
    @linkedInName = ''
    @linkedInConnections = []
    linkedInProfile = LinkedInSocialService.linkedInProfile accessToken
    #PP::pp linkedInProfile, $stderr, 50
       
    @linkedInId = linkedInProfile['id']
    firstName = linkedInProfile['firstName']
    lastName = linkedInProfile['lastName']
    @linkedInName = firstName + " " + lastName
    linkedInConnections = LinkedInSocialService.linkedInConnections accessToken
    #PP::pp linkedInConnections, $stderr, 50
    @linkedInConnections = linkedInConnections
  
  end

  def signin
    
  end

private

  
end
