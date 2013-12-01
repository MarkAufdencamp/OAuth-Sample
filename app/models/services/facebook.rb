require Rails.root.join('app', 'models', 'services', 'socialservice')
require Rails.root.join('app', 'models', 'services', 'oauthconfig')
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

# oauth-key.yml
#        Facebook:
#            Application URL: https://domain.tld/OAuth-Sample
#            Access Callback URL: https://domain.tld/OAuth-Sample/google/retrieveGoogleContacts
#            Signin Callback URL: https://domain.tld/OAuth-Sample/google/retrieveGoogleContacts
#            Service URL: https://accounts.google.com
#            Client Id: "xxxxxxxxxxxxx.apps.googleusercontent.com"
#            Client Secret: "xxxxxxxxxxxxxxxxxxxxxxxx"
#

class FacebookSocialService < SocialService
  
  def self.signinURL 
    credentials = getOAuthConfig
    client = getAuthConsumer credentials
    client.auth_code.authorize_url(:redirect_uri => credentials['Signin Callback URL'], :scope => 'user_about_me, email')
  end
  
  def self.mobileSigninURL 
    credentials = getOAuthConfig
    client = getAuthConsumer credentials
    client.auth_code.authorize_url(:redirect_uri => credentials['Mobile Callback URL'], :scope => 'user_about_me, email')
  end
  
  def self.newSigninToken authCode   
    credentials = getOAuthConfig
    client = getTokenConsumer credentials

    #tokenURL = client.token_url(
    #  :client_id => credentials['App ID'],
    #  :redirect_uri => credentials['Callback URL'],
    #  :client_secret => credentials['App Secret'],
    #  :code => authCode)
    #PP::pp tokenURL, $stderr, 50
    
    token = client.get_token( 
      :client_id => credentials['App ID'],
      :redirect_uri => credentials['Signin Callback URL'],
      :client_secret => credentials['App Secret'],
      :code => authCode,
      :parse => :query,
      :token_method => :get,
      :mode => :query,
      :param_name => 'access_token'
      )
  end

  def self.signinToken token
    credentials = getOAuthConfig
    client = getTokenConsumer credentials
    
    OAuth2::AccessToken.new(client, token)
  end

  def self.accessURL 
    credentials = getOAuthConfig
    client = getAuthConsumer credentials
    client.auth_code.authorize_url(:redirect_uri => credentials['Access Callback URL'], :scope => 'user_about_me,friends_about_me,offline_access')
  end

  def self.newAccessToken authCode   
    credentials = getOAuthConfig
    client = getTokenConsumer credentials

    #tokenURL = client.token_url(
    #  :client_id => credentials['App ID'],
    #  :redirect_uri => credentials['Callback URL'],
    #  :client_secret => credentials['App Secret'],
    #  :code => authCode)
    #PP::pp tokenURL, $stderr, 50
    
    token = client.get_token( 
      :client_id => credentials['App ID'],
      :redirect_uri => credentials['Access Callback URL'],
      :client_secret => credentials['App Secret'],
      :code => authCode,
      :parse => :query,
      :token_method => :get,
      :mode => :query,
      :param_name => 'access_token'
      )
  end

  def self.accessToken token
    credentials = getOAuthConfig
    client = getTokenConsumer credentials
    
    OAuth2::AccessToken.new(client, token)
  end

  def self.facebookMe token
    response = token.get("https://graph.facebook.com/me", :params => { :access_token => token.token })
    #PP::pp response.body, $stderr, 50
    result = response.body
    data = JSON.parse(result)
  end
  
  
  def self.facebookFriends token
    response = token.get("https://graph.facebook.com/me/friends", :params => { :access_token => token.token })
    #PP::pp response.body, $stderr, 50
    result = response.body
    data = JSON.parse(result)
    parseFacebookFriends data['data']    
  end
  
   
private

  # Read OAuth Configuration file RAILS.root.join('config', 'oauth-key.yml) for Google Key
  def self.getOAuthConfig
    oauthConfig = OAuthConfig.new
    begin
      config = oauthConfig.loadOAuthConfig 'Facebook'
    rescue
      Kernel::raise errorMsg
    end
    config
  end


  # Factory OAuth2 Client from credentials hash
  def self.getAuthConsumer credentials
    OAuth2::Client.new(credentials['App ID'],
      credentials['App Secret'],
        :site => credentials['Service URL'],
        :authorize_url => '/dialog/oauth',
        :token_url => '/oauth/access_token'
        )     
  end


  # Factory OAuth2 Client from credentials hash
  def self.getTokenConsumer credentials
    OAuth2::Client.new(credentials['App ID'],
      credentials['App Secret'],
        :site => 'https://graph.facebook.com',
        :authorize_url => '/dialog/oauth',
        :token_url => '/oauth/access_token'
        )     
  end
  
  
  def self.parseFacebookFriends friends
    
    friends_cnt = friends.length

    facebookFriends = []
    for cnt in 0..friends_cnt-1 do
      friend = friends[cnt]
      friend_name = friend['name']
      friend_id = friend['id']
      #logger.info friend_name
      #logger.info friend_name
      friend = []
      friend << friend_name
      friend << friend_id
      facebookFriends << friend
    end
    
    facebookFriends
  end
  
end