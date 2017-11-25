Rails.application.routes.draw do
  post '/callback' => 'webhook#callback'
end