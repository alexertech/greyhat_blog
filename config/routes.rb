Rails.application.routes.draw do

  get 'dashboard' => 'dashboard#index'
  get 'dashboard/stats'
  get 'dashboard/posts'
  devise_for :users

  resources :contacts
  resources :posts

  root 'pages#index' # Pagina principl

  get '/index'     => 'pages#index'
  get '/acerca'    => 'pages#about'
  get '/servicios' => 'pages#services'
  get '/contacto'  => 'contacts#new'
  get '/contacto_clean'  => 'contacts#clean', as: 'contacts_clean_url'

  get '/articulos' => 'posts#list'



  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
