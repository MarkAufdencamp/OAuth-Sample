class WindowsliveController < ApplicationController

  layout "service"

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

  def authorizeWindowsLiveAccess
    # Retrieve Request Token from WindowsLive and Re-Direct to WindowsLive for Authentication
    begin
      credentials = loadOAuthConfig 'WindowsLive'
    rescue
    end
    #logger.info 'Service URL - ' + credentials['Service URL']
    #logger.info 'App ID - ' + credentials['App ID']
    #logger.info 'App Secret - ' + credentials['App Secret']
    
    if credentials
      auth_scope = "scope=wl.signin,wl.basic"
      url = "#{credentials['Service URL']}/authorize?client_id=#{credentials['Client Id']}&#{auth_scope}&response_type=code&redirect_uri=#{credentials['Callback URL']}"
      redirect_to url
    else
      redirect_to :action => :index
    end
  end
  
  def retrieveWindowsLiveContacts
    # Retrieve Token and Verifier from URL
    #PP::pp params, $stderr, 50
    oauth_code = params[:code]
    #logger.info 'OAuth Code - ' + oauth_code
    
     # Strip params
    if(params[:error] and params[:error] != '')
      flash[:error] = params[:error]
      if(params[:error_desciption] and params[:error_desciption] != '')
        flash[:error_desciption] = params[:error_desciption]
        redirect_to :auth_error
      end
    end
  
    if(params[:code] and params[:code] != '')
      access_code = params[:code]
      #logger.info 'Access Code  - ' + access_code
      access_token = getAppAccessToken access_code
      PP::pp access_token, $stderr, 50
    end
        
    # Data for Views
    @windowsLiveId = ''
    @windowsLiveName = ''
    @windowsLiveContacts = []
        
    if access_token
      # Acces Code and Accees Token Retrieved
      windowsLiveMe = getWindowsLiveMe access_token
      logger.info windowsLiveMe
      @windowsLiveId = windowsLiveMe['id']
      @windowsLiveName = windowsLiveMe['name']
            
      @windowsLiveContacts = getWindowsLiveContacts access_token
      #logger.info @windowsLiveContacts
      
    end
    
    def auth_error
      
    end
  
    
  end
  
private

  def getAppAccessToken access_code
    credentials = loadOAuthConfig 'WindowsLive'
    url = "#{credentials['Service URL']}/token?client_id=#{credentials['Client Id']}&redirect_uri=#{credentials['Callback URL']}&client_secret=#{credentials['Client Secret']}&code=#{CGI.escape(access_code)}&grant_type=authorization_code"
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(uri.path + "?" + uri.query)
    response = http.request(request)
    access_token = JSON.parse(response.body)    
  end
  
    def getWindowsLiveMe access_token
    url = "https://apis.live.net/v5.0/me?access_token=#{CGI.escape( access_token['access_token'] )}"
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(uri.path + "?" + uri.query)
    response = http.request(request)
    result = response.body
    #PP::pp JSON.parse(result), $stderr, 50
    data = JSON.parse(result)
  end

  def getWindowsLiveContacts access_token
    url = "https://apis.live.net/v5.0/me/contacts?access_token=#{CGI.escape( access_token['access_token'] )}"
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(uri.path + "?" + uri.query)
    response = http.request(request)
    parseContactsResponse response.body
  end
  
  def parseContactsResponse data
    result = JSON.parse( data )
    #PP::pp result, $stderr, 50
    contacts = result['data']
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
