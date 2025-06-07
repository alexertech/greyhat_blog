# frozen_string_literal: true

Rails.application.routes.draw do
  get '/buscar', to: 'search#index', as: 'search'
  get '/guardados', to: 'bookmarks#index', as: 'bookmarks'
  # Active Storage direct uploads
  post '/rails/active_storage/direct_uploads', to: 'active_storage/direct_uploads#create'
  get 'dashboard' => 'dashboards#index'
  get 'dashboards/stats' => 'dashboards#stats'
  get 'dashboards/posts' => 'dashboards#posts'
  get 'dashboards/comments' => 'dashboards#comments'
  devise_for :users

  resources :contacts
  resources :posts do
    resources :comments, only: [:create]
    member do
      get 'track_visit'
    end
  end
  resources :comments, only: [:destroy] do
    member do
      patch 'approve'
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
