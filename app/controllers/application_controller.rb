# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

# https://github.com/oauth/oauth-ruby
require 'oauth'
require 'oauth/consumer'
# https://github.com/intridea/oauth2
require 'oauth2'

require 'yaml'
require 'json'
require 'xmlsimple'
require 'pp'

require 'net/http'
require 'cgi'

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password

  def loadOAuthConfig serviceName
    credentials = Hash.new
    authKeys = YAML::load_file("#{RAILS_ROOT}/config/oauth-key.yml") [RAILS_ENV]
    authKeys.each_key do | key |
      if key[serviceName]
        # Facebook
        credentials['App ID'] = authKeys[key]['App ID']
        # Facebook
        credentials['App Secret'] = authKeys[key]['App Secret']
        # Google, Yahoo
        credentials['Consumer Key'] = authKeys[key]['Consumer Key']
        # Google, Yahoo
        credentials['Consumer Secret'] = authKeys[key]['Consumer Secret']
        # Facebook, Google, Yahoo
        credentials['Service URL'] = authKeys[key]['Service URL']
        # Facebook, Google, Yahoo
        credentials['Callback URL'] = authKeys[key]['Callback URL']
        # Facebook, Google, Yahoo
        credentials['Application URL'] = authKeys[key]['Application URL']
      end
    end
    credentials
  end


end
