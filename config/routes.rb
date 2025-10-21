Resrv::Application.routes.draw do
  resources :movies
  # Add new routes here

  resources :movies do
    get :similar, on: :member
  end

  root to: redirect('/movies')
end
