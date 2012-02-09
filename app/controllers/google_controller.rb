require Rails.root.join('app', 'models', 'services', 'google')

class GoogleController < ApplicationController
  
  layout "service"

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


  def authorizeGoogleAccess
    begin
      url = GoogleSocialService.getAuthCodeURL
      redirect_to url
    rescue
      flash[:error_description] = errorMsg
      redirect_to :action => :index
    end
  end

  
  def authorizationStatus
    # Test the referrer?    
    if(params[:code] and params[:code] != '')
      # Store User Authoization Code
      session[:googleAuthCode] = params[:code]
    end
    if !session[:googleAuthCode]
      flash[:error] = params[:error]
    end
  end

  def revokeGoogleAccess
      session[:googleAuthCode] = nil
      redirect_to :action => :index    
  end
  
  def retrieveGoogleContacts
    
    #PP::pp params, $stderr, 50
    
    got_access_token = false
    if(session[:googleAuthCode])
      authCode = session[:googleAuthCode]
      access_token = GoogleSocialService.getAccessToken authCode
      #PP::pp access_token, $stderr, 50
      #oauth2AccessToken = GoogleSocialService.getOAuth2AccessToken authCode
      #PP::pp oauth2AccessToken, $stderr, 50
      got_access_token = true
    else
      flash[:error] = params[:error]
      redirect_to :action => :googleAccessDenied
    end 
     
    # Retrieve Google GUID and Contacts
    @googleId = ''
    @googleName = ''
    @googleContacts = []
    #got_access_token = false
    if got_access_token
      userProfile = GoogleSocialService.getGoogleProfile access_token
      @googleId = userProfile['id']
      @googleName = userProfile['name']
      @googleContacts = GoogleSocialService.getGoogleContacts access_token
      #PP::pp @googleContacts, $stderr, 50
    end

  end
  
  def googleAccessDenied
    
  end

private
  
  
end
