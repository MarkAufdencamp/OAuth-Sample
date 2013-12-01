class OAuthConfig

  def loadOAuthConfig serviceName
    credentials = Hash.new
    oauthFilename = "#{RAILS_ROOT}/config/oauth-key.yml"
    #logger.info RAILS_ROOT
    #logger.info "#{RAILS_ROOT}/config/oauth-key.yml"
    begin
      authKeys = YAML::load_file(oauthFilename) [RAILS_ENV]
    rescue
      errorMsg = "YAML load failed. Expected file - " + oauthFilename
      Kernel::raise errorMsg
    end
    
    authKeys.each_key do | key |
      if key[serviceName]
        # Facebook
        credentials['App ID'] = authKeys[key]['App ID']
        # Facebook
        credentials['App Secret'] = authKeys[key]['App Secret']
        # Twitter, LinkedIn, Yahoo
        credentials['Consumer Key'] = authKeys[key]['Consumer Key']
        # Twitter, LinkedIn, Google, Yahoo
        credentials['Consumer Secret'] = authKeys[key]['Consumer Secret']
        # Facebook, Twitter, LinkedIn, Google, Yahoo
        credentials['Service URL'] = authKeys[key]['Service URL']
        # Facebook, Twitter, LinkedIn, Google, Yahoo
        credentials['Callback URL'] = authKeys[key]['Callback URL']
        # Facebook, Twitter, LinkedIn, Google, Yahoo
        credentials['Access Callback URL'] = authKeys[key]['Access Callback URL']
        # Facebook, Twitter, LinkedIn, Google, Yahoo
        credentials['Mobile Callback URL'] = authKeys[key]['Mobile Callback URL']
        # Facebook, Twitter, LinkedIn, Google, Yahoo
        credentials['Signin Callback URL'] = authKeys[key]['Signin Callback URL']
        # Facebook, Twitter, LinkedIn, Google, Yahoo
        credentials['Application URL'] = authKeys[key]['Application URL']
         # Google, Windows Live
        credentials['Client Id'] = authKeys[key]['Client Id']
        # Google, Windows Live
        credentials['Client Secret'] = authKeys[key]['Client Secret']
     end
    end
    credentials
  end
end