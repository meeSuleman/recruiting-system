Rails.application.routes.draw do
  root "dashboard#health_check"
  devise_for :users,
  controllers: {
    sessions: "users/sessions",
    passwords: "users/passwords"
  }
  resources :candidates, only: [ :index, :show, :create, :destroy ] do
    collection do
      get :validate_email, to: "candidates#validate_email"
    end
  end
  resources :dashboard, only: [ :index ] do
    collection do
      get :admins_list, to: "dashboard#admins_list"
      get :show_admin, to: "dashboard#show_admin"
    end
    member do
      patch :deactivate_admin, to: "dashboard#deactivate_admin"
      patch :activate_admin, to: "dashboard#activate_admin"
      delete :delete_admin, to: "dashboard#delete_admin"
    end
  end
  resources :invitations, only: [ :create ] do
    get :accept, on: :member
    post :register_invited_user, on: :collection
  end
end
