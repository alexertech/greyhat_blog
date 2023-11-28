# frozen_string_literal: true

class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @statIndex = ''
    @statAbout = ''
    @statServ = ''
    @statPosts = ''
  end

  def stats; end

  def posts; end
end
