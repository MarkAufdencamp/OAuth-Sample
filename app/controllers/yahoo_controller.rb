require 'oauth'
require 'oauth/consumer'
require 'yaml'
require 'json'
require 'cgi'

class YahooController < ApplicationController

  layout "service"

# How to OAuth
# http://mojodna.net/2009/05/20/updating-ruby-consumers-and-providers-to-oauth-10a.html
# How to Hack Yahoo OAuth
# http://groups.google.com/group/oauth-ruby/browse_thread/thread/4059b81775752caf

  def retrieveContacts
    # Retrieve Request Token from Yahoo
    credentials = loadOAuthConfig 'Yahoo'
    consumer = OAuth::Consumer.new(credentials['Consumer Key'],
                  credentials['Consumer Secret'],
                  { :site => credentials['Service URL'],
                    :yahoo_hack => true,
                    :scheme => :query_string,
                    :http_method => :get,
                    :request_token_path => '/oauth/v2/get_request_token',
                    :access_token_path => '/oauth/v2/get_token',
                    :authorize_path => '/oauth/v2/request_auth'
                  })    
    request_token = consumer.get_request_token(:oauth_callback => 'http://iluviya.net/OAuth-Sample/yahoo/authorized/')
    if request_token.callback_confirmed?
      session[:request_token] = request_token.token
      session[:request_token_secret] = request_token.secret
      # Redirect to Yahoo Authorization
      redirect_to request_token.authorize_url
    else
      
    end
  end

  def authorized
    
    oauth_token = CGI::unescape params[:oauth_token]
    oauth_verifier = CGI::unescape params[:oauth_verifier]
    credentials = loadOAuthConfig 'Yahoo'
    consumer = OAuth::Consumer.new(credentials['Consumer Key'],
            credentials['Consumer Secret'],
                  { :site => credentials['Service URL'],
                    :yahoo_hack => true,
                    :scheme => :query_string,
                    :http_method => :get,
                    :request_token_path => '/oauth/v2/get_request_token',
                    :access_token_path => '/oauth/v2/get_token',
                    :authorize_path => '/oauth/v2/request_auth'
                  })    

    api_consumer = OAuth::Consumer.new(credentials['Consumer Key'],
                  credentials['Consumer Secret'],
                  { :site => 'http://social.yahooapis.com/',
                    :yahoo_hack => true,
                    :scheme => :header,
                    :realm => 'yahooapis.com',
                    :http_method => :get,
                    :request_token_path => '/oauth/v2/get_request_token',
                    :access_token_path => '/oauth/v2/get_token',
                    :authorize_path => '/oauth/v2/request_auth',
                    :format => 'json'
                  })    

    # Exchange Request Token for Access Token
    request_token = OAuth::RequestToken.new(consumer, session[:request_token], session[:request_token_secret])
    
    access_token = request_token.get_access_token(:oauth_verifier => oauth_verifier)
    access_token.consumer = api_consumer
    
    response = access_token.get('/v1/me/guid?format=json') 
    data = response.body
    result = JSON.parse(data)
    @guid = result['guid']['value']

    contacts_url = "/v1/user/" + @guid + "/contacts?format=json"
    response = access_token.get(contacts_url)
    data = response.body
    
    result = JSON.parse(data)
    contacts = result['contacts']['contact']
    contact_cnt = result['contacts']['total']
    #logger.info "Yahoo GUID - " + @guid
    @contacts = []
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
        @contacts << contact
        #logger.info contact_id
        #logger.info givenName + " " + familyName
        #logger.info email
      end
    end

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
end