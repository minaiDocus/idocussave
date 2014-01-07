Idocus::Application.routes.draw do
  root :to => "homepage#index"

  wash_out :dematbox

  devise_for :users

  resources :pages

  match '/account/documents/:id/download/:style', controller: 'account/documents', action: 'download', via: :get
  match '/account/documents/pieces/:id/download', controller: 'account/documents', action: 'piece', via: :get
  match '/account/invoices/:id/download/:style', controller: 'account/invoices', action: 'download', via: :get
  match '/account/compositions/download', controller: 'account/compositions', action: 'download', via: :get
  match '/account' => redirect('/account/documents')

  resources :compta

  get  'num',                   controller: 'num', action: 'index'
  get  'num/:year/:month/:day', controller: 'num', action: 'index',    constraints: { year: /\d{4}/, month: /\d{1,2}/, day: /\d{1,2}/ }
  post 'num',                   controller: 'num', action: 'create'
  put  'num',                   controller: 'num', action: 'create'
  get  'num/cancel',            controller: 'num', action: 'cancel'
  put  'num/:id/add',           controller: 'num', action: 'add'
  put  'num/:id/overwrite',     controller: 'num', action: 'overwrite'

  scope '/num' do
    resource :return_labels
  end
  get  '/num/return_labels/new/:year/:month/:day', controller: 'return_labels', action: 'new'
  post '/num/return_labels/:year/:month/:day',     controller: 'return_labels', action: 'create'

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
        put 'update_ibiza',   on: :member
        resources :addresses, controller: 'organization_addresses'
        resource :accounting_plan do
          member do
            put :import
            delete :destroy_providers
            delete :destroy_customers
          end
        end
        resources :bank_accounts
      end
      resources :journals do
        post 'cancel_destroy',           :on => :member
        put  'update_requested_users',   :on => :member
      end
      resources :subscriptions
      resource :default_subscription, controller: 'organization_subscriptions'
      resource :ibiza, controller: 'ibiza' do
        get 'refresh_users_cache', on: :member
      end
      resources :pre_assignments
      resources :pack_reports do
        post 'deliver', on: :member
      end
      resources :preseizures do
        post 'deliver', on: :member
      end
      resources :preseizure_accounts
    end

    resources :documents do
      get 'packs', :on => :collection
      get 'archive', :on => :member
      post 'sync_with_external_file_storage', :on => :collection
    end

    namespace :documents do
      resource :sharings do
        post 'destroy_multiple', :on => :collection
      end
      resource :tags do
        post 'update_multiple', :on => :collection
      end
      resource :upload
    end

    resource :reporting
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
    resource :dematbox

    namespace :settings do
      resources :retrievers, as: :fiduceo_retrievers do
        post 'fetch',                :on => :member
        get  'select_documents',     :on => :member
        put  'update_documents',     :on => :member
        get  'select_bank_accounts', :on => :member
        post 'create_bank_accounts', :on => :member
      end
    end

    namespace :charts do
      resources :operations
      resources :balances
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
    resources :users do
      get 'search_by_code', on: :collection
      put 'accept', on: :member
      put 'activate', on: :member
      post 'send_reset_password_instructions', on: :member
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
      resources :journals, as: :account_book_types, controller: 'organization_journals' do
        put 'accept', on: :member
      end
      resources :reminder_emails do
        get  'preview',         on: :member
        get  'deliver',         on: :member
        get  'edit_multiple',   on: :collection
        post 'update_multiple', on: :collection
      end
      resource :file_sending_kit do
        get  'select',          on: :member
        post 'generate',        on: :member
        get  'folders',         on: :member
        get  'mails',           on: :member
        get  'customer_labels', on: :member
        get  'workshop_labels', on: :member
      end
      resource :ibiza, controller: 'ibiza'
      resource :subscription, controller: 'organization_subscriptions'
      resource :csv_outputter, controller: 'organization_csv_outputters' do
        get 'select_propagation_options', on: :collection
        post 'propagate', on: :collection
      end
    end
    resources :invoices do
      get 'archive', on: :collection
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
    resources :scanning_providers
    resources :dematboxes do
      post 'subscribe', on: :member
    end
    resources :dematbox_services do
      post 'load_from_external', on: :collection
    end
    resources :dematbox_files
  end

  match '/admin/reporting(/:year)', controller: 'Admin::Reporting', action: :index

  get "/preview/(:id)", controller: :homepage, action: :preview
  
  match '*a', :to => 'errors#routing'
end
