require 'oauth'
require 'oauth/consumer'
require 'yaml'
require 'json'
require 'pp'

class YahooController < ApplicationController

  layout "service"

# How to OAuth
# http://mojodna.net/2009/05/20/updating-ruby-consumers-and-providers-to-oauth-10a.html
# How to Hack Yahoo OAuth
# http://groups.google.com/group/oauth-ruby/browse_thread/thread/4059b81775752caf

  def authorizeYahooAccess
    # Retrieve Request Token from Yahoo and Re-Direct to Yahoo for Authentication
    credentials = loadOAuthConfig 'Yahoo'
    #logger.info 'Service URL - ' + credentials['Service URL']
    #logger.info 'Consumer Key - ' + credentials['Consumer Key']
    #logger.info 'Consumer Secret - ' + credentials['Consumer Secret']
    auth_consumer = getAuthConsumer credentials
                  
    request_token = auth_consumer.get_request_token(:oauth_callback => 'http://iluviya.net/OAuth-Sample/yahoo/retrieveYahooContacts/')
    if request_token.callback_confirmed?
      #Store Token and Secret to Session
      session[:request_token] = request_token.token
      session[:request_token_secret] = request_token.secret
      # Redirect to Yahoo Authorization
      redirect_to request_token.authorize_url  
    else
      flash.now[:error] = 'Error Retrieving OAuth Request Token from Yahoo'            
    end
  end

  def retrieveYahooContacts    
    # Retrieve Token and Verifier from URL
    oauth_token = params[:oauth_token]
    oauth_verifier = params[:oauth_verifier]

    # Useful Debugging Information?
    flash.now[:request_token] = "Request Token - " + session[:request_token]
    flash.now[:request_token_secret] = "Request Token Secret - " + session[:request_token_secret]
    flash.now[:oauth_token] = "OAuth Token - " + oauth_token
    flash.now[:oauth_verifier] = "OAuth Verifier - " + oauth_verifier
    
    # Load Yahoo Credentials from comfig/oauth-config.yml
    credentials = loadOAuthConfig 'Yahoo'

    # Factory a OAuth Consumer - Yahoo Authorization Consumer requires using query_string scheme
    auth_consumer = getAuthConsumer credentials
    # Factory Request Token
    got_request_token = false
    begin
      request_token = OAuth::RequestToken.new(auth_consumer, session[:request_token], session[:request_token_secret])
      got_request_token = true
    rescue
      flash.now[:error] = 'Error Retrieving OAuth Request Token from Yahoo'
    end  
    # Exchange Request Token for Access Token
    got_access_token = false
    if got_request_token
      begin
        access_token = request_token.get_access_token(:oauth_verifier => oauth_verifier)
        got_access_token = true
      rescue
        flash.now[:error] = 'Error Retrieving OAuth Access Token from Yahoo'
      end  
    end
    
    # Retrieve Yahoo GUID  and Contacts
    @guid = ''
    @contacts = []
    if got_request_token and got_access_token
      # Factory a OAuth Consumer - Yahoo API Consumer requires using header scheme and a realm
      access_token.consumer = getAPIConsumer credentials
      @guid = getYahooGUID access_token
      @contacts = getYahooContacts access_token
    end
  end

  private

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
        :yahoo_hack => true,
        :scheme => :query_string,
        :http_method => :get,
        :request_token_path => '/oauth/v2/get_request_token',
        :access_token_path => '/oauth/v2/get_token',
        :authorize_path => '/oauth/v2/request_auth'
        })        
  end
  
  def getAPIConsumer credentials
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
  
  def getYahooGUID access_token
    response = access_token.get('/v1/me/guid?format=json') 
    data = response.body
    result = JSON.parse(data)
    result['guid']['value']    
  end
  
  def getYahooContacts access_token
    contacts_url = "/v1/user/" + @guid + "/contacts?format=json"
    response = access_token.get(contacts_url)
    data = response.body
    parseContactsResponse data
  end
  
  def parseContactsResponse data
    result = JSON.parse(data)
    #PP::pp result, $stderr, 50
    contacts = result['contacts']['contact']
    contact_cnt = result['contacts']['total']
    yahooContacts = []
    for cnt in 0..contact_cnt-1 do
      contact = contacts[cnt]
      contact_id = contact['id']
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
        contact << familyName
        contact << givenName
        contact << email        
        yahooContacts << contact
      end
    end
    yahooContacts
  end
  
end