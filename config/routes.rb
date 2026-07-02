Rails.application.routes.draw do
  # Add the missing asset to the load path
  get "pages/home"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Defines the root path route ("/")
  root "home#index"

  # Reading page for logged-in users
  get "reading", to: "home#reading", as: :reading

  # Date picker for month navigation
  get "date_picker", to: "date_picker#show", as: :date_picker

  # User Authentication UI routes
  get "users/sign_up", to: "users#new", as: :new_user_registration
  resources :users, only: [ :create ] # For handling registration form submission
  get "users/sign_in", to: "sessions#new", as: :new_user_session
  post "users/sign_in", to: "sessions#create", as: :user_session
  delete "users/sign_out", to: "sessions#destroy", as: :destroy_user_session

  # Password Reset routes
  get "password_reset/new", to: "password_resets#new", as: :new_password_reset
  post "password_reset", to: "password_resets#create", as: :password_reset
  get "password_reset/:token/edit", to: "password_resets#edit", as: :edit_password_reset
  patch "password_reset/:token", to: "password_resets#update", as: :update_password_reset

  # Unsubscribe route
  get "unsubscribe/:token", to: "unsubscribe#show", as: :unsubscribe

  # Email Login routes
  get "email_login/:token", to: "email_login#show", as: :email_login

  # Language switching
  patch "language", to: "languages#update", as: :update_language

  # Challenge invitation links
  get "challenges/:token/join", to: "challenge_invitations#show", as: :challenge_invitation

  # Group invitation links
  get "groups/:token/join", to: "group_invitations#show", as: :group_invitation

  # Challenges UI
  resources :challenges, only: [ :index, :show, :new, :create ] do # Challenge creation for logged-in users
    resources :user_challenge_enrollments, only: [ :create ], as: :enrollments # POST challenges/:challenge_id/enrollments
    resources :groups, only: [ :create ], controller: "challenge_groups" do
      member do
        post :join
        post :leave
      end
    end
    resources :blog_posts, only: [ :index, :show ], controller: "blog_posts" do
      resources :blog_comments, only: [ :create, :destroy ]
    end
    resource :catch_up, only: [ :show ]
    member do
      get :summary
    end
  end
  resources :user_challenge_enrollments, only: [ :destroy ] # DELETE /user_challenge_enrollments/:id

  # Multi-challenge management chooser (shown when user manages more than one challenge)
  get "manage", to: "manage/chooser#index", as: :manage_chooser

  # Challenge owner management
  resources :challenges, only: [] do
    namespace :manage do
      root "dashboard#index", as: :dashboard
      get "danger", to: "danger#show", as: :danger
      delete "danger", to: "danger#destroy"
      resource :settings, only: [ :edit, :update ], controller: "settings"
      resource :api_access, only: [ :show ], controller: "api_access" do
        post :regenerate
      end
      resources :top_readers, only: [ :index ]
      resources :chapters, only: [ :index ] do
        collection do
          get :add_books
          post :add_books, action: :create_add_books, as: :create_add_books
        end
      end
      resources :sprints, only: [ :index, :show, :new, :create, :edit, :update, :destroy ]
      resources :blog_posts, only: [ :index, :new, :create, :edit, :update, :destroy ]
      resources :users, only: [ :index, :show ] do
        member do
          delete :remove
          delete :remove_from_group
          get :change_password
          patch :update_password
          patch :promote
          patch :demote
        end
        collection do
          post :bulk_remove_from_groups
        end
      end
      get "seven_day_winner/draw", to: "seven_day_winner#draw", as: :seven_day_winner_draw
      resources :groups, only: [ :index, :update, :destroy ] do
        member do
          delete :remove_member
          patch :move_member
        end
      end
    end
  end

  # Public user profiles (viewable by anyone)
  resources :public_profiles, only: [ :show ], path: "users"

  # User Profile UI (current user's own settings)
  get "account", to: "profile#index", as: :account
  get "profile", to: redirect("/account") # Redirect old profile path to account
  namespace :profile do
    resource :details, only: [ :edit, :update ], controller: "details"
    resource :password, only: [ :edit, :update ], controller: "passwords"
    resource :avatar, only: [ :edit, :update ], controller: "avatars"
    resource :version, only: [ :edit, :update ], controller: "versions"
    resource :email_preferences, only: [ :edit, :update ], controller: "email_preferences"
    resources :enrollments, only: [ :index, :show, :destroy ], controller: "enrollments" do
      member do
        get :delete_challenge_confirmation
        delete :delete_challenge
      end
    end
  end

  # Admin routes
  namespace :admin do
    root "dashboard#index"
    resources :challenges, only: [ :index, :new, :create, :destroy ] do
      member do
        get :delete_confirmation
      end
    end
    resources :users, only: [ :index, :show ] do
      member do
        patch :reset_password
        patch :update_password
        patch :toggle_challenge_creator
        get :reading_history
        get :change_password
      end
      collection do
        post :remove_from_groups
      end
    end
    resources :feedbacks, only: [ :index, :show, :destroy ]

    # Challenge transfer routes
    get "change_challenge", to: "challenge_transfers#new", as: :change_challenge
    post "change_challenge", to: "challenge_transfers#create"
  end

  # 7 Day Lobby routes (available to all users)
  resources :challenges, only: [] do
    resource :seven_day_lobby, only: [ :show ], path: "seven_day_win" do
      post :join, on: :member
      delete :leave, on: :member
      post :start, on: :member
      delete :clear_lobby, on: :member
      post :add_all_eligibles, on: :member
    end
  end

  namespace :api do
    namespace :v1 do
      resources :users, only: [ :create ]
      resources :challenges, only: [ :index, :show, :create ] do
        get :report, on: :member, to: "challenge_reports#show"
        resources :participants, only: [ :show ], controller: "challenge_participants"
        resources :enrollments, only: [ :create, :update ], controller: "challenge_enrollments"
        resources :readings, only: [ :index, :create ]
        resources :groups, only: [ :index, :create ] do
          get :report, on: :member, to: "group_reports#show"
        end
        resources :sprints, only: [ :index, :show ], controller: "challenge_sprints"
      end
      get "meta", to: "meta#show"
      get "chapter_verses", to: "chapter_verses#show"
    end
  end

  if Rails.env.development?
    mount Lookbook::Engine, at: "/lookbook"
  end

  get "about", to: "pages#about"
  get "faq", to: "pages#faq"
  get "statistics_update", to: "static_pages#statistics_update", as: :statistics_update
  get "stats", to: "stats#index"
  get "stats/challenge", to: "stats#challenge", as: :stats_challenge
  get "stats/group", to: "stats#group", as: :stats_group
  get "stats/personal", to: "stats#personal", as: :stats_personal
  get "stats/seven_day_window", to: "stats#seven_day_window", as: :stats_seven_day_window

  get "badges", to: "badges#index", as: :badges
  get "badges/:badge_key", to: "badges#show", as: :badge

  resources :user_readings, only: [ :create ]
  resources :push_subscriptions, only: [ :create ] do
    collection do
      delete :destroy
    end
  end

  # Feedback
  resources :feedbacks, only: [ :new, :create, :show ]

  resources :groups, only: [ :index, :new, :create, :show, :edit, :update ] do
    resources :pokes, only: [ :create ]
    resources :group_messages, only: [ :index, :create ], path: "messages"
    member do
      post :join
      get :confirm_destroy
      post :destroy_and_leave
      get "members/:member_id/confirm_remove", to: "groups#confirm_remove_member", as: :confirm_remove_member
      delete "members/:member_id", to: "groups#remove_member", as: :remove_member
    end
    collection do
      post :leave
    end
  end

  # Verse messages are scoped by reading and verse number
  # URL pattern: /readings/:reading_id/verse_messages?verse_number=X
  resources :readings, only: [] do
    resources :verse_messages, only: [ :index, :create, :destroy ], path: "verse_messages"
    post "verse_like", to: "verse_likes#toggle", as: :toggle_verse_like
  end
end
