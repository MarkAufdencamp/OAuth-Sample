require 'oauth'
require 'oauth/consumer'
require 'yaml'
require 'json'

class GoogleController < ApplicationController
  
  layout "service"
  
  def authorizeGoogleAccess
    # Retrieve Request Token from Yahoo and Re-Direct to Yahoo for Authentication
    credentials = loadOAuthConfig 'Google'
    logger.info credentials['Service URL']
    logger.info credentials['Consumer Key']
    logger.info credentials['Consumer Secret']
    auth_consumer = getAuthConsumer credentials
                  
    request_token = auth_consumer.get_request_token(:oauth_callback => 'http://iluviya.net/OAuth-Sample/google/retrieveGoogleContacts')
    if request_token.callback_confirmed?
      #Store Token and Secret to Session
      session[:request_token] = request_token.token
      session[:request_token_secret] = request_token.secret
      # Redirect to Yahoo Authorization
      redirect_to request_token.authorize_url  
    else    
      flash[:error] = 'Error Retrieving OAuth Request Token from Google'            
    end
  end
  
  def retrieveGoogleContacts
    oauth_token = params[:token]
    flash[:notice] = oauth_token
  end
  
  def loadOAuthConfig serviceName
    credentials = Hash.new
    authKeys = YAML::load_file("#{RAILS_ROOT}/config/oauth-key.yml") [RAILS_ENV]
    authKeys.each_key do | key |
      if key[serviceName]
        credentials['Consumer Key'] = authKeys[key]['Consumer Key']
        credentials['Consumer Secret'] = authKeys[key]['Consumer Secret']
        credentials['Service URL'] = authKeys[key]['Service URL']
      end
    end
    credentials
  end

  def getAuthConsumer credentials
    OAuth::Consumer.new(credentials['Consumer Key'],
      credentials['Consumer Secret'],
        { :site => credentials['Service URL'],
        :scheme => :query_string,
        :http_method => :get,
        :request_token_path => '/accounts/OauthGetRequestToken',
        :access_token_path => '/accounts/OAuthAuthorizeToken',
        :authorize_path => '/accounts/OAuthGetAccessToken'
        })        
  end
  
end
