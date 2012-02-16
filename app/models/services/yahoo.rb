require Rails.root.join('app', 'models', 'services', 'socialservice')
require Rails.root.join('app', 'models', 'services', 'oauthconfig')

# accessToken.@params['oauth_session_handle']
# How to OAuth
# http://mojodna.net/2009/05/20/updating-ruby-consumers-and-providers-to-oauth-10a.html
# How to Hack Yahoo OAuth
# http://groups.google.com/group/oauth-ruby/browse_thread/thread/4059b81775752caf

# http://developer.yahoo.com/oauth/
# http://developer.yahoo.com/oauth/guide/oauth-guide.html
# http://developer.yahoo.com/oauth/guide/oauth-scopes.html
# http://developer.yahoo.com/social/rest_api_guide/uri-general.html


class YahooSocialService < SocialService
  
  def self.requestToken 
    credentials = getOAuthConfig
    consumer = getAuthConsumer credentials
    consumer.get_request_token(:oauth_callback => credentials['Callback URL'])
  end
  
  def self.newAccessToken requestToken, requestTokenSecret, verifier
    credentials = getOAuthConfig
    consumer = getAuthConsumer credentials
    requestToken = OAuth::RequestToken.new(consumer, requestToken, requestTokenSecret)
    accessToken = requestToken.get_access_token(:oauth_verifier => verifier)
  end
  
  def self.accessToken accessToken, accessTokenSecret, sessionHandle
    credentials = getOAuthConfig
    consumer = getTokenConsumer credentials
    accessToken = OAuth::AccessToken.new(consumer, accessToken, accessTokenSecret)
  end

  def self.yahooGUID access_token
    response = access_token.get('/v1/me/guid?format=json') 
    data = response.body
    result = JSON.parse(data)
    result['guid']['value']    
  end

  def self.yahooProfile access_token,  guid
    profile_url = "/v1/user/" + guid + "/profile?format=json"
    response = access_token.get(profile_url)
    data = response.body
    profile = JSON.parse(data)
    #PP::pp profile, $stderr, 50
  end

  def self.yahooContacts access_token, guid
    contacts_url = "/v1/user/" + guid + "/contacts?format=json"
    response = access_token.get(contacts_url)
    data = response.body
    contacts = JSON.parse(data)
    #PP::pp contacts, $stderr, 50
    
    parseContactsResponse contacts
  end

private
  
  # Read OAuth Configuration file RAILS.root.join('config', 'oauth-key.yml) for Yahoo Key
  def self.getOAuthConfig
    oauthConfig = OAuthConfig.new
    begin
      config = oauthConfig.loadOAuthConfig 'Yahoo'
    rescue
      Kernel::raise errorMsg
    end
    config
  end
  
  def self.getAuthConsumer credentials
    OAuth::Consumer.new(credentials['Consumer Key'],
      credentials['Consumer Secret'],
        { :site => credentials['Service URL'],
        :yahoo_hack => true,
        :scheme => :query_string,
        :http_method => :get,
        :request_token_path => '/oauth/v2/get_request_token',
        :access_token_path => '/oauth/v2/get_token',
        :authorize_path => '/oauth/v2/request_auth'
        })        
  end
  
  def self.getTokenConsumer credentials
    OAuth::Consumer.new(credentials['Consumer Key'],
      credentials['Consumer Secret'],
        { :site => 'http://social.yahooapis.com/',
        :yahoo_hack => true,
        :scheme => :header,
        :realm => 'yahooapis.com',
        :http_method => :get,
        :request_token_path => '/oauth/v2/get_request_token',
        :access_token_path => '/oauth/v2/get_token',
        :authorize_path => '/oauth/v2/request_auth'
        })    
  end

  def self.refreshToken accessToken, accessTokenSecret, sessionHandle
    
    credentials = getOAuthConfig
    consumer = getAuthConsumer credentials
    requestToken = OAuth::RequestToken.new(consumer, accessToken, accessTokenSecret)
    token = OAuth::Token.new(accessToken, accessTokenSecret)
    accessToken = requestToken.get_access_token(
                         :oauth_session_handle => sessionHandle,
                         :token => token) 
  end
  
  
  def self.parseContactsResponse data

    contacts = data['contacts']['contact']
    contact_cnt = data['contacts']['total']
    yahooContacts = []
    for cnt in 0..contact_cnt-1 do
      contact = contacts[cnt]
      contact_id = contact['id']
      contactURI = contact['uri']
      fields = contact['fields']
      #logger.info fields
      #logger.info fields.length
      contactHasEMail = false
      givenName = ''
      familyName = ''
      email = ''
      fields.length.times do |field|
        #logger.info fields[field]['uri']
        #['giveName'] + " " + fields[field]['value']['familyName']
        if fields[field]['type'] == 'name' then
          givenName = fields[field]['value']['givenName']
          familyName = fields[field]['value']['familyName']
        end
        if fields[field]['type'] == 'email' then
          contactHasEMail = true
          email = fields[field]['value']
        end
      end
      if contactHasEMail then
        contact = []
        contact << contactURI
        contact << familyName
        contact << givenName
        contact << email        
        yahooContacts << contact
      end
    end
    yahooContacts
  end
 
end