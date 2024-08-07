# frozen_string_literal: true

Rails.application.routes.draw do
  get 'dashboard' => 'dashboard#index'
  get 'dashboard/stats'
  get 'dashboard/posts'
  devise_for :users

  resources :contacts
  resources :posts do
    member do
      get 'track_visit'
    end
  end
  root 'pages#index' # Pagina principl

  get '/index' => 'pages#index'
  get '/acerca' => 'pages#about'
  get '/servicios' => 'pages#services'
  get '/contacto' => 'contacts#new'
  get '/contacto_clean' => 'contacts#clean', :as => 'contacts_clean'

  get '/articulos' => 'posts#list'
end
