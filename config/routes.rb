Rails.application.routes.draw do
  # Add the missing asset to the load path
  get "pages/home"
  get "pages/about"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  resource :user, only: [:edit, :update] do
    post 'reset_key', on: :member
  end
  resources :check_ins, only: [:create, :destroy]
  resources :date_view_changes, only: [:create]

  resources :groups do
  end

  resources :group_memberships, only: [:new, :create, :destroy]

  # Defines the root path route ("/")
  root "dashboard#show"
  get 'dashboard', to: 'dashboard#show'
  get 'home', to: 'dashboard#home', as: :home

  get 'create_or_join', to: 'groups#create_or_join', as: :create_or_join

  if Rails.env.development?
    mount Lookbook::Engine, at: "/lookbook"
  end

  namespace :api do
    namespace :v1 do
      resources :group_statistics, only: [:index, :show]
    end
  end

end
