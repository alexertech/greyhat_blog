class PagesController < ApplicationController

  impressionist :unique => [:controller_name, :action_name, :session_hash]

  def index
  end
  def about
  end
  def services
  end
  def contact
  end

end
