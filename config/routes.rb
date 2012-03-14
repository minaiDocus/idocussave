Idocus::Application.routes.draw do
  root :to => "homepage#index"

  devise_for :super_users
  devise_for :users
  
  resources :maintenances

  resources :pages do
    resources :page_contents do
      resources :page_content_items
    end
  end
  
  namespace :account do
    root :to => "account/documents#index"
    
    scope :module => "documents" do
      resources :documents do
        get 'invoice', :on => :member
        get 'packs', :on => :collection
        get 'search', :on => :collection
        get 'find', :on => :collection
        get 'reporting', :on => :collection
        get 'search_user', :on => :collection
        post 'reorder', :on => :collection
        post 'archive', :on => :collection
      end
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
    
    resource :profile
    resources :addresses
    resource :dropbox do
      get 'authorize_url', :on => :member
      get 'callback', :on => :member
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
    
    namespace :manage do
      resources :account_book_types
    end
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
    resources :events
    resources :users do
      post 'update_confirm_status', :on => :member
      post 'update_delivery_status', :on => :member
      get 'search', :on => :collection
    end
    resources :orders do
      get 'edit_option', :on => :member
      post 'update_option', :on => :member
    end
    resources :homepages
    resource :thumbnail_task do
      get 'start'
      get 'stop'
      get 'status'
      get 'remain'
    end
    resources :slides do
      post 'update_is_invisible_status', :on => :member
    end
    resources :pavets do
      post 'update_is_invisible_status', :on => :member
    end
    resources :page_types
    resources :pages do
      post 'update_is_invisible_status', :on => :member
    end
    resources :cms_images
    resources :products
    resources :product_options
    resources :product_groups
    resources :subscriptions
    resources :account_book_types
    resources :documents do
      get 'run_background_process', :on => :collection
    end
    resources :backups do
      get 'service', :on => :collection
    end
  
  end
end
