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
  
  # Password Reset routes
  get 'password_reset/new', to: 'password_resets#new', as: :new_password_reset
  post 'password_reset', to: 'password_resets#create', as: :password_reset
  get 'password_reset/:token/edit', to: 'password_resets#edit', as: :edit_password_reset
  patch 'password_reset/:token', to: 'password_resets#update', as: :update_password_reset

  # Language switching
  patch 'language', to: 'languages#update', as: :update_language

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
    resource :avatar, only: [:edit, :update], controller: 'avatars'
    resource :version, only: [:edit, :update], controller: 'versions'
    resource :email_preferences, only: [:edit, :update], controller: 'email_preferences'
    resources :enrollments, only: [:index, :destroy], controller: 'enrollments'
  end

  # Admin routes
  namespace :admin do
    resources :challenges, only: [:new, :create, :destroy] do
      member do
        get :delete_confirmation
      end
    end
    resources :feedbacks, only: [:index, :show, :destroy]
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
  get 'faq', to: 'pages#faq'
  get 'stats', to: 'stats#index'
  get 'stats/challenge', to: 'stats#challenge', as: :stats_challenge
  get 'stats/group', to: 'stats#group', as: :stats_group
  get 'stats/personal', to: 'stats#personal', as: :stats_personal
  get 'stats/seven_day_window', to: 'stats#seven_day_window', as: :stats_seven_day_window

  resources :user_readings, only: [:create]
  
  # Feedback
  resources :feedbacks, only: [:new, :create, :show]

  resources :groups, only: [:index, :new, :create, :show] do
    member do
      post :join
      get :confirm_destroy
      post :destroy_and_leave
      patch :toggle_closed
    end
    collection do
      post :leave
    end
  end
end
