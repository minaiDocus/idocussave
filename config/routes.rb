Idocus::Application.routes.draw do
  root to: 'account/documents#index'

  wash_out :dematbox

  devise_for :users

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
    resources :organizations, except: :destroy do
      resources :addresses, controller: 'organization_addresses'
      resource :period_options, only: %w(edit update), controller: 'organization_period_options' do
        get  :select_propagation_options, on: :member
        post :propagate,                  on: :member
      end
      resource :knowings, only: %w(new create edit update)
      resources :reminder_emails, except: :index do
        post 'deliver', on: :member
      end
      resource :file_sending_kit, only: %w(edit update) do
        get  'select',          on: :member
        post 'generate',        on: :member
        get  'folders',         on: :member
        get  'mails',           on: :member
        get  'customer_labels', on: :member
        get  'workshop_labels', on: :member
      end
      resource :csv_outputter, only: %w(edit update), controller: 'organization_csv_outputters' do
        get  'select_propagation_options', on: :member
        post 'propagate',                  on: :member
      end
      resources :groups
      resources :collaborators do
        resource :rights, only: %w(edit update)
        resource :file_storage_authorizations, only: %w(edit update)
      end
      resources :customers do
        get 'search_by_code',        on: :collection
        put 'update_ibiza',          on: :member
        get 'edit_period_options',   on: :member
        put 'update_period_options', on: :member
        resources :addresses, controller: 'customer_addresses'
        resource :accounting_plan do
          member do
            put    :import
            delete :destroy_providers
            delete :destroy_customers
          end
          resources :vat_accounts do
            get 'edit_multiple',   on: :collection
            put 'update_multiple', on: :collection
          end
        end
        resources :bank_accounts, only: %w(edit update), module: 'organization'
        resources :exercices
        resources :journals, except: %w(index show) do
          get  'select', on: :collection
          post 'copy',   on: :collection
        end
        resource :csv_outputter, only: %w(edit update)
        resource :file_storage_authorizations, only: %w(edit update)
        resource :subscription
      end
      resource :dropbox_extended, only: [] do
        get 'authorize_url', on: :member
        get 'callback',      on: :member
      end
      resources :journals, except: 'show'
      resource :default_subscription, only: %w(show edit update)
      resource :organization_subscription, only: %w(edit update)
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
      get  'packs',                           on: :collection
      get  'archive',                         on: :member
      post 'sync_with_external_file_storage', on: :collection
    end

    namespace :documents do
      resource :sharings do
        post 'destroy_multiple', on: :collection
      end
      resource :tags do
        post 'update_multiple', on: :collection
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
      post   'share_documents_with',   on: :collection
      delete 'unshare_documents_with', on: :collection
    end
    resources :addresses
    resource :dropbox do
      get 'authorize_url', on: :member
      get 'callback',      on: :member
    end
    resource :box do
      get 'authorize_url', on: :member
      get 'callback',      on: :member
    end
    resource :google_doc do
      get 'authorize_url', on: :member
      get 'callback',      on: :member
    end
    resource :external_file_storage do
      post :use,                  on: :member
      post :update_path_settings, on: :member
    end
    resource :ftp do
      post :configure, on: :member
    end
    resource :paypal, only: [] do
      member do
        post :success
        get :success
        get :cancel
        post :notify
      end
    end
    resource :cmcic, only: [] do
      member do
        post :callback
        get :success
        get :cancel
      end
    end
    resource :payment do
      post 'mode',             on: :member
      get 'use_debit_mandate', on: :member
      get 'credit',            on: :member
    end
    resource :debit_mandate do
      get 'return', :on => :member
    end
    resources :compositions do
      delete 'reset', :on => :collection
    end
    resources :backups
    resource :dematbox

    resources :retrievers, as: :fiduceo_retrievers do
      get  'list',                 on: :collection
      post 'fetch',                on: :member
      get  'wait_for_user_action', on: :member
      put  'update_transaction',   on: :member
    end
    resources :provider_wishes, as: :fiduceo_provider_wishes
    resources :retriever_transactions
    resources :retrieved_banking_operations
    resources :retrieved_documents do
      get 'piece',    on: :member
      get 'select',   on: :collection
      put 'validate', on: :collection
    end
    resources :bank_accounts do
      put 'update_multiple', on: :collection
    end

    namespace :charts do
      resources :operations
      resources :balances
    end

    resources :emailed_documents do
      post 'regenerate_code', on: :collection
    end
  end

  namespace :api, defaults: { format: 'json' } do
    namespace :v1 do
      resources :operations do
        post 'import', on: :collection
      end
      resources :pre_assignments do
        post 'update_comment', on: :collection
      end
    end
  end

  namespace :tunnel do
    resource :order do
      member do
        get  :address_choice
        post :option_choice
        get  :summary
        post :pay
      end
    end
    resources :addresses
  end

  namespace :admin do
    root :to => "admin#index"
    resources :users, except: %w(edit destroy) do
      get  'search_by_code',                   on: :collection
      post 'send_reset_password_instructions', on: :member
    end
    resources :invoices, only: %w(index show update) do
      get  'archive',     on: :collection
      post 'debit_order', on: :collection
    end
    resources :cms_images
    resources :products, except: 'show'
    resources :product_options, except: %w(index show)
    resources :product_groups, except: %w(index show)
    namespace :log do
      resources :visits
    end
    resources :gray_labels
    resources :scanning_providers
    resources :dematboxes, only: %w(index show destroy) do
      post 'subscribe', on: :member
    end
    resources :dematbox_services, only: %w(index destroy) do
      post 'load_from_external', on: :collection
    end
    resources :dematbox_files, only: :index
    resources :retrievers, as: :fiduceo_retrievers, only: %w(index edit destroy)
    resources :provider_wishes, as: :fiduceo_provider_wishes, only: %w(index edit) do
      put 'start_process', on: :member
      put 'reject',        on: :member
      put 'accept',        on: :member
    end
    resources :emailed_documents, only: %w(index show) do
      get 'show_errors', on: :member
    end

    authenticated :user, -> user { user.is_admin } do
      match '/delayed_job' => DelayedJobWeb, anchor: false, via: [:get, :post]
    end
  end

  match '/admin/reporting(/:year)', controller: 'Admin::Reporting', action: :index

  match '*a', :to => 'errors#routing'
end
