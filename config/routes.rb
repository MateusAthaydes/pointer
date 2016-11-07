Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  resources :profiles
  root to: 'search#home'
  get 'search', to: 'search#search'
  get 'import', to: 'profiles#import'
  post 'parse_and_import', to: 'profiles#parse_and_import'
end
