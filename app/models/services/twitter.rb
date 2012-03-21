require Rails.root.join('app', 'models', 'services', 'socialservice')
require Rails.root.join('app', 'models', 'services', 'oauthconfig')

# https://dev.twitter.com/docs/api/1/get/users/lookup

class TwitterSocialService < SocialService
  
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
    
  def self.twitterUser accessToken, userId 
    user_url = "/1/users/lookup.json?user_id=#{ userId }"
    response = accessToken.get(user_url).body
    data = JSON.parse(response)
  end

  def self.twitterFriends accessToken, userId
    friends_url = "/1/friends/ids.json?cursor=-1&stringify_ids=true&user_id=#{ userId }"
    response = accessToken.get(friends_url).body
    data = JSON.parse(response)
    parseFriendsResponse data[ 'ids']
   end
  

private
  
  # Read OAuth Configuration file RAILS.root.join('config', 'oauth-key.yml) for Twitter Key
  def self.getOAuthConfig
    oauthConfig = OAuthConfig.new
    begin
      config = oauthConfig.loadOAuthConfig 'Twitter'
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
        :request_token_path => '/oauth/request_token',
        :authorize_path => '/oauth/authorize',
        :access_token_path => '/oauth/access_token',
        :signature_method => "HMAC-SHA1"
        })        
  end
  
  def self.getTokenConsumer credentials
    OAuth::Consumer.new(credentials['Consumer Key'],
      credentials['Consumer Secret'],
        { 
        :site => credentials['Service URL'],
        :request_token_path => '/oauth/request_token',
        :authorize_path => '/oauth/authorize',
        :access_token_path => '/oauth/access_token',
        :signature_method => "HMAC-SHA1"
        })        
  end
  
  def self.parseFriendsResponse friends
        
    friends_cnt = friends.length
    
    twitterFriends = []
    for cnt in 0..friends_cnt-1 do
      friend_id = friends[cnt]
      #logger.info friend_id
      friend = []
      friend << friend_id
      twitterFriends << friend
    end
    
    twitterFriends
    
  end

end