require Rails.root.join('app', 'models', 'services', 'socialservice')
require Rails.root.join('app', 'models', 'services', 'oauthconfig')

class LinkedInSocialService < SocialService
  
  def self.signinRequestToken 
    credentials = getOAuthConfig
    consumer = getAuthConsumer credentials
    consumer.get_request_token(:oauth_callback => credentials['Signin Callback URL'])
  end
  
  def self.newSigninToken requestToken, requestTokenSecret, verifier
    credentials = getOAuthConfig
    consumer = getAuthConsumer credentials
    requestToken = OAuth::RequestToken.new(consumer, requestToken, requestTokenSecret)
    signinToken = requestToken.get_access_token(:oauth_verifier => verifier)
  end
  
  def self.signinToken signinToken, signinTokenSecret
    credentials = getOAuthConfig
    consumer = getTokenConsumer credentials
    accessToken = OAuth::AccessToken.new(consumer, signinToken, signinTokenSecret)
  end
  
  def self.accessRequestToken 
    credentials = getOAuthConfig
    consumer = getAuthConsumer credentials
    consumer.get_request_token(:oauth_callback => credentials['Access Callback URL'])
  end
  
  def self.newAccessToken requestToken, requestTokenSecret, verifier
    credentials = getOAuthConfig
    consumer = getAuthConsumer credentials
    requestToken = OAuth::RequestToken.new(consumer, requestToken, requestTokenSecret)
    accessToken = requestToken.get_access_token(:oauth_verifier => verifier)
  end
  
  def self.accessToken accessToken, accessTokenSecret
    credentials = getOAuthConfig
    consumer = getTokenConsumer credentials
    accessToken = OAuth::AccessToken.new(consumer, accessToken, accessTokenSecret)
  end
  
  def self.refreshToken accessToken
    
  end

  def self.linkedInProfile accessToken
    # Pick some fields
    fields = ['id', 'first-name', 'last-name', 'headline', 'industry', 'num-connections'].join(',')
    
    # Make a request for JSON data
    json_txt = accessToken.get("/v1/people/~:(#{fields})", 'x-li-format' => 'json').body
    profile = JSON.parse(json_txt)
    #PP::pp profile, $stderr, 50
  end
  
  def self.linkedInConnections accessToken
    # Pick some fields
    fields = ['id', 'first-name', 'last-name', 'headline', 'industry'].join(',')
    
    # Make a request for JSON data
    json_txt = accessToken.get("/v1/people/~/connections:(#{fields})", 'x-li-format' => 'json').body
    connections = JSON.parse(json_txt)
    parseLinkedInConnections connections['values']
  end
  
  private
  
  # Read OAuth Configuration file RAILS.root.join('config', 'oauth-key.yml) for LinkedIn Key
  def self.getOAuthConfig
    oauthConfig = OAuthConfig.new
    begin
      config = oauthConfig.loadOAuthConfig 'LinkedIn'
    rescue
      errorMsg = "Unable to load config/oauth-key.yml"
      Kernel::raise errorMsg
    end
    config
  end
  
  def self.getAuthConsumer credentials
    OAuth::Consumer.new(credentials['Consumer Key'],
      credentials['Consumer Secret'],
        { 
        :site => credentials['Service URL'],
        :request_token_path => '/uas/oauth/requestToken',
        :authorize_path => '/uas/oauth/authorize',
        :access_token_path => '/uas/oauth/accessToken',
        :signature_method => "HMAC-SHA1"
        })        
  end

  def self.getTokenConsumer credentials
    OAuth::Consumer.new(credentials['Consumer Key'],
      credentials['Consumer Secret'],
        { 
        :site => credentials['Service URL'],
        :request_token_path => '/uas/oauth/requestToken',
        :authorize_path => '/uas/oauth/authorize',
        :access_token_path => '/uas/oauth/accessToken',
        :signature_method => "HMAC-SHA1"
        })        
  end
  
  def self.parseLinkedInConnections connections
    
    connections_cnt = connections.length
    linkedInConnections = []
    for cnt in 0..connections_cnt-1 do
      connection = connections[cnt]
      #logger.info friend_id
      linkedInConnection = []
      linkedInConnection << connection['id']
      linkedInConnection << connection['firstName'] + " " + connection['lastName']
      linkedInConnection << connection['headline']
      linkedInConnection << connection['industry']
      linkedInConnections << linkedInConnection
    end
    
    linkedInConnections
   
  end

end