Resrv::Application.routes.draw do
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

  # == Email Verification Routes ==
  get "email/verify", to: "email_verifications#new", as: "verify_email"
  post "email/verify", to: "email_verifications#create"

  # == Password Reset Routes ==
  get "password/reset", to: "password_resets#new", as: "new_password_reset"
  post "password/reset", to: "password_resets#create", as: "password_resets"
  get "password/reset/:token/edit", to: "password_resets#edit", as: "edit_password_reset"
  patch "password/reset/:token", to: "password_resets#update", as: "password_reset"

  # == Workspace Routes ==
  resources :workspaces, only: [:index, :new, :create, :show, :edit, :update] do
    member do
      get :past_reservations
      get :analytics
      get :analytics_utilization_csv
      get :analytics_behavior_csv
      get :analytics_heatmap_csv
    end
    resource :user_to_workspace, only: [:create, :destroy]
    resources :items, only: [:new, :create, :edit, :update, :destroy]
    resources :missing_reports, only: [:index] do
      member do
        patch :resolve
      end
    end
  end

  # == Reservation Routes ==
  resources :reservations, only: [:index, :create, :destroy, :show] do
    get :availability, on: :collection
    member do
      patch :mark_no_show
      patch :return_items
      patch :undo_return_items
      patch :owner_cancel
    end
  end

  # == Notification Routes ==
  resources :notifications, only: [:index, :destroy] do
    post :mark_as_read,  on: :member
    collection do
      post :mark_all_as_read
      delete :delete_all
    end
  end
  resources :penalties, only: [] do
    member do
      post :appeal
      patch :forgive
      patch :shorten
    end
  end

  # == Cart Routes ==
  resource  :cart, only: [:show] do
    post :checkout
  end
  resources :cart_items, only: [:create, :update, :destroy] do
    delete :remove_range, on: :collection
  end
end
