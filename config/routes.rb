Idocus::Application.routes.draw do

  root :to => "homepage#index"

  devise_for :super_users
  devise_for :users

  resources :maintenances

  resources :pages

  namespace :account do
    root :to => "account/documents#index"

    resources :documents do
      get 'invoice', :on => :member
      get 'packs', :on => :collection
      get 'search', :on => :collection
      get 'find', :on => :collection
      get 'reporting', :on => :collection
      get 'search_user', :on => :collection
      post 'reorder', :on => :collection
      post 'archive', :on => :collection
      get 'historic', :on => :member
      post 'sync_with_external_file_storage', :on => :collection
    end

    namespace :documents do
      resource :sharings do
        post 'destroy_multiple', :on => :collection
        post 'destroy_multiple_selected', :on => :collection
      end
      resource :tags do
        post 'update_multiple', :on => :collection
      end
      resource :upload
    end


    namespace :scan do
      resources :reportings
      resources :periods
    end

    resource :profile
    resources :addresses
    resource :dropbox do
      get 'authorize_url', :on => :member
      get 'callback', :on => :member
    end
    resource :google_doc do
      get 'authorize_url', :on => :member
      get 'callback', :on => :member
    end
    resource :external_file_storage do
      post :use, :on => :member
      post :update_path_settings, :on => :member
    end
    resource :ftp do
      post :configure, :on => :member
    end
    resource :paypal, :only => [] do
      member do
        post :success
        get :success
        get :cancel
        post :notify
      end
    end
    resource :cmcic, :only => [] do
      member do
        post :callback
        get :success
        get :cancel
      end
      end
    resource :payment do
      post 'mode', :on => :member
      get 'credit', :on => :member
    end
    resource :debit_mandate do
      get 'return', :on => :member
    end
    resources :compositions do
      post 'reorder', :on => :member
      delete 'delete_document', :on => :member
    end
    resources :backups
  end

  namespace :tunnel do
    resource :order do
      member do
        get :address_choice
        post :option_choice
        get :summary
        post :pay
      end
    end

    resources :addresses
  end

  namespace :admin do
    root :to => "admin#index"
    resources :users
    resources :pages
    resources :products
    resources :product_options
    resources :product_groups
  end

  get "/preview/(:id)", controller: :homepage, action: :preview
  
  match '*a', :to => 'errors#routing'
end
