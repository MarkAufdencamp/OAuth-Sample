class LinkedinController < ApplicationController
  layout "service"

# http://developer.linkedin.com
# http://developer.linkedin.com/documents/authentication
# https://developer.linkedin.com/documents/oauth-overview
# https://developer.linkedin.com/documents/linkedins-oauth-details
# https://developer.linkedin.com/documents/getting-oauth-token
# https://developer.linkedin.com/documents/making-api-call-oauth-token
# https://developer.linkedin.com/documents/profile-api
# https://developer.linkedin.com/documents/connections-api


  def authorizeLinkedInAccess
    # Retrieve Request Token from LinkedIn and Re-Direct to LinkedIn for Authentication
    credentials = loadOAuthConfig 'LinkedIn'
    #logger.info 'Service URL - ' + credentials['Service URL']
    #logger.info 'Consumer Key - ' + credentials['Consumer Key']
    #logger.info 'Consumer Secret - ' + credentials['Consumer Secret']
    auth_consumer = getAuthConsumer credentials
    #PP::pp auth_consumer, $stderr, 50
    
    request_token = auth_consumer.get_request_token(:oauth_callback => credentials['Callback URL'])
    if request_token.callback_confirmed?
      #Store Token and Secret to Session
      session[:request_token] = request_token.token
      session[:request_token_secret] = request_token.secret
      # Redirect to LinkedIn Authorization
      redirect_to request_token.authorize_url  
    else    
      flash.now[:error] = 'Error Retrieving OAuth Request Token from LinkedIn'            
    end


  end
  
  def retrieveLinkedInConnections
    # Retrieve Token and Verifier from URL
    oauth_token = params[:oauth_token]
    oauth_verifier = params[:oauth_verifier]
    #logger.info 'OAuth Token - ' + oauth_token
    #logger.info 'OAuth Verifier - '  + oauth_verifier
    
    # Useful Debugging Information?
    #flash.now[:request_token] = "Request Token - " + session[:request_token]
    #flash.now[:request_token_secret] = "Request Token Secret - " + session[:request_token_secret]
    #flash.now[:oauth_token] = "OAuth Token - " + oauth_token
    #flash.now[:oauth_verifier] = "OAuth Verifier - " + oauth_verifier

    # Load LinkedIn Credentials from comfig/oauth-config.yml
    credentials = loadOAuthConfig 'LinkedIn'
    #PP::pp credentials, $stderr, 50
 
    # Factory a OAuth Consumer
    auth_consumer = getAuthConsumer credentials
    
    # Factory Request Token
    got_request_token = false
    begin
      request_token = OAuth::RequestToken.new(auth_consumer, session[:request_token], session[:request_token_secret])
      got_request_token = true
    rescue
      flash.now[:error] = 'Error Retrieving OAuth Request Token from LinkedIn'
    end 
    #PP::pp request_token, $stderr, 50
     
    # Exchange Request Token for Access Token
    got_access_token = false
    if got_request_token
      begin
        access_token = request_token.get_access_token(:oauth_verifier => oauth_verifier)
        got_access_token = true
      rescue
        flash.now[:error] = 'Error Retrieving OAuth Access Token from LinkedIn'
      end  
    end
    #PP::pp access_token, $stderr, 50
  
    # Retrieve LinkedIn ID and Connections
    @linkedInId = ''
    @linkedInName = ''
    @linkedInConnections = []
    if got_request_token and got_access_token
      linkedInProfile = getLinkedInProfile access_token
      #PP::pp linkedInProfile, $stderr, 50
       
      @linkedInId = linkedInProfile['id']
      firstName = linkedInProfile['firstName']
      lastName = linkedInProfile['lastName']
      @linkedInName = firstName + " " + lastName
      linkedInConnections = getLinkedInConnections access_token
      #PP::pp linkedInConnections, $stderr, 50
      @linkedInConnections = linkedInConnections
    end
  
  end
  
  
private

  def getAuthConsumer credentials
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
  
  def getLinkedInProfile access_token
    # Pick some fields
    fields = ['id', 'first-name', 'last-name', 'headline', 'industry', 'num-connections'].join(',')
    
    # Make a request for JSON data
    json_txt = access_token.get("/v1/people/~:(#{fields})", 'x-li-format' => 'json').body
    profile = JSON.parse(json_txt)
    #PP::pp profile, $stderr, 50
 

  end 
  
  def getLinkedInConnections access_token
    # Pick some fields
    fields = ['id', 'first-name', 'last-name', 'headline', 'industry'].join(',')
    
    # Make a request for JSON data
    json_txt = access_token.get("/v1/people/~/connections:(#{fields})", 'x-li-format' => 'json').body
    connections = JSON.parse(json_txt)
    parseLinkedInConnections connections
  end
  
  def parseLinkedInConnections data
    
    #PP::pp data, $stderr, 50
    connections = data['values']
    
    connections_cnt = connections.length
    linkedInConnections = []
    for cnt in 0..connections_cnt-1 do
      connection = connections[cnt]
      #logger.info friend_id
      linkedInConnection = []
      linkedInConnection << connection['id']
      linkedInConnection << connection['firstName']
      linkedInConnection << connection['lastName']
      linkedInConnection << connection['headline']
      linkedInConnection << connection['industry']
      linkedInConnections << linkedInConnection
    end
    
    linkedInConnections
   
  end
  
end
