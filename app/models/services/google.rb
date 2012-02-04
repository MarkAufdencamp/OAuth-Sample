require Rails.root.join('app', 'models', 'services', 'socialservice')
require Rails.root.join('app', 'models', 'services', 'oauthconfig')

require 'net/http'
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

#
# oauth-key.yml
#        Google:
#            Application URL: https://domain.tld/OAuth-Sample
#            CallbackURL: https://domain.tld/OAuth-Sample/google/retrieveGoogleContacts
#            Service URL: https://accounts.google.com
#            Client Id: "xxxxxxxxxxxxx.apps.googleusercontent.com"
#            Client Secret: "xxxxxxxxxxxxxxxxxxxxxxxx"
#

class GoogleSocialService < SocialService
  
  def self.getOAuthConfig
    oauthConfig = OAuthConfig.new
    begin
      config = oauthConfig.loadOAuthConfig 'Google'
    rescue
      Kernel::raise errorMsg
    end
    config
  end

  def self.getAuthConsumer
    credentials = getOAuthConfig
    OAuth2::Client.new(credentials['Client Id'],
      credentials['Client Secret'],
        { 
        :site => credentials['Service URL'],
        #:ssl =>  {
          
        #  },
        :authorize_url => '/o/oauth2/auth',
        :token_url => '/o/oauth2/token',
        :token_method => :post,
        #:connection_opts => {
          
        #  }
        })        
  end

  def self.getAuthCodeURL 
      begin
        credentials = getOAuthConfig
      rescue
        Kernel::raise errorMsg
      end
      auth_scope = "scope=https://www.googleapis.com/auth/userinfo.profile+https://www.google.com/m8/feeds/"
      url = "#{credentials['Service URL']}/o/oauth2/auth?client_id=#{credentials['Client Id']}&#{auth_scope}&redirect_uri=#{credentials['Callback URL']}&response_type=code&access_type=offline"
  end
  

  def self.getAccessToken authCode
    
    credentials = getOAuthConfig
    params ="client_id=#{credentials['Client Id']}&redirect_uri=#{credentials['Callback URL']}&client_secret=#{credentials['Client Secret']}&code=access_code&grant_type=authorization_code"
    url = "#{credentials['Service URL']}/o/oauth2/token?client_id=#{credentials['Client Id']}&redirect_uri=#{credentials['Callback URL']}&client_secret=#{credentials['Client Secret']}&code=#{CGI.escape(authCode)}&grant_type=authorization_code"
    #url = "#{credentials['Service URL']}/o/oauth/token"
    uri = URI.parse(url)
    headers = {
      'Host' => 'accounts.google.com',
      'Referer' => credentials['Callback URL'],
      'Content-Type' => 'application/x-www-form-urlencoded'
    }

    http = Net::HTTP.new(uri.host, 443)
    http.use_ssl = true
  
    #puts 'URI Scheme - '
    #PP::pp uri.scheme, $stderr, 50
    #puts 'URI Host - '
    #PP::pp uri.host, $stderr, 50
    #puts 'URI Port - '
    #PP::pp uri.port, $stderr, 50
    #puts 'URI Path - '
    #PP::pp uri.path, $stderr, 50
    #puts 'URI Query - '
    #PP::pp uri.query, $stderr, 50

    response, data = http.post(uri.path, uri.query, headers)
    #puts 'Response Code - ' + response.code
    #puts 'Response Message' + response.message
    #PP::pp response, $stderr, 50
    #PP::pp data, $stderr, 50

    # Split the response into the access_token and the expires
    #PP::pp response.body, $stderr, 50
    json_data = JSON.parse(response.body)        
    access_token = json_data['access_token']
    #PP::pp access_token, $stderr, 50
    token_type = json_data['token_type']
    #PP::pp token_type, $stderr, 50
    expires = json_data['expires_in']
    #PP::pp expires, $stderr, 50
    
    access_token
    
  end

  
  def self.refreshToken accessToken
    
  end

    
  def self.getGoogleProfile access_token
    credentials = getOAuthConfig
    profile_url = "https://www.googleapis.com/oauth2/v1/userinfo"
    params = "?access_token=#{CGI.escape(access_token)}"
    url = profile_url + params
    uri = URI.parse(url)
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(uri.path + "?" + uri.query)
    response = http.request(request)
    result = response.body
    
    data = JSON.parse(result)
  end


  def self.getGoogleContacts access_token

    # Google URL for Full Contact Retrieval
    #   "http://www.google.com/m8/feeds/contacts/default/full"
    # Alternately the Google userId can be substituted for default
    #   "http://www.google.com/m8/feeds/contacts/hostmaster@iluviya.net/full"
    # for JSON instead of XML contacts_url = "/m8/feeds/contacts/default/full?alt=json"
    contacts_url = "https://www.google.com/m8/feeds/contacts/default/full"

    credentials = getOAuthConfig
    params = "?access_token=#{CGI.escape(access_token)}&v=3.0&alt=json"
    url = contacts_url + params
    uri = URI.parse(url)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(uri.path + "?" + uri.query)
    response = http.request(request)
    result = response.body
    data = JSON.parse(result)
    parseGoogleContacts data['feed']['entry']
  end
  
  
  def self.parseGoogleContacts contacts
    googleContacts = []
    PP::pp contacts, $stderr, 50
    contacts_cnt = contacts.length
    for cnt in 0..contacts_cnt-1 do
      contact = contacts[cnt]
      
      contact_id = ""
      gdId = contact['id']
      if gdId
        contact_id = gdId['$t']
      end
      
      contact_name = ""
      gdName = contact['gd$name']
      if gdName
        gdFullName = gdName['gd$fullName']
        if gdName['gd$fullName']
          contact_name = gdName['gd$fullName']['$t']
        end
      end      
      
      contact_address = ""
      if contact['gd$email']
        gdEMail = contact['gd$email']
        contact_address = gdEMail[0]['address']
        PP::pp gdEMail[0], $stderr, 50
        #gdAddress
      end
      
      contact_Phone = ""
      if contact['gd$phoneNumber']
        gdPhoneNumber = contact['gd$phoneNumber']
        contact_phone = gdPhoneNumber[0]['$t']
      end
      
      contact = []
      #contact << contact_name
      if (contact_id && contact_name)
        contact << contact_name
        contact << CGI.unescape( contact_id )
        contact << contact_address
        contact << contact_phone
        googleContacts << contact
      end
      
    end
    
    googleContacts 
  end
  
  
  def self.getOAuth2AccessToken authCode

    credentials = getOAuthConfig
    client = getAuthConsumer
    #PP::pp client, $stderr, 50
    client.auth_code.authorize_url( :redirect_uri => credentials['Callback URL'])
    token = client.auth_code.get_token( authCode, :redirect_uri => credentials['Callback URL'])
    
  end
    
end