class TwitterController < ApplicationController
  layout "service"
  
# https://dev.twitter.com/
# https://dev.twitter.com/docs
# https://dev.twitter.com/docs/auth/oauth
# https://dev.twitter.com/docs/api
#
# https://dev.twitter.com/docs/api/1/get/friends/ids

  def authorizeTwitterAccess
    # Retrieve Request Token from Twitter and Re-Direct to Twitter for Authentication
    credentials = loadOAuthConfig 'Twitter'
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
      # Redirect to Twitter Authorization
      redirect_to request_token.authorize_url  
    else    
      flash.now[:error] = 'Error Retrieving OAuth Request Token from Twitter'            
    end

  end
  
  def retrieveTwitterFriends
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

    # Load Twitter Credentials from comfig/oauth-config.yml
    credentials = loadOAuthConfig 'Twitter'
    #PP::pp credentials, $stderr, 50
 
    # Factory a OAuth Consumer
    auth_consumer = getAuthConsumer credentials
    
    # Factory Request Token
    got_request_token = false
    begin
      request_token = OAuth::RequestToken.new(auth_consumer, session[:request_token], session[:request_token_secret])
      got_request_token = true
    rescue
      flash.now[:error] = 'Error Retrieving OAuth Request Token from Twitter'
    end 
    #PP::pp request_token, $stderr, 50
     
    # Exchange Request Token for Access Token
    got_access_token = false
    if got_request_token
      begin
        access_token = request_token.get_access_token(:oauth_verifier => oauth_verifier)
        got_access_token = true
      rescue
        flash.now[:error] = 'Error Retrieving OAuth Access Token from Twitter'
      end  
    end
    #PP::pp access_token, $stderr, 50
    
    # Retrieve Twitter GUID and Contacts
    @twitterName = ''
    @twitterId = ''
    @twitterScreenName = ''
    @twitterFriends = []
    if got_request_token and got_access_token
      @twitterScreenName = getTwitterScreenName access_token
      
      userArray = getTwitterUser access_token
      user = userArray[0]
      #PP::pp user, $stderr, 50
      @twitterName = user['name']
      @twitterId = user['id_str']
      
      friends = getTwitterFriends access_token
      #PP::pp friends, $stderr, 50
      @twitterFriends = parseFriendsResponse friends
    end
    
  end

private
  
  def getAuthConsumer credentials
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
  
  def getTwitterUserId access_token
    token_params = access_token.params
    #PP::pp token_params, $stderr, 50
    user_id = token_params[:user_id]
    #logger.info 'User Id -     ' + user_id    
  end

  def getTwitterScreenName access_token
    token_params = access_token.params
    #PP::pp token_params, $stderr, 50
    screen_name = token_params[:screen_name]
    #logger.info 'Screen Name - ' + screen_name    
  end
  
  def getTwitterUser access_token 
    user_id = getTwitterUserId access_token   
    user_url = "/1/users/lookup.json?user_id=#{ user_id}"
    response = access_token.get(user_url).body
    data = JSON.parse(response)
  end

  def getTwitterFriends access_token
    user_id = getTwitterUserId access_token
    friends_url = "/1/friends/ids.json?cursor=-1&stringify_ids=true&user_id=#{ user_id }"
    response = access_token.get(friends_url).body
    data = JSON.parse(response)
   end
  
  def parseFriendsResponse data
        
    friends = data[ 'ids']
    #PP::pp friends, $stderr, 50
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
