require Rails.root.join('app', 'models', 'services', 'socialservice')
require Rails.root.join('app', 'models', 'services', 'oauthconfig')

# http://msdn.microsoft.com/en-us/windowslive/
# Learn Live Connect
# http://msdn.microsoft.com/en-us/windowslive/ff621314
# Identity (profiles)
# http://msdn.microsoft.com/en-us/windowslive/hh278356
# Hotmail (contacts and calendars)
# http://msdn.microsoft.com/en-us/windowslive/hh528486
# Scopes and Permissions
# http://msdn.microsoft.com/en-us/library/hh243646.aspx
# Obtaining user consent
# http://msdn.microsoft.com/en-us/windowslive/hh278359

class WindowsLiveSocialService < SocialService
  
  def self.authCodeURL 
    credentials = getOAuthConfig
    client = getAuthConsumer credentials
    client.auth_code.authorize_url(
      :redirect_uri => credentials['Callback URL'],
      :scope => 'wl.signin,wl.basic,wl.offline_access',
      :grant_type => "authorization_code", 
      :response_type => "code")
  end
  
  
  def self.newAccessToken authCode   
    credentials = getOAuthConfig
    client = getTokenConsumer credentials

    #tokenURL = client.token_url(
    #  :client_id => credentials['Client Id'],
    #  :redirect_uri => credentials['Callback URL'],
    #  :client_secret => credentials['Client Secret'],
    #  :grant_type => "authorization_code",
    #  :code => authCode)
    #PP::pp tokenURL, $stderr, 50
      
    token = client.get_token( 
      :client_id => credentials['Client Id'],
      :redirect_uri => credentials['Callback URL'],
      :client_secret => credentials['Client Secret'],
      :grant_type => "authorization_code",
      :code => authCode,
      :parse => :json,
      :token_method => :get,
      :mode => :header,
      :param_name => 'bearer_token'
      )
  end
  
  def self.accessToken token   
    credentials = getOAuthConfig
    client = getTokenConsumer credentials
    
    OAuth2::AccessToken.new(client, token)
  end

  def self.windowsLiveMe token
    response = token.get("https://apis.live.net/v5.0/me")
    #PP::pp response.body, $stderr, 50
    result = response.body
    data = JSON.parse(result)
  end
  
  
  def self.windowsLiveContacts token
    response = token.get("https://apis.live.net/v5.0/me/contacts")
    #PP::pp response.body, $stderr, 50
    result = response.body
    data = JSON.parse(result)
    parseContactsResponse data['data']
  end  

  
private
  
  # Read OAuth Configuration file RAILS.root.join('config', 'oauth-key.yml) for Google Key
  def self.getOAuthConfig
    oauthConfig = OAuthConfig.new
    begin
      config = oauthConfig.loadOAuthConfig 'WindowsLive'
    rescue
      Kernel::raise errorMsg
    end
    config
  end

  # Factory OAuth2 Client from credentials hash
  def self.getAuthConsumer credentials
    OAuth2::Client.new(credentials['Client Id'],
      credentials['Client Secret'],
        :site => credentials['Service URL'],
        :authorize_url => '/authorize',
        :token_url => '/token'
        )     
  end
  
  # Factory OAuth2 Client from credentials hash
  def self.getTokenConsumer credentials
    OAuth2::Client.new(credentials['Client Id'],
      credentials['Client Secret'],
        :site => credentials['Service URL'],
        :authorize_url => '/authorize',
        :token_url => '/token'
        )     
  end


  def self.parseContactsResponse contacts
   contacts_cnt = contacts.length

    windowsLiveContacts = []
    for cnt in 0..contacts_cnt-1 do
      contact = contacts[cnt]
      contact_name = contact['name']
      contact_id = contact['id']
      #logger.info friend_name
      #logger.info friend_name
      contact = []
      contact << contact_name
      contact << contact_id
      windowsLiveContacts << contact
    end
    
    windowsLiveContacts
  end

end