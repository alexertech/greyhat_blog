class PagesController < ApplicationController

  impressionist :unique => [:session_hash]

  def index
  end
  def about
  end
  def services
  end
  def contact
  end

end
