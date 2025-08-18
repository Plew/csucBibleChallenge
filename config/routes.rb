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
  root "home#index"

  # User Authentication UI routes
  get 'users/sign_up', to: 'users#new', as: :new_user_registration
  resources :users, only: [:create] # For handling registration form submission
  get 'users/sign_in', to: 'sessions#new', as: :new_user_session
  post 'users/sign_in', to: 'sessions#create', as: :user_session
  delete 'users/sign_out', to: 'sessions#destroy', as: :destroy_user_session

  # Challenges UI
  resources :challenges, only: [:index, :show] do # Add :show, :new, :create, etc. as needed for UI
    resources :user_challenge_enrollments, only: [:create], as: :enrollments # POST challenges/:challenge_id/enrollments
    member do
      get :summary
    end
  end
  resources :user_challenge_enrollments, only: [:destroy] # DELETE /user_challenge_enrollments/:id

  # User Profile UI
  get 'profile', to: 'profile#index', as: :profile
  namespace :profile do
    resource :details, only: [:edit, :update], controller: 'details'
    resource :password, only: [:edit, :update], controller: 'passwords'  
    resources :enrollments, only: [:index, :destroy], controller: 'enrollments'
  end

  # Admin routes
  namespace :admin do
    resources :challenges, only: [:new, :create]
  end

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
  get 'stats', to: 'stats#index'

  resources :user_readings, only: [:create]

  resources :groups, only: [:index, :new, :create, :show] do
    member do
      post :join
      get :confirm_destroy
      post :destroy_and_leave
    end
    collection do
      post :leave
    end
  end
end
