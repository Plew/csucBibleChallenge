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

  # Defines the root path route ("/")
  # root "posts#index"

  namespace :api do
    namespace :v1 do
      resources :users, only: [:create]
      resources :challenges, only: [:index, :show, :create] do
        resources :enrollments, only: [:create, :update], controller: 'challenge_enrollments'
        resources :readings, only: [:index, :create] do
          resource :user_reading, only: [:create, :destroy], controller: 'user_readings'
        end
        resources :groups, only: [:index, :create]
      end
      resources :user_readings, only: [:index, :create, :destroy]
      get 'chapter_verses', to: 'chapter_verses#show'
    end
  end

  if Rails.env.development?
    mount Lookbook::Engine, at: "/lookbook"
  end

  get 'about', to: 'pages#about'
end
