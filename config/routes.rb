Rails.application.routes.draw do
  resources :posts
  root 'pages#index' # Pagina principl

  get '/index'     => 'pages#index'
  get '/acerca'    => 'pages#about'
  get '/servicios' => 'pages#services'
  get '/contacto'  => 'pages#contact'

  get '/blog'      => 'posts#list'

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
