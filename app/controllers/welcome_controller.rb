class WelcomeController < ApplicationController

  layout "welcome"
  
  # GET /Welcome
  def index
    @current_time = Time.now
    #PP::pp session, $stderr, 50
  end
  
end
