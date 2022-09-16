class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @statIndex =
      Impression.where(controller_name: "pages", action_name: "index").length
    @statAbout =
      Impression.where(controller_name: "pages", action_name: "about").length
    @statServ =
      Impression.where(controller_name: "pages", action_name: "services").length
    @statPosts =
      Impression.where(controller_name: "posts", action_name: "list").length
  end

  def stats
  end

  def posts
  end
end
