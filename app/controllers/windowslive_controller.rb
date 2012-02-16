require Rails.root.join('app', 'models', 'services', 'windowslive')

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

  def authorizeAccess
    # Retrieve Request Token from WindowsLive and Re-Direct to WindowsLive for Authentication
    begin
      url = WindowsLiveSocialService.authCodeURL
      redirect_to url
    rescue
      flash[:error_description] = errorMsg
      redirect_to :action => :index
    end
  end
  
  def authorizationStatus
    #PP::pp session, $stderr, 50
    # Test the referrer
    # Retrieve and Test nonce
    
    if(params[:code] and params[:code] != '')
      # Store User Authoization Code
      session[:windowsLiveAuthCode] = params[:code]
      if(session[:windowsLiveAuthCode] and !session[:windowsLiveAccessToken])
        authCode = session[:windowsLiveAuthCode]
        session[:windowsLiveTokenBirth] = Time.now
        accessToken = WindowsLiveSocialService.newAccessToken authCode
        PP::pp accessToken, $stderr, 50

        session[:windowsLiveAccessToken] = accessToken.token
        session[:windowsLiveTokenExpiresIn] = accessToken.expires_in
        session[:windowsLiveRefreshToken] = accessToken.refresh_token
        session[:windowsLiveAuthenticationToken] = accessToken.params["authentication_token"]
        #PP::pp session, $stderr, 50
        # TODO: Save the Access Token
        if !accessToken
          flash[:error] = "Error Retrieving AccessToken.  Authorization Code Present. WindowsLiveSocialService.accessToken authCode failed to Return Token."
          redirect_to :action => :accessDenied        
        end
      else
        flash[:error] = "Error Retrieving Access Token.  No Authorization Code Found."
        redirect_to :action => :accessDenied
      end
    end
    if !session[:windowsLiveAuthCode]
      flash[:error] = params[:error]
    end
  end

  def revokeAccess
    session[:windowsLiveAuthenticationToken] = nil
    session[:windowsLiveRefreshToken] = nil
    session[:windowsLiveAccessToken] = nil
    session[:windowsLiveAuthCode] = nil

    redirect_to :action => :index

  end
  
  def retrieveWindowsLiveContacts
    #PP::pp params, $stderr, 50
    accessToken = WindowsLiveSocialService.accessToken session[:windowsLiveAccessToken]
    PP::pp accessToken, $stderr, 50
        
    # Data for Views
    @windowsLiveId = ''
    @windowsLiveName = ''
    @windowsLiveContacts = []
        
    if accessToken
      windowsLiveMe = WindowsLiveSocialService.windowsLiveMe accessToken
      @windowsLiveId = windowsLiveMe['id']
      @windowsLiveName = windowsLiveMe['name']        
      @windowsLiveContacts = WindowsLiveSocialService.windowsLiveContacts accessToken
    end
  end
    
  def accessDenied
      
  end
    
private

  
end
