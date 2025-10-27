Resrv::Application.routes.draw do
  # == Root Route ==
  root "workspaces#index"
  
  # == User Routes ==
  get "signup", to: "users#new", as: "signup"
  get "profile", to: "users#show", as: "profile"
  resources :users, only: [:create, :destroy]

  # == Session Routes ==
  get "login", to: "sessions#new", as: "login"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy", as: "logout"

  # == Workspace Routes ==
  resources :workspaces, only: [:index, :new, :create, :show] do
    resource :user_to_workspace, only: [:create, :destroy]
  end
end
