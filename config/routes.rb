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

  get 'forgot-password', to: 'password_resets#new'
  post 'forgot-password', to: 'password_resets#create'

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

  resource :cart, only: [:show, :update, :destroy] do
    post 'add_item', on: :collection
    delete 'remove_item/:product_id', to: 'carts#remove_item', on: :collection, as: :remove_item
  end

  resources :orders, only: [:index, :show, :create] do
    resource :payment, only: [:new, :create], controller: 'order_payments'
  end

  # Webhooks
  namespace :webhooks do
    post 'cloudpayments/pay', to: 'cloud_payments#pay'
    post 'cloudpayments/fail', to: 'cloud_payments#fail'
    post 'cloudpayments/refund', to: 'cloud_payments#refund'
  end

  # Dashboard routes
  get 'dashboard', to: 'dashboard#index'
  get 'dashboard/profile', to: 'dashboard#profile'
  get 'dashboard/wallet', to: 'dashboard#wallet'
  get 'dashboard/rating', to: 'dashboard#rating'
  get 'dashboard/orders', to: 'dashboard#orders'
  get 'dashboard/my-courses', to: 'dashboard#my_courses'
  get 'dashboard/achievements', to: 'dashboard#achievements'
  get 'dashboard/notifications', to: 'dashboard#notifications'
  get 'dashboard/settings', to: 'dashboard#settings'
end
