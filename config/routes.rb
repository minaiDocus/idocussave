Idocus::Application.routes.draw do
  mount Ckeditor::Engine => '/ckeditor'
  root to: 'account/account#index'

  wash_out :dematbox

  devise_for :users

  get '/account/documents/:id/download/:style', controller: 'account/documents', action: 'download'
  get '/account/documents/pieces/:id/download', controller: 'account/documents', action: 'piece'
  get '/account/invoices/:id/download/:style', controller: 'account/invoices', action: 'download'
  get '/account/compositions/download', controller: 'account/compositions', action: 'download'
  get '/account' => redirect('/account/documents')

  resources :compta

  resources :kits, only: %w(index create)
  get 'kits/:year/:month/:day', controller: 'kits', action: 'index', constraints: { year: /\d{4}/, month: /\d{1,2}/, day: /\d{1,2}/ }

  resources :receipts, only: %w(index create)
  get 'receipts/:year/:month/:day', controller: 'receipts', action: 'index', constraints: { year: /\d{4}/, month: /\d{1,2}/, day: /\d{1,2}/ }

  resources :scans, only: %w(index create) do
    patch :add,       on: :member
    patch :overwrite, on: :member
    get   :cancel,    on: :collection
  end
  get 'scans/:year/:month/:day', controller: 'scans', action: 'index', constraints: { year: /\d{4}/, month: /\d{1,2}/, day: /\d{1,2}/ }

  resources :returns, only: %w(index create)
  get 'returns/:year/:month/:day', controller: 'returns', action: 'index', constraints: { year: /\d{4}/, month: /\d{1,2}/, day: /\d{1,2}/ }

  scope '/scans' do
    resource :return_labels
  end
  get  '/scans/return_labels/new/:year/:month/:day', controller: 'return_labels', action: 'new'
  post '/scans/return_labels/:year/:month/:day',     controller: 'return_labels', action: 'create'

  get 'gr/sessions/:slug/create',  controller: 'gray_label/sessions', action: 'create'
  get 'gr/sessions/:slug/destroy', controller: 'gray_label/sessions', action: 'destroy'

  post 'dropbox/webhook', controller: 'dropboxes', action: 'webhook'

  namespace :account do
    root to: 'account/account#index'
    resources :organizations, except: :destroy do
      get   :edit_options,   on: :collection
      get   :close_confirm,  on: :member
      patch :update_options, on: :collection
      patch :suspend,        on: :member
      patch :unsuspend,      on: :member
      patch :activate,       on: :member
      patch :deactivate,     on: :member
      resources :addresses, controller: 'organization_addresses'
      resource :period_options, only: %w(edit update), controller: 'organization_period_options' do
        get  :select_propagation_options, on: :member
        post :propagate,                  on: :member
      end
      resource :file_naming_policy, only: %w(edit update) do
        patch 'preview', on: :member
      end
      resources :account_number_rules
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
      resource :csv_descriptor, only: %w(edit update), controller: 'organization_csv_descriptors'
      resources :groups
      resources :collaborators do
        resource :rights, only: %w(edit update)
        resource :file_storage_authorizations, only: %w(edit update)
      end
      resources :customers do
        get   'info',                    on: :collection
        get   'search_by_code',          on: :collection
        get   'edit_ibiza',              on: :member
        patch 'update_ibiza',            on: :member
        get   'edit_period_options',     on: :member
        patch 'update_period_options',   on: :member
        get   'edit_knowings_options',   on: :member
        patch 'update_knowings_options', on: :member
        get   'edit_compta_options',     on: :member
        patch 'update_compta_options',   on: :member
        get   'account_close_confirm',   on: :member
        patch 'close_account',           on: :member
        get   'account_reopen_confirm',  on: :member
        patch 'reopen_account',          on: :member
        resource :setup, only: [] do
          member do
            get 'next'
            get 'previous'
            get 'resume'
            get 'complete_later'
          end
        end
        resources :addresses, controller: 'customer_addresses'
        resource :accounting_plan, except: %w(new create destroy) do
          member do
            get    :import_model
            patch  :import
            delete :destroy_providers
            delete :destroy_customers
          end
          resources :vat_accounts do
            get   'edit_multiple',   on: :collection
            patch 'update_multiple', on: :collection
          end
        end
        resources :exercises
        resources :journals, except: %w(index show) do
          get  'select', on: :collection
          post 'copy',   on: :collection
        end
        resources :list_journals, only: %w(index)
        resource :csv_descriptor do
          patch 'activate',   on: :member
          patch 'deactivate', on: :member
        end
        resource :use_csv_descriptor, only: %w(edit update)
        resource :file_storage_authorizations, only: %w(edit update)
        resource :subscription
        with_options module: 'organization' do |r|
          r.resources :retrievers, as: :fiduceo_retrievers do
            get   'list',                 on: :collection
            post  'fetch',                on: :member
            get   'wait_for_user_action', on: :member
            patch 'update_transaction',   on: :member
          end
          r.resources :bank_accounts, only: %w(index edit update) do
            post 'update_multiple', on: :collection
          end
          r.resources :retriever_transactions, only: %w(index show)
          r.resources :retrieved_banking_operations, only: :index
          r.resources :retrieved_documents, only: %w(index show) do
            get 'piece', on: :member
            get 'select', on: :collection
            patch 'validate', on: :collection
          end
          r.resource :dematbox, only: %w(create destroy)
        end
        resources :orders, except: %w(index show)
      end
      resources :journals, except: 'show'
      resource :organization_subscription, only: %w(edit update) do
        get   'select_options',    on: :collection
        patch 'propagate_options', on: :collection
      end
      resource :ibiza, controller: 'ibiza', only: %w(create edit update)
      resources :ibiza_users, only: 'index'
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
    resource :google_drive do
      post 'authorize_url', on: :member
      get  'callback',      on: :member
    end
    resource :external_file_storage do
      post :use,                  on: :member
      post :update_path_settings, on: :member
    end
    resource :ftp do
      post :configure, on: :member
    end
    resource :payment do
      post 'debit_mandate_notify', on: :member
      get  'use_debit_mandate',    on: :member
    end
    resource :debit_mandate do
      get 'return', :on => :member
    end
    resources :compositions do
      delete 'reset', :on => :collection
    end
    resource :dematbox, only: %w(create destroy)

    resources :retrievers, as: :fiduceo_retrievers do
      get   'list',                 on: :collection
      post  'fetch',                on: :member
      get   'wait_for_user_action', on: :member
      patch 'update_transaction',   on: :member
    end
    resources :provider_wishes, as: :fiduceo_provider_wishes
    resources :retriever_transactions
    resources :retrieved_banking_operations
    resources :retrieved_documents do
      get   'piece',    on: :member
      get   'select',   on: :collection
      patch 'validate', on: :collection
    end
    resources :bank_accounts do
      patch 'update_multiple', on: :collection
    end

    # namespace :charts do
    #   resources :operations
    #   resources :balances
    # end

    resources :emailed_documents do
      post 'regenerate_code', on: :collection
    end

    resources :paper_processes, only: :index

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
    resources :users, except: %w(new create edit destroy) do
      get  'search_by_code',                   on: :collection
      post 'send_reset_password_instructions', on: :member
    end
    resources :invoices, only: %w(index show update) do
      get  'archive',     on: :collection
      post 'debit_order', on: :collection
      post 'download',    on: :collection
    end
    resources :cms_images
    get 'subscriptions', controller: 'subscriptions', action: 'index'
    get 'orders', controller: 'orders', action: 'index'
    resources :subscription_options, except: %w(index show)
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
    resources :retrievers, as: :fiduceo_retrievers, only: %w(index edit destroy) do
      post 'fetch', on: :collection
    end
    resources :provider_wishes, as: :fiduceo_provider_wishes, only: %w(index show edit) do
      patch 'start_process', on: :member
      patch 'reject',        on: :member
      patch 'accept',        on: :member
    end
    resources :emailed_documents, only: %w(index show) do
      get 'show_errors', on: :member
    end
    resources :pre_assignment_deliveries, only: %w(index show)
    resources :notification_settings, only: %w(index) do
      get  'edit_error',             on: :collection
      post 'update_error',           on: :collection
      get  'edit_subscription',      on: :collection
      post 'update_subscription',    on: :collection
      get  'edit_dematbox_order',    on: :collection
      post 'update_dematbox_order',  on: :collection
      get  'edit_paper_set_order',   on: :collection
      post 'update_paper_set_order', on: :collection
      get  'edit_ibiza',             on: :collection
      post 'update_ibiza',           on: :collection
      get  'edit_scans',             on: :collection
      post 'update_scans',           on: :collection
    end

    authenticated :user, -> user { user.is_admin } do
      match '/delayed_job' => DelayedJobWeb, anchor: false, via: [:get, :post]
    end
  end

  get 'admin/ocr_needed_temp_packs',           controller: 'admin/admin', action: 'ocr_needed_temp_packs'
  get 'admin/bundle_needed_temp_packs',        controller: 'admin/admin', action: 'bundle_needed_temp_packs'
  get 'admin/bundling_temp_packs',             controller: 'admin/admin', action: 'bundling_temp_packs'
  get 'admin/processing_temp_packs',           controller: 'admin/admin', action: 'processing_temp_packs'
  get 'admin/currently_being_delivered_packs', controller: 'admin/admin', action: 'currently_being_delivered_packs'
  get 'admin/failed_packs_delivery',           controller: 'admin/admin', action: 'failed_packs_delivery'
  get 'admin/blocked_pre_assignments',         controller: 'admin/admin', action: 'blocked_pre_assignments'
  get 'admin/awaiting_pre_assignments',        controller: 'admin/admin', action: 'awaiting_pre_assignments'
  get 'admin/reports_delivery',                controller: 'admin/admin', action: 'reports_delivery'
  get 'admin/failed_reports_delivery',         controller: 'admin/admin', action: 'failed_reports_delivery'

  get '/admin/reporting(/:year)', controller: 'admin/reporting', action: :index
  get '/admin/process_reporting(/:year)(/:month)', controller: 'admin/process_reporting', action: :index

  match '*a', :to => 'errors#routing', via: :all
end
