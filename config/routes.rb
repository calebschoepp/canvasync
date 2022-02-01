Rails.application.routes.draw do
  resources :notebooks, except: :destroy do
    member do
      get 'preview'
      post 'join'
    end
  end

  # TODO: Login, signup pages aren't rendering errors
  devise_for :users
  devise_scope :user do
    authenticated :user do
      root 'notebooks#index', as: :authenticated_root
    end
    unauthenticated :user do
      root 'devise/sessions#new', as: :unauthenticated_root
    end
  end

  # Only let admins go to the admin page
  authenticate :user, ->(user) { user.has_role? :admin } do
    mount RailsAdmin::Engine => '/special/sauce', as: 'rails_admin'
  end
end
