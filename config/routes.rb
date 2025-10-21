Resrv::Application.routes.draw do
  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"
  
  get "signup", to: "users#new"
  resources :users, only: [:create]

  resources :movies
  # Add new routes here

  resources :movies do
    get :similar, on: :member
  end

  root to: redirect('/movies')
end
