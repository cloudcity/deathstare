Deathstare::Engine.routes.draw do

  root 'test_sessions#new'

  # don't need :new since we already have root pointing at it
  resources :test_sessions, path:'sessions', only: [:create, :index, :show, :destroy] do
    collection do
      post :clear
    end
    member do
      get :stream
      post :cancel
    end
    resources :test_results, path:'results', only:[:index]
  end

  resources :end_points, only:[:index] do
    member do
      post :reset
    end
  end

  resource :concurrent_instances, only: [:show, :update]

  get 'login' => 'login#new'
  get '/auth/:provider/callback' => 'login#create'
  get 'logout' => 'login#destroy'
  get 'not_signed_in' => 'application#not_signed_in'

  #require 'sidekiq/web'

  #get '/sidekiq' => Sidekiq::Web.new

end
