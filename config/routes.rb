Resrv::Application.routes.draw do

  # == User Routes ==
  get "signup", to: "users#new"
  resources :users, only: [:create]

  # == Session Routes ==
  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"
  
  

  resources :movies
  # Add new routes here

  resources :movies do
    get :similar, on: :member
  end

  root to: redirect('/movies')
end
