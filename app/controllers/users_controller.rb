# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: %i[show edit update destroy]

  def index
    @users = User.all.order(:public_name, :email)
  end

  def show
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    @user.password = SecureRandom.hex(8) if @user.password.blank?
    
    if @user.save
      redirect_to users_path, notice: 'Usuario creado exitosamente.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    user_params_without_password = user_params
    user_params_without_password.delete(:password) if user_params_without_password[:password].blank?
    
    if @user.update(user_params_without_password)
      redirect_to users_path, notice: 'Usuario actualizado exitosamente.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @user.posts.any?
      redirect_to users_path, alert: 'No se puede eliminar un usuario que tiene posts asociados.'
    else
      @user.destroy
      redirect_to users_path, notice: 'Usuario eliminado exitosamente.'
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:email, :password, :public_name, :description, :avatar)
  end
end