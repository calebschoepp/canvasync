Rails.application.routes.draw do
  resources :notebooks

  devise_for :users
  devise_scope :user do
    authenticated :user do
      root 'notebooks#index', as: :authenticated_root
    end
    unauthenticated :user do
      root 'devise/sessions#new', as: :unauthenticated_root
    end
    end
end
