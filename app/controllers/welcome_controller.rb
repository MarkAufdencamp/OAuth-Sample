class WelcomeController < ApplicationController

  layout "welcome"
  
  # GET /Welcome
  def index
    @current_time = Time.now

  end
  
end
