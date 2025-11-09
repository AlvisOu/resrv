Resrv::Application.routes.draw do
  get "notifications/index"
  get "notifications/mark_as_read"
  # == Root Route ==
  root "workspaces#index"
  
  # == User Routes ==
  get "signup", to: "users#new", as: "signup"
  get "profile", to: "users#show", as: "profile"
  patch "profile", to: "users#update"
  resources :users, only: [:create, :destroy]

  # == Session Routes ==
  get "login", to: "sessions#new", as: "login"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy", as: "logout"

  # == Workspace Routes ==
  resources :workspaces, only: [:index, :new, :create, :show, :edit, :update] do
    resource :user_to_workspace, only: [:create, :destroy]
    resources :items, only: [:new, :create, :edit, :update, :destroy]
  end

  # == Reservation Routes ==
  resources :reservations, only: [:index, :create, :destroy] do
    get :availability, on: :collection
    member do
      patch :mark_no_show
      patch :return_items
      patch :undo_return_items
    end
  end

  resources :notifications, only: [:index, :destroy] do
    post :mark_as_read,  on: :member
    collection do
      post :mark_all_as_read
      delete :delete_all
    end
  end

  # == Cart Routes ==
  resource  :cart, only: [:show] do
    post :checkout   # <= NEW
  end
  resources :cart_items, only: [:create, :update, :destroy] do
    delete :remove_range, on: :collection
  end
end
