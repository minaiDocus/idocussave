require 'sidekiq/web'
require 'sidekiq-scheduler/web'

Idocus::Application.routes.draw do
  mount Ckeditor::Engine => '/ckeditor'
  root to: 'account/account#index'

  wash_out :dematbox

  devise_for :users

  authenticate :user, lambda { |u| u.is_admin } do
    mount Sidekiq::Web => '/sidekiq'
  end

  get '/account' => redirect('/account/documents')
  get '/account/compositions/download',                    controller: 'account/compositions', action: 'download'
  get '/account/invoices/:id/download/:style',             controller: 'account/invoices',  action: 'download'
  get '/account/documents/:id/download/:style',            controller: 'account/documents', action: 'download'
  get '/account/documents/processing/:id/download/:style', controller: 'account/documents', action: 'download_processing'
  get '/account/documents/pieces/:id/download',            controller: 'account/documents', action: 'piece'

  resources :compta

  resources :kits, only: %w(index create)
  get 'kits/:year/:month/:day', controller: 'kits', action: 'index', constraints: { year: /\d{4}/, month: /\d{1,2}/, day: /\d{1,2}/ }


  resources :receipts, only: %w(index create)
  get 'receipts/:year/:month/:day', controller: 'receipts', action: 'index', constraints: { year: /\d{4}/, month: /\d{1,2}/, day: /\d{1,2}/ }


  resources :scans, only: %w(index create) do
    patch :add,       on: :member
    get   :cancel,    on: :collection
    patch :overwrite, on: :member
  end
  get 'scans/:year/:month/:day', controller: 'scans', action: 'index', constraints: { year: /\d{4}/, month: /\d{1,2}/, day: /\d{1,2}/ }


  resources :returns, only: %w(index create)
  get 'returns/:year/:month/:day', controller: 'returns', action: 'index', constraints: { year: /\d{4}/, month: /\d{1,2}/, day: /\d{1,2}/ }


  scope '/scans' do
    resource :return_labels
  end
  post '/scans/return_labels/:year/:month/:day',     controller: 'return_labels', action: 'create'
  get  '/scans/return_labels/new/:year/:month/:day', controller: 'return_labels', action: 'new'

  get '/paper_set_orders', controller: 'paper_set_orders', action: 'index'

  post 'dropbox/webhook', controller: 'dropboxes', action: 'webhook'
  get  'dropbox/webhook', controller: 'dropboxes', action: 'verify'

  post 'retriever/callback', controller: 'retrievers', action: 'callback'

  get '/docs/download', controller: 'account/docs', action: 'download'

  post 'my_company_files/upload', controller: :my_company_files, action: 'upload'

  namespace :account do
    root to: 'account/account#index'

    resources :account, only: :index do
      collection do
        post :choose_default_summary
        get :last_scans
        get :last_uploads
        get :last_dematbox_scans
        get :last_retrieved
      end
    end

    # Named like that to avoid conflict with the routes of groups
    resources :group_organizations, controller_name: 'organization_groups'

    resources :organizations, except: :destroy do
      patch :suspend,        on: :member
      patch :activate,       on: :member
      patch :unsuspend,      on: :member
      patch :deactivate,     on: :member
      get   :edit_options,   on: :collection
      get   :close_confirm,  on: :member
      patch :update_options, on: :collection

      resources :addresses, controller: 'organization_addresses'

      resource :period_options, only: %w(edit update), controller: 'organization_period_options' do
        post :propagate,                  on: :member
        get  :select_propagation_options, on: :member
      end

      resource :file_naming_policy, only: %w(edit update) do
        patch 'preview', on: :member
      end

      resources :account_number_rules do
        patch   'import',                    on: :collection
        get     'import_form',               on: :collection
        get     'import_model',              on: :collection
        post    'export_or_destroy',         on: :collection
      end

      resource :knowings, only: %w(new create edit update)

      resource :ftps, only: %w(edit update destroy), module: 'organization' do
        post :fetch_now, on: :collection
      end

      resources :reminder_emails, except: :index do
        post 'deliver', on: :member
      end

      resource :file_sending_kit, only: %w(edit update) do
        get  'mails',           on: :member
        get  'select',          on: :member
        get  'folders',         on: :member
        post 'generate',        on: :member
        get  'customer_labels', on: :member
        get  'workshop_labels', on: :member
      end

      resource :csv_descriptor, only: %w(edit update), controller: 'organization_csv_descriptors'

      resources :groups

      resources :collaborators do
        member do
          post   :add_to_organization
          delete :remove_from_organization
        end

        resource :rights, only: %w(edit update)
        resource :file_storage_authorizations, only: %w(edit update)
      end

      resources :paper_set_orders do
        get  'select_for_orders', on: :collection
        post 'order_multiple',   on: :collection
        post 'create_multiple', on: :collection
      end

      resources :customers do
        collection do
          get   'info'
          get   'search'
        end
        member do
          get   'edit_ibiza'
          patch 'update_ibiza'
          patch 'close_account'
          patch 'reopen_account'
          get   'edit_compta_options'
          get   'edit_period_options'
          patch 'update_compta_options'
          patch 'update_period_options'
          get   'edit_knowings_options'
          get   'account_close_confirm'
          get   'account_reopen_confirm'
          patch 'update_knowings_options'
          get   'edit_mcf'
          get   'show_mcf_errors'
          patch 'update_mcf'
        end

        resource :setup, only: [] do
          member do
            get 'next'
            get 'resume'
            get 'previous'
            get 'complete_later'
          end
        end

        resources :addresses, controller: 'customer_addresses'

        resource :accounting_plan, except: %w(new create destroy) do
          member do
            patch  :import
            get    :import_model
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
          post 'copy',   on: :collection
          get  'select', on: :collection
        end

        resources :ibizabox_folders, only: %w(update) do
          patch 'refresh', on: :collection
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
          r.resources :retrievers do
            get   'list',                     on: :collection
            post  'run',                      on: :member
            get   'waiting_additionnal_info', on: :member
            patch 'additionnal_info',         on: :member
          end
          r.resources :new_provider_requests, only: %w(index new create edit update)
          r.resources :bank_accounts, only: %w(index edit update) do
            post 'update_multiple', on: :collection
          end
          r.resources :retrieved_banking_operations, only: :index do
            post 'force_processing', on: :collection
          end

          r.resources :retrieved_documents, only: %w(index show) do
            get   'piece',    on: :member
            get   'select',   on: :collection
            patch 'validate', on: :collection
          end
          r.resource :dematbox, only: %w(create destroy)

          r.resources :ibizabox_documents, only: %w(index show) do
            get   'piece',    on: :member
            get   'select',   on: :collection
            patch 'validate', on: :collection
          end

        end


        resources :orders, except: %w(index show)
      end

      resources :journals, except: 'show'

      resource :organization_subscription, only: %w(edit update) do
        get   'select_options',    on: :collection
        patch 'propagate_options', on: :collection
      end

      resource :ibiza, controller: 'ibiza', only: %w(create edit update)

      resources :ibiza_users,                       only: :index
      resources :mcf_users,                         only: :index
      resources :pre_assignments,                   only: :index
      resources :pre_assignment_delivery_errors,    only: :index
      resources :pre_assignment_ignored,            only: :index do
        post :force_pre_assignment, on: :collection
      end
      resources :pre_assignment_blocked_duplicates, only: :index do
        post :update_multiple, on: :collection
      end

      resources :pack_reports, only: :index do
        post 'deliver',            on: :member
        get  'select_to_download', on: :member
        post 'download',           on: :member
      end

      resources :preseizures, only: %w(index update) do
        post 'deliver', on: :member
      end

      resources :preseizure_accounts

      resources :account_sharings, only: %w(index new create destroy), module: :organization do
        post :accept, on: :member
      end
      resources :guest_collaborators do
        get 'search', on: :collection
      end

      resource :mcf_settings, only: %w(edit update destroy) do
        post :authorize
        get  :callback
      end
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

    resource :ftp, only: %w(edit update destroy)

    resource :payment do
      post 'debit_mandate_notify', on: :member
      get  'use_debit_mandate',    on: :member
    end

    resources :compositions do
      delete 'reset', on: :collection
    end

    resource :dematbox, only: %w(create destroy)

    resources :retrievers do
      get   'list',                     on: :collection
      post  'run',                      on: :member
      get   'waiting_additionnal_info', on: :member
      patch 'additionnal_info',         on: :member
    end
    resources :new_provider_requests, only: %w(index new create edit update)
    resources :retrieved_banking_operations

    resources :retrieved_documents do
      get   'piece',    on: :member
      get   'select',   on: :collection
      patch 'validate', on: :collection
    end

    resources :bank_accounts do
      patch 'update_multiple', on: :collection
    end

    resources :emailed_documents do
      post 'regenerate_code', on: :collection
    end

    resources :paper_processes, only: :index

    resource :suspended, only: :show

    resources :notifications, only: :index do
      get 'latest', on: :collection
      get 'link_through', on: :member
    end

    resources :account_sharings, only: %w(new create destroy) do
      get 'new_request', on: :collection
      post 'create_request', on: :collection
    end

    resources :analytics, only: %w(index)

    get :news, controller: :news, action: :index
  end

  namespace :api, defaults: { format: 'json' } do
    namespace :v1 do
      resources :pre_assignments do
        post 'update_comment', on: :collection
      end
    end

    namespace :mobile do
      devise_for :users

      resources :remote_authentication do
        collection do
          post :request_connexion
          post :ping
        end
      end

      resources :data_loader do
        collection do
          post :load_customers
          post :load_user_organizations
          post :load_packs
          post :load_documents_processed
          post :load_documents_processing
          post :load_stats
          post :get_packs
          get  :render_image_documents
        end
      end

      resources :account_sharing do
        collection do
          post :load_shared_docs
          post :load_shared_contacts

          post :get_list_collaborators
          post :get_list_customers
          post :add_shared_docs
          post :add_shared_contacts
          post :edit_shared_contacts
          post :accept_shared_docs
          post :delete_shared_docs
          post :delete_shared_contacts

          post :load_shared_docs_customers
          post :add_shared_docs_customers
          post :add_sharing_request_customers
        end
      end

      resources :file_uploader do
        post 'load_file_upload_params', on: :collection
      end

      resources :firebase_notification do
        collection do
          post :get_notifications
          post :release_new_notifications
          post :register_firebase_token
        end
      end

      resources :error_report do
        post 'send_error_report', on: :collection
      end
    end
  end

  namespace :admin do
    root to: 'admin#index'
    resources :users, except: %w(new create edit destroy) do
      get  'search_by_code',                   on: :collection
      post 'send_reset_password_instructions', on: :member
    end

    resources :invoices, only: %w(index show update) do
      get  'archive',     on: :collection
      post 'download',    on: :collection
      post 'debit_order', on: :collection
    end

    resources :cms_images

    get 'orders', controller: 'orders', action: 'index'
    get 'subscriptions', controller: 'subscriptions', action: 'index'

    resources :mobile_reporting, only: %w(index) do
      get 'mobile_users_stats(/:month)(/:year)', action: 'download_mobile_users', on: :collection, as: :download_users
      get 'mobile_documents_stats(/:month)(/:year)', action: 'download_mobile_documents', on: :collection, as: :download_documents
    end

    resources :events, only: %w(index show)
    resources :scanning_providers
    resources :subscription_options, except: %w(show)

    resources :dematboxes, only: %w(index show destroy) do
      post 'subscribe', on: :member
    end

    resources :dematbox_services, only: %w(index destroy) do
      post 'load_from_external', on: :collection
    end

    resources :dematbox_files, only: :index

    resources :retrievers, only: %w(index edit destroy) do
      post 'run',     on: :collection
      post 'fetcher', on: :collection
      get 'fetcher',  on: :collection
    end

    resources :new_provider_requests, only: %w(index show edit) do
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

    resources :notifications, only: %w(index)

    resources :account_sharings, only: %w(index)

    resources :pre_assignment_blocked_duplicates, only: :index

    resources :news do
      post :publish, on: :member
    end
  end

  get 'admin/reports_delivery',                controller: 'admin/admin', action: 'reports_delivery'
  get '/admin/reporting(/:year)',              controller: 'admin/reporting', action: :index
  get 'admin/bundling_temp_packs',             controller: 'admin/admin', action: 'bundling_temp_packs'
  get 'admin/ocr_needed_temp_packs',           controller: 'admin/admin', action: 'ocr_needed_temp_packs'
  get 'admin/processing_temp_packs',           controller: 'admin/admin', action: 'processing_temp_packs'
  get 'admin/failed_packs_delivery',           controller: 'admin/admin', action: 'failed_packs_delivery'
  get 'admin/failed_reports_delivery',         controller: 'admin/admin', action: 'failed_reports_delivery'
  get 'admin/blocked_pre_assignments',         controller: 'admin/admin', action: 'blocked_pre_assignments'
  get 'admin/bundle_needed_temp_packs',        controller: 'admin/admin', action: 'bundle_needed_temp_packs'
  get 'admin/awaiting_pre_assignments',        controller: 'admin/admin', action: 'awaiting_pre_assignments'
  get 'admin/currently_being_delivered_packs', controller: 'admin/admin', action: 'currently_being_delivered_packs'
  get '/admin/process_reporting(/:year)(/:month)', controller: 'admin/process_reporting', action: :index

  get  'admin/retriever_services',             controller: 'admin/retriever_services', action: :index
  post 'admin/retriever_services/update_list', controller: 'admin/retriever_services', action: :update_list

  match '*a', to: 'errors#routing', via: :all
end
