class StartRemoveOldMongoReferenceAndDeprecatedTables < ActiveRecord::Migration[5.2]
  def change
    drop_table :fiduceo_retrievers
    drop_table :fiduceo_transactions
    drop_table :delayed_backend_mongoid_jobs

    remove_column :account_book_types, :mongo_id
    remove_column :account_book_types, :user_id_mongo_id
    remove_column :account_book_types, :organization_id_mongo_id

    remove_column :account_number_rules, :mongo_id
    remove_column :account_number_rules, :organization_id_mongo_id

    remove_column :accounting_plan_items, :mongo_id
    remove_column :accounting_plan_items, :accounting_plan_itemable_id_mongo_id

    remove_column :accounting_plan_vat_accounts, :mongo_id
    remove_column :accounting_plan_vat_accounts, :accounting_plan_id_mongo_id

    remove_column :accounting_plans, :mongo_id
    remove_column :accounting_plans, :user_id_mongo_id

    remove_column :addresses, :mongo_id
    remove_column :addresses, :locatable_id_mongo_id

    remove_column :bank_accounts, :mongo_id
    remove_column :bank_accounts, :user_id_mongo_id
    remove_column :bank_accounts, :retriever_id_mongo_id

    remove_column :boxes, :mongo_id
    remove_column :boxes, :external_file_storage_id_mongo_id

    remove_column :cms_images, :cloud_content_file_name
    remove_column :cms_images, :cloud_content_file_size
    remove_column :cms_images, :cloud_content_content_type

    remove_column :cms_images, :mongo_id

    remove_column :compositions, :mongo_id
    remove_column :compositions, :user_id_mongo_id

    remove_column :csv_descriptors, :mongo_id
    remove_column :csv_descriptors, :user_id_mongo_id

    remove_column :dba_sequences, :mongo_id

    remove_column :dematbox, :mongo_id
    remove_column :dematbox, :user_id_mongo_id

    remove_column :dematbox_services, :mongo_id
    remove_column :dematbox_subscribed_services, :dematbox_id_mongo_id

    remove_column :document_deliveries, :mongo_id

    remove_column :documents, :cloud_content_file_name
    remove_column :documents, :cloud_content_file_size
    remove_column :documents, :cloud_content_content_type

    remove_column :documents, :pack_id_mongo_id

    remove_column :dropbox_basics, :mongo_id
    remove_column :dropbox_basics, :external_file_storage_id_mongo_id

    remove_column :emails, :cloud_original_content_file_name
    remove_column :emails, :cloud_original_content_file_size
    remove_column :emails, :cloud_original_content_updated_at
    remove_column :emails, :cloud_original_content_fingerprint
    remove_column :emails, :cloud_original_content_content_type

    remove_column :emails, :to_user_id_mongo_id
    remove_column :emails, :from_user_id_mongo_id

    remove_column :exercises, :mongo_id
    remove_column :exercises, :user_id_mongo_id

    remove_column :expense_categories, :mongo_id
    remove_column :expense_categories, :account_book_type_id_mongo_id

    remove_column :external_file_storages, :mongo_id
    remove_column :external_file_storages, :user_id_mongo_id

    remove_column :file_naming_policies, :mongo_id
    remove_column :file_naming_policies, :organization_id_mongo_id

    remove_column :file_sending_kits, :mongo_id
    remove_column :file_sending_kits, :organization_id_mongo_id

    remove_column :ftps, :mongo_id
    remove_column :ftps, :external_file_storage_id_mongo_id

    remove_column :google_docs, :mongo_id
    remove_column :google_docs, :external_file_storage_id_mongo_id

    remove_column :groups, :mongo_id
    remove_column :groups, :organization_id_mongo_id

    remove_column :ibizas, :mongo_id
    remove_column :ibizas, :organization_id_mongo_id

    remove_column :invoices, :cloud_content_file_name
    remove_column :invoices, :cloud_content_file_size
    remove_column :invoices, :cloud_content_updated_at
    remove_column :invoices, :cloud_content_fingerprint
    remove_column :invoices, :cloud_content_content_type

    remove_column :invoices, :user_id_mongo_id
    remove_column :invoices, :period_id_mongo_id
    remove_column :invoices, :subscription_id_mongo_id
    remove_column :invoices, :organization_id_mongo_id

    remove_column :knowings, :mongo_id
    remove_column :knowings, :organization_id_mongo_id

    remove_column :new_provider_requests, :mongo_id
    remove_column :new_provider_requests, :user_id_mongo_id

    remove_column :operations, :mongo_id
    remove_column :operations, :user_id_mongo_id
    remove_column :operations, :organization_id_mongo_id

    remove_column :orders, :mongo_id
    remove_column :orders, :user_id_mongo_id
    remove_column :orders, :period_id_mongo_id
    remove_column :orders, :organization_id_mongo_id

    remove_column :organization_rights, :mongo_id
    remove_column :organization_rights, :user_id_mongo_id

    remove_column :organizations, :mongo_id
    remove_column :organizations, :leader_id_mongo_id

    remove_column :pack_dividers, :mongo_id
    remove_column :pack_dividers, :pack_id_mongo_id

    remove_column :pack_pieces, :cloud_content_file_name
    remove_column :pack_pieces, :cloud_content_file_size
    remove_column :pack_pieces, :cloud_content_updated_at
    remove_column :pack_pieces, :cloud_content_fingerprint
    remove_column :pack_pieces, :cloud_content_content_type

    remove_column :pack_pieces, :pack_id_mongo_id
    remove_column :pack_pieces, :user_id_mongo_id
    remove_column :pack_pieces, :organization_id_mongo_id

    remove_column :pack_report_expenses, :mongo_id
    remove_column :pack_report_expenses, :user_id_mongo_id
    remove_column :pack_report_expenses, :piece_id_mongo_id
    remove_column :pack_report_expenses, :report_id_mongo_id
    remove_column :pack_report_expenses, :organization_id_mongo_id

    remove_column :pack_report_observation_guests, :mongo_id
    remove_column :pack_report_observation_guests, :observation_id_mongo_id

    remove_column :pack_report_observations, :mongo_id
    remove_column :pack_report_observations, :expense_id_mongo_id

    remove_column :pack_report_preseizure_accounts, :mongo_id
    remove_column :pack_report_preseizure_accounts, :preseizure_id_mongo_id

    remove_column :pack_report_preseizure_entries, :mongo_id
    remove_column :pack_report_preseizure_entries, :account_id_mongo_id
    remove_column :pack_report_preseizure_entries, :preseizure_id_mongo_id

    remove_column :pack_report_preseizures, :mongo_id
    remove_column :pack_report_preseizures, :user_id_mongo_id
    remove_column :pack_report_preseizures, :piece_id_mongo_id
    remove_column :pack_report_preseizures, :report_id_mongo_id
    remove_column :pack_report_preseizures, :operation_id_mongo_id
    remove_column :pack_report_preseizures, :organization_id_mongo_id

    remove_column :pack_reports, :mongo_id
    remove_column :pack_reports, :user_id_mongo_id
    remove_column :pack_reports, :pack_id_mongo_id
    remove_column :pack_reports, :document_id_mongo_id
    remove_column :pack_reports, :organization_id_mongo_id

    remove_column :packs, :owner_id_mongo_id
    remove_column :packs, :organization_id_mongo_id

    remove_column :paper_processes, :mongo_id
    remove_column :paper_processes, :user_id_mongo_id
    remove_column :paper_processes, :organization_id_mongo_id
    remove_column :paper_processes, :period_document_id_mongo_id

    remove_column :period_billings, :mongo_id
    remove_column :period_billings, :period_id_mongo_id

    remove_column :period_deliveries, :mongo_id
    remove_column :period_deliveries, :period_id_mongo_id

    remove_column :period_documents, :mongo_id
    remove_column :period_documents, :user_id_mongo_id
    remove_column :period_documents, :pack_id_mongo_id
    remove_column :period_documents, :period_id_mongo_id
    remove_column :period_documents, :organization_id_mongo_id

    remove_column :periods, :mongo_id
    remove_column :periods, :user_id_mongo_id
    remove_column :periods, :subscription_id_mongo_id
    remove_column :periods, :organization_id_mongo_id

    remove_column :product_option_orders, :mongo_id
    remove_column :product_option_orders, :product_optionable_id_mongo_id

    remove_column :reminder_emails, :mongo_id
    remove_column :reminder_emails, :organization_id_mongo_id

    remove_column :remote_files, :mongo_id
    remove_column :remote_files, :user_id_mongo_id
    remove_column :remote_files, :pack_id_mongo_id
    remove_column :remote_files, :group_id_mongo_id
    remove_column :remote_files, :remotable_id_mongo_id
    remove_column :remote_files, :organization_id_mongo_id

    remove_column :scanning_providers, :mongo_id

    remove_column :settings, :mongo_id

    remove_column :subscription_options, :mongo_id

    remove_column :subscriptions, :mongo_id
    remove_column :subscriptions, :user_id_mongo_id
    remove_column :subscriptions, :organization_id_mongo_id

    remove_column :temp_documents, :cloud_content_file_name
    remove_column :temp_documents, :cloud_content_file_size
    remove_column :temp_documents, :cloud_content_updated_at
    remove_column :temp_documents, :cloud_content_fingerprint
    remove_column :temp_documents, :cloud_content_content_type
    remove_column :temp_documents, :cloud_raw_content_file_name
    remove_column :temp_documents, :cloud_raw_content_file_size
    remove_column :temp_documents, :cloud_raw_content_updated_at
    remove_column :temp_documents, :cloud_raw_content_fingerprint
    remove_column :temp_documents, :cloud_raw_content_content_type

    remove_column :temp_documents, :piece_id_mongo_id
    remove_column :temp_documents, :user_id_mongo_id
    remove_column :temp_documents, :email_id_mongo_id
    remove_column :temp_documents, :temp_pack_id_mongo_id
    remove_column :temp_documents, :organization_id_mongo_id
    remove_column :temp_documents, :document_delivery_id_mongo_id
    remove_column :temp_documents, :fiduceo_retriever_id_mongo_id

    remove_column :temp_packs, :user_id_mongo_id
    remove_column :temp_packs, :organization_id_mongo_id
    remove_column :temp_packs, :document_delivery_id_mongo_id

    remove_column :user_options, :mongo_id
    remove_column :user_options, :user_id_mongo_id

    remove_column :users, :mongo_id
    remove_column :users, :fiduceo_id
    remove_column :users, :parent_id_mongo_id
    remove_column :users, :organization_id_mongo_id
    remove_column :users, :scanning_provider_id_mongo_id
  end
end
