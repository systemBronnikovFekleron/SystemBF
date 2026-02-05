Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"

  # Authentication routes
  get 'login', to: 'sessions#new'
  post 'login', to: 'sessions#create'
  delete 'logout', to: 'sessions#destroy'

  get 'register', to: 'registrations#new'
  post 'register', to: 'registrations#create'

  # Password reset routes
  get 'forgot-password', to: 'password_resets#new', as: :new_password_reset
  post 'password-resets', to: 'password_resets#create', as: :password_resets
  get 'password-reset/:token/edit', to: 'password_resets#edit', as: :edit_password_reset
  patch 'password-reset/:token', to: 'password_resets#update', as: :password_reset

  # API routes
  namespace :api do
    namespace :v1 do
      post 'login', to: 'authentication#login'
      delete 'logout', to: 'authentication#logout'
      get 'validate_token', to: 'authentication#validate_token'

      resources :users, only: [:show, :update]
    end
  end

  # Shop routes
  resources :categories, only: [:index, :show]
  resources :products, only: [:index, :show]

  # Order requests (new purchase flow)
  resources :order_requests, only: [:index, :show, :create] do
    member do
      get :payment_options
      post :pay
    end
  end

  # External forms integration
  post 'external_forms/submit', to: 'external_forms#submit', as: :external_forms_submit

  resources :orders, only: [:index, :show] do
    resource :payment, only: [:new, :create], controller: 'order_payments'
  end

  # Webhooks
  namespace :webhooks do
    post 'cloudpayments/pay', to: 'cloud_payments#pay'
    post 'cloudpayments/fail', to: 'cloud_payments#fail'
    post 'cloudpayments/refund', to: 'cloud_payments#refund'
    post 'telegram/:token', to: 'telegram#webhook'
  end

  # Telegram linking
  get 'telegram/link/:token', to: 'telegram#link', as: :telegram_link

  # Admin routes
  namespace :admin do
    root to: 'dashboard#index'
    resources :products do
      post :bulk_action, on: :collection
      resource :form_generator, only: [:show]
    end
    resources :orders, only: [:index, :show, :update]
    resources :users, only: [:index, :show, :edit, :update]
    resources :interaction_histories
    resources :order_requests, only: [:index, :show] do
      member do
        post :approve
        post :reject
      end
    end

    # Integrations management
    resources :integrations, only: [:index, :show, :edit, :update] do
      member do
        post :test_connection
        post :toggle_status
        get :logs
        get :statistics
      end
    end

    # Email templates management
    resources :email_templates do
      member do
        get :preview
        post :send_test
        post :duplicate
      end
    end
  end

  # Events routes
  resources :events, only: [:index, :show] do
    collection do
      get :calendar
    end
    resources :event_registrations, only: [:create], path: 'register'
  end
  resources :event_registrations, only: [:destroy], path: 'registrations'

  # Dashboard routes
  get 'dashboard', to: 'dashboard#index'
  get 'dashboard/profile', to: 'dashboard#profile', as: :dashboard_profile
  patch 'dashboard/profile', to: 'dashboard#update_profile'
  get 'dashboard/wallet', to: 'dashboard#wallet', as: :dashboard_wallet
  post 'dashboard/wallet/deposit', to: 'dashboard#deposit_wallet', as: :deposit_wallet
  get 'dashboard/rating', to: 'dashboard#rating', as: :dashboard_rating
  get 'dashboard/orders', to: 'dashboard#orders', as: :dashboard_orders
  get 'dashboard/my-courses', to: 'dashboard#my_courses', as: :dashboard_my_courses
  get 'dashboard/achievements', to: 'dashboard#achievements', as: :dashboard_achievements
  get 'dashboard/notifications', to: 'dashboard#notifications', as: :dashboard_notifications
  get 'dashboard/settings', to: 'dashboard#settings', as: :dashboard_settings

  # New dashboard routes for content
  get 'dashboard/development-map', to: 'dashboard#development_map', as: :dashboard_development_map
  get 'dashboard/favorites', to: 'dashboard#favorites', as: :dashboard_favorites
  get 'dashboard/news', to: 'dashboard#news', as: :dashboard_news
  get 'dashboard/materials', to: 'dashboard#materials', as: :dashboard_materials
  get 'dashboard/wiki', to: 'dashboard#wiki', as: :dashboard_wiki
  get 'dashboard/wiki/:slug', to: 'dashboard#wiki_show', as: :dashboard_wiki_page
  get 'dashboard/recommendations', to: 'dashboard#recommendations', as: :dashboard_recommendations
  get 'dashboard/events', to: 'dashboard#events', as: :dashboard_events
end
