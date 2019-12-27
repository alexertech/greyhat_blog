Rails.application.routes.draw do

  devise_for :users

  resources :contacts
  resources :posts

  root 'pages#index' # Pagina principl

  get '/index'     => 'pages#index'
  get '/acerca'    => 'pages#about'
  get '/servicios' => 'pages#services'
  get '/contacto'  => 'contacts#new'

  get '/articulos'      => 'posts#list'

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
