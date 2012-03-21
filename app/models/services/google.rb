require Rails.root.join('app', 'models', 'services', 'socialservice')
require Rails.root.join('app', 'models', 'services', 'oauthconfig')

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

# https://github.com/binarylogic/authlogic_openid
# https://github.com/ryanb/nifty-generators
# http://railscasts.com/episodes/67-restful-authentication
# http://railscasts.com/episodes/121-non-active-record-model
# http://railscasts.com/episodes/160-authlogic
# http://railscasts.com/episodes/170-openid-with-authlogic
#
# http://code.google.com/apis/accounts/docs/OpenID.html
# https://dev.twitter.com/docs/auth/browser-sign-flow
# http://developers.facebook.com/docs/guides/web/
# http://openid.net/connect/
# http://msdn.microsoft.com/en-us/live/hh561433
#
# http://phpmaster.com/where-on-earth-are-you/?utm_medium=email&utm_campaign=PHPMaster+Newsletter+-+14+February+2012&utm_content=PHPMaster+Newsletter+-+14+February+2012+CID_74916e0e4419b88d00a20298405b1a53&utm_source=Newsletter&utm_term=More
#
#
#
#
#
#
#



#
# oauth-key.yml
#        Google:
#            Application URL: https://domain.tld/OAuth-Sample
#            Access Callback URL: https://domain.tld/OAuth-Sample/google/retrieveGoogleContacts
#            Signin Callback URL: https://domain.tld/OAuth-Sample/google/retrieveGoogleContacts
#            Service URL: https://accounts.google.com
#            Client Id: "xxxxxxxxxxxxx.apps.googleusercontent.com"
#            Client Secret: "xxxxxxxxxxxxxxxxxxxxxxxx"
#

class GoogleSocialService < SocialService
  


  def self.signinURL 
    credentials = getOAuthConfig
    client = getAuthConsumer credentials
    client.auth_code.authorize_url(:redirect_uri => credentials['Signin Callback URL'], :scope => 'https://www.googleapis.com/auth/userinfo.profile https://www.googleapis.com/auth/userinfo.email', :access_type => "online", :approval_prompt => "auto")
  end
  
  def self.newSigninToken authCode   
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
      :redirect_uri => credentials['Signin Callback URL'],
      :client_secret => credentials['Client Secret'],
      :grant_type => "authorization_code", 
      :code => authCode,
      :parse => :json,
      :token_method => :post,
      :mode => :header
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
    client.auth_code.authorize_url(:redirect_uri => credentials['Access Callback URL'], :scope => 'https://www.googleapis.com/auth/userinfo.profile https://www.googleapis.com/auth/userinfo.email https://www.google.com/m8/feeds/', :access_type => "offline", :approval_prompt => "force")
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
      :redirect_uri => credentials['Access Callback URL'],
      :client_secret => credentials['Client Secret'],
      :grant_type => "authorization_code", 
      :code => authCode,
      :parse => :json,
      :token_method => :post,
      :mode => :header
      )

  end
  

  def self.accessToken token   
    credentials = getOAuthConfig
    client = getTokenConsumer credentials
    
    OAuth2::AccessToken.new(client, token)
  end
  
  
  def self.googleProfile token
    response = token.get("https://www.googleapis.com/oauth2/v1/userinfo")
    #PP::pp response.body, $stderr, 50
    result = response.body
    data = JSON.parse(result)
  end
  
  
  def self.googleContacts accessToken
    response = token.get("https://www.google.com/m8/feeds/contacts/default/full", :params => { 'v' => '3.0', 'alt' => 'json'} )
    #PP::pp response.body, $stderr, 50
    result = response.body
    data = JSON.parse(result)
    parseGoogleContacts data['feed']['entry']
  end  

  
private
  
  # Read OAuth Configuration file RAILS.root.join('config', 'oauth-key.yml) for Google Key
  def self.getOAuthConfig
    oauthConfig = OAuthConfig.new
    begin
      config = oauthConfig.loadOAuthConfig 'Google'
    rescue
      errorMsg = "Unable to load config/oauth-key.yml"
      Kernel::raise errorMsg
    end
    config
  end

  # Factory OAuth2 Client from credentials hash
  def self.getAuthConsumer credentials
    OAuth2::Client.new(credentials['Client Id'],
      credentials['Client Secret'],
        :site => credentials['Service URL'],
        :authorize_url => '/o/oauth2/auth',
        :token_url => '/o/oauth2/token'
        )     
  end
  
  # Factory OAuth2 Client from credentials hash
  def self.getTokenConsumer credentials
    OAuth2::Client.new(credentials['Client Id'],
      credentials['Client Secret'],
        :site => credentials['Service URL'],
        :authorize_url => '/o/oauth2/auth',
        :token_url => '/o/oauth2/token'
        )     
  end


  # Parse Google Contacts JSON response into Array
  def self.parseGoogleContacts contacts
    googleContacts = []
    #PP::pp contacts, $stderr, 50
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
        #PP::pp gdEMail[0], $stderr, 50
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

  def self.isTokenExpired?
  
  end

end