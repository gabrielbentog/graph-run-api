Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  get 'websocket/connect', to: 'websocket#connect'

  post 'websocket/create_group', to: 'websocket#create_group'
  post 'websocket/create_labirint', to: 'websocket#create_labirint'
  post 'websocket/get_url', to: 'websocket#get_url'
end
