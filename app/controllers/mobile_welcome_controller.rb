class MobileWelcomeController < ApplicationController

  layout "mobileWelcome"
  
  # GET /Welcome
  def index
    @current_time = Time.now
    #PP::pp session, $stderr, 50
  end
  
end
