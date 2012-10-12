Idocus::Application.routes.draw do
  root :to => "homepage#index"

  devise_for :users

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
      namespace :report do
        resources :expenses
        resources :preseizures
      end
    end

    resource :profile do
      post   'share_documents_with',   :on => :collection
      delete 'unshare_documents_with', :on => :collection
    end
    resources :addresses
    resource :dropbox do
      get 'authorize_url', :on => :member
      get 'callback', :on => :member
    end
    resource :box do
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
    resources :users do
      get 'search_by_code', on: :collection
      get 'propagate_stamp_name', on: :member
      resources :addresses do
        get 'edit_multiple', on: :collection
        post 'update_multiple', on: :collection
      end
      resources :reminder_emails do
        get 'preview', on: :member
        get 'deliver', on: :member
        get 'edit_multiple', on: :collection
        post 'update_multiple', on: :collection
      end
      resource :file_sending_kit do
        get 'select', on: :member
        post 'generate', on: :member
      end
      resources :account_book_types
      namespace :scan do
        resource :subscription
      end
    end
    resources :pages
    resources :cms_images
    resources :products
    resources :product_options
    resources :product_groups
    resource :dropbox do
      get 'authorize_url', on: :member
      get 'callback', on: :member
    end
    namespace :log do
      resources :visits
    end
  end

  get "/preview/(:id)", controller: :homepage, action: :preview
  
  match '*a', :to => 'errors#routing'
end
