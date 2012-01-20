class GoogleController < ApplicationController
  
  layout "service"

# http://code.google.com/apis/contacts
# http://code.google.com/apis/contactsdocs/3.0/developers_guide_protocol.html
# http://code.google.com/apis/gdata/articles/using_ruby.html
# http://code.google.com/apis/accounts/docs/OAuth.html
# http://code.google.com/apis/accounts/docs/OAuth2.html
# http://code.google.com/apis/gdata/articles/oauth.html
# http://code.google.com/apis/gdata/faq.html#AuthScopes
# http://code.google.com/apis/gdata/docs/auth/oauth.html#Scope

  def authorizeGoogleAccess
    # Retrieve Request Token from Google and Re-Direct to Google for Authentication
    credentials = loadOAuthConfig 'Google'
    #logger.info 'Service URL - ' + credentials['Service URL']
    #logger.info 'Consumer Key - ' + credentials['Consumer Key']
    #logger.info 'Consumer Secret - ' + credentials['Consumer Secret']
    auth_consumer = getAuthConsumer credentials
    
    auth_scope = 'https://www.googleapis.com/auth/userinfo.profile https://www.google.com/m8/feeds/'
    request_token = auth_consumer.get_request_token({:oauth_callback => credentials['Callback URL'] }, {:scope => auth_scope})
    if request_token.callback_confirmed?
      #Store Token and Secret to Session
      session[:request_token] = request_token.token
      session[:request_token_secret] = request_token.secret
      # Redirect to Yahoo Authorization
      redirect_to request_token.authorize_url  
    else    
      flash.now[:error] = 'Error Retrieving OAuth Request Token from Google'            
    end
  end
  
  def retrieveGoogleContacts
    # Retrieve Token and Verifier from URL
    oauth_token = params[:oauth_token]
    oauth_verifier = params[:oauth_verifier]

    # Useful Debugging Information?
    #flash.now[:request_token] = "Request Token - " + session[:request_token]
    #flash.now[:request_token_secret] = "Request Token Secret - " + session[:request_token_secret]
    #flash.now[:oauth_token] = "OAuth Token - " + oauth_token
    #flash.now[:oauth_verifier] = "OAuth Verifier - " + oauth_verifier

    # Load Yahoo Credentials from comfig/oauth-config.yml
    credentials = loadOAuthConfig 'Google'

    # Factory a OAuth Consumer
    auth_consumer = getAuthConsumer credentials
    # Factory Request Token
    got_request_token = false
    begin
      request_token = OAuth::RequestToken.new(auth_consumer, session[:request_token], session[:request_token_secret])
      got_request_token = true
    rescue
      flash.now[:error] = 'Error Retrieving OAuth Request Token from Google'
    end  
    # Exchange Request Token for Access Token
    got_access_token = false
    if got_request_token
      begin
        access_token = request_token.get_access_token(:oauth_verifier => oauth_verifier)
        got_access_token = true
      rescue
        flash.now[:error] = 'Error Retrieving OAuth Access Token from Google'
      end  
    end
    
    # Retrieve Google GUID and Contacts
    @googleId = ''
    @googleName = ''
    @googleContacts = []
    if got_request_token and got_access_token
      userProfile = getGoogleProfile access_token
      @googleId = userProfile['id']
      @googleName = userProfile['name']
      @googleContacts = getGoogleContacts access_token
    end

  end

private

  def getAuthConsumer credentials
    OAuth::Consumer.new(credentials['Consumer Key'],
      credentials['Consumer Secret'],
        { 
        :site => credentials['Service URL'],
        :request_token_path => '/accounts/OAuthGetRequestToken',
        :authorize_path => '/accounts/OAuthAuthorizeToken',
        :access_token_path => '/accounts/OAuthGetAccessToken',
        :signature_method => "HMAC-SHA1"
        })        
  end
  
  def getGoogleProfile access_token
 
    profile_url = "https://www.googleapis.com/oauth2/v1/userinfo"
    response = access_token.get(profile_url)
    result = response.body
    data = JSON.parse(result)
    
  end

  def getGoogleContacts access_token
    # Google URL for Full Contact Retrieval
    #   "http://www.google.com/m8/feeds/contacts/default/full"
    # Alternately the Google userId can be substituted for default
    #   "http://www.google.com/m8/feeds/contacts/hostmaster@iluviya.net/full"
    # for JSON instead of XML contacts_url = "/m8/feeds/contacts/default/full?alt=json"
    contacts_url = "/m8/feeds/contacts/default/full"
    response = access_token.get(contacts_url)
    result = response.body
    # Convert the XML Response to a Hash
    data = XmlSimple::xml_in(result)
    #PP::pp data, $stderr, 50
    googleContacts = parseContactsResponse data
    
  end


  def parseContactsResponse doc

    googleContacts = []
    entries = doc['entry']
    entries.each { |entry|
      #logger.info entry
      contact_id  = entry["id"]
      #logger.info contact_id
      #contactName  = entry["title"]["text"]["content"]
      contactName  = entry["title"][0]["content"]
      #logger.info contactName
      if entry["email"]
        contactEMail = entry["email"][0]["address"]
      else
        contactEMail = ""
      end
      #logger.info contactEMail
      if entry["phoneNumber"]
        contactPhone = entry["phoneNumber"][0]["content"]
      else
        contactPhone = ""
      end
      #logger.info contactPhone

      contact = []
      contact << contact_id
      contact << contactName
      contact << contactEMail
      contact << contactPhone
      googleContacts << contact
    }
    googleContacts
  end
  
end
