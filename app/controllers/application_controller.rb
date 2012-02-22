# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

# https://github.com/oauth/oauth-ruby
# http://oauth.rubyforge.org/rdoc/
require 'oauth'
require 'oauth/consumer'
# https://github.com/intridea/oauth2
require 'oauth2'

require 'yaml'
require 'json'
require 'xmlsimple'
require 'pp'


require 'authlogic'

require 'net/http'
require 'cgi'

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password

  def loadOAuthConfig serviceName
    credentials = Hash.new
    oauthFilename = "#{RAILS_ROOT}/config/oauth-key.yml"
    #logger.info RAILS_ROOT
    #logger.info "#{RAILS_ROOT}/config/oauth-key.yml"
    begin
      authKeys = YAML::load_file(oauthFilename) [RAILS_ENV]
    rescue
      errorMsg = "YAML load failed. Expected file - " + oauthFilename
      logger.info errorMsg
      flash[:error_description] = errorMsg
      Kernel::raise errorMsg
    end
    
    authKeys.each_key do | key |
      if key[serviceName]
        # Facebook
        credentials['App ID'] = authKeys[key]['App ID']
        # Facebook
        credentials['App Secret'] = authKeys[key]['App Secret']
        # Twitter, LinkedIn, Google, Yahoo
        credentials['Consumer Key'] = authKeys[key]['Consumer Key']
        # Twitter, LinkedIn, Google, Yahoo
        credentials['Consumer Secret'] = authKeys[key]['Consumer Secret']
        # Facebook, Twitter, LinkedIn, Google, Yahoo
        credentials['Service URL'] = authKeys[key]['Service URL']
        # Facebook, Twitter, LinkedIn, Google, Yahoo
        credentials['Callback URL'] = authKeys[key]['Callback URL']
        # Facebook, Twitter, LinkedIn, Google, Yahoo
        credentials['Application URL'] = authKeys[key]['Application URL']
         # Windows Live
        credentials['Client Id'] = authKeys[key]['Client Id']
        # Windows Live
        credentials['Client Secret'] = authKeys[key]['Client Secret']
     end
    end
    credentials
  end


end
