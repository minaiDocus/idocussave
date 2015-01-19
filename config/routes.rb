Idocus::Application.routes.draw do
  root to: 'account/account#index'

  wash_out :dematbox

  devise_for :users

  match '/account/documents/:id/download/:style', controller: 'account/documents', action: 'download', via: :get
  match '/account/documents/pieces/:id/download', controller: 'account/documents', action: 'piece', via: :get
  match '/account/invoices/:id/download/:style', controller: 'account/invoices', action: 'download', via: :get
  match '/account/compositions/download', controller: 'account/compositions', action: 'download', via: :get
  match '/account' => redirect('/account/documents')

  resources :compta

  resources :kits, only: %w(index create) do
    put 'overwrite', on: :member
    get 'cancel',    on: :collection
  end
  get 'kits/:year/:month/:day', controller: 'kits', action: 'index', constraints: { year: /\d{4}/, month: /\d{1,2}/, day: /\d{1,2}/ }

  resources :scans, only: %w(index create) do
    put :add,       on: :member
    put :overwrite, on: :member
    get :cancel,    on: :collection
  end
  get 'scans/:year/:month/:day', controller: 'scans', action: 'index', constraints: { year: /\d{4}/, month: /\d{1,2}/, day: /\d{1,2}/ }

  scope '/scans' do
    resource :return_labels
  end
  get  '/scans/return_labels/new/:year/:month/:day', controller: 'return_labels', action: 'new'
  post '/scans/return_labels/:year/:month/:day',     controller: 'return_labels', action: 'create'

  match 'gr/sessions/:slug/create',  controller: 'gray_label/sessions', action: 'create',  via: :get
  match 'gr/sessions/:slug/destroy', controller: 'gray_label/sessions', action: 'destroy', via: :get

  namespace :account do
    root to: 'account/account#index'
    resources :organizations, except: :destroy do
      get :edit_options,   on: :collection
      put :update_options, on: :collection
      put :suspend,        on: :member
      put :unsuspend,      on: :member
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
        get 'account_close_confirm', on: :member
        put 'close_account',         on: :member
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
      resource :ibiza, controller: 'ibiza', only: %w(create edit update) do
        get 'refresh_users_cache', on: :member
      end
      resources :pre_assignments, only: :index
      resources :pre_assignment_delivery_errors, only: :index
      resources :pack_reports, only: :index do
        post 'deliver',            on: :member
        get  'select_to_download', on: :member
        post 'download',           on: :member
      end
      resources :preseizures, only: %w(index update) do
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

    resource :profile
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
      post 'mode',                 on: :member
      post 'debit_mandate_notify', on: :member
      get  'use_debit_mandate',    on: :member
      get  'credit',               on: :member
    end
    resource :debit_mandate do
      get 'return', :on => :member
    end
    resources :compositions do
      delete 'reset', :on => :collection
    end
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

    # namespace :charts do
    #   resources :operations
    #   resources :balances
    # end

    resources :emailed_documents do
      post 'regenerate_code', on: :collection
    end

    resource :suspended, only: :show
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
    resources :events, only: %w(index show)
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
    resources :provider_wishes, as: :fiduceo_provider_wishes, only: %w(index show edit) do
      put 'start_process', on: :member
      put 'reject',        on: :member
      put 'accept',        on: :member
    end
    resources :emailed_documents, only: %w(index show) do
      get 'show_errors', on: :member
    end
    resources :pre_assignment_deliveries, only: %w(index show)
    resources :notification_settings, only: %w(index) do
      get  'edit_error',          on: :collection
      post 'update_error',        on: :collection
      get  'edit_subscription',   on: :collection
      post 'update_subscription', on: :collection
      get  'edit_ibiza',          on: :collection
      post 'update_ibiza',        on: :collection
    end

    authenticated :user, -> user { user.is_admin } do
      match '/delayed_job' => DelayedJobWeb, anchor: false, via: [:get, :post]
    end
  end

  match '/admin/reporting(/:year)', controller: 'Admin::Reporting', action: :index
  match '/admin/process_reporting(/:year)(/:month)', controller: 'Admin::ProcessReporting', action: :index

  match '*a', :to => 'errors#routing'
end
