Resrv::Application.routes.draw do
  # Root Route
  # root "home#index"
  resources :movies do
    get :similar, on: :member
  end
  root to: redirect('/movies')


  # == User Routes ==
  get "signup", to: "users#new", as: "signup"
  resources :users, only: [:create]

  # == Session Routes ==
  get "login", to: "sessions#new", as: "login"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy", as: "logout"

end
