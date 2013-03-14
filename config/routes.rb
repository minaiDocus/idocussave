Idocus::Application.routes.draw do
  root :to => "homepage#index"

  devise_for :users

  resources :pages

  match '/account/documents/:id/download/:style', controller: 'account/documents', action: 'download', via: :get
  match '/account/documents/pieces/:id/download', controller: 'account/documents', action: 'piece', via: :get
  match '/account/invoices/:id/download/:style', controller: 'account/invoices', action: 'download', via: :get
  match '/account/compositions/download', controller: 'account/compositions', action: 'download', via: :get
  match '/account' => redirect('/account/documents')

  match 'num', controller: 'num', action: :index, via: :get
  match 'num', controller: 'num', action: :create, via: :post
  match 'num', controller: 'num', action: :create, via: :put
  match 'num/cancel', controller: 'num', action: :cancel, via: :get
  match 'num/:id/add', controller: 'num', action: :add, via: :put
  match 'num/:id/overwrite', controller: 'num', action: :overwrite, via: :put

  match 'gr/sessions/:slug/create',  controller: 'gray_label/sessions', action: 'create',  via: :get
  match 'gr/sessions/:slug/destroy', controller: 'gray_label/sessions', action: 'destroy', via: :get

  namespace :account do
    root :to => "account/documents#index"
    resource :organization do
      resources :groups
      resources :collaborators do
        resource :rights
        put 'stop_using',     on: :member
        put 'restart_using',  on: :member
      end
      resources :customers do
        get 'search_by_code', on: :collection
        put 'stop_using',     on: :member
        put 'restart_using',  on: :member
        resources :addresses, controller: 'organization_addresses'
      end
      resources :journals do
        post 'cancel_destroy',           :on => :member
        post 'update_requested_users',   :on => :member
        put  'update_is_default_status', :on => :member
      end
      resources :subscriptions
      resource :default_subscription, controller: 'organization_subscriptions'
      resource :ibiza, controller: 'ibiza'
    end

    resources :documents do
      get 'packs', :on => :collection
      get 'search', :on => :collection
      get 'archive', :on => :member
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

    resource :reporting, controller: 'reporting'
    resources :periods
    namespace :report do
      resources :expenses
      resources :preseizures
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
      get 'use_debit_mandate', :on => :member
      get 'credit', :on => :member
    end
    resource :debit_mandate do
      get 'return', :on => :member
    end
    resources :compositions do
      delete 'reset', :on => :collection
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
      put 'accept', on: :member
      put 'activate', on: :member
      resources :addresses do
        get 'edit_multiple', on: :collection
        post 'update_multiple', on: :collection
      end
      resources :account_book_types do
        put    'accept', on: :member
        put    'add',    on: :member
        delete 'remove', on: :member
      end
      resource :scan_subscription
      resource :csv_outputter
    end
    resources :organizations do
      resources :groups
      resources :journals, controller: 'organization_journals'
      resources :reminder_emails do
        get  'preview',         on: :member
        get  'deliver',         on: :member
        get  'edit_multiple',   on: :collection
        post 'update_multiple', on: :collection
      end
      resource :file_sending_kit do
        get  'select',   on: :member
        post 'generate', on: :member
        get  'folder',   on: :member
        get  'mail',     on: :member
        get  'label',    on: :member
      end
      resource :ibiza, controller: 'ibiza'
      resource :subscription, controller: 'organization_subscriptions'
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
    resources :gray_labels
  end

  get "/preview/(:id)", controller: :homepage, action: :preview
  
  match '*a', :to => 'errors#routing'
end
