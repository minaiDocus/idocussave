# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_02_17_172908) do

  create_table "account_book_types", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "name"
    t.string "pseudonym"
    t.boolean "use_pseudonym_for_import", default: true
    t.string "description", default: "", null: false
    t.integer "position", default: 0, null: false
    t.integer "entry_type", default: 0, null: false
    t.string "currency", limit: 5, default: "EUR"
    t.string "domain", default: "", null: false
    t.string "account_number"
    t.string "default_account_number"
    t.string "charge_account"
    t.string "default_charge_account"
    t.text "vat_accounts"
    t.string "vat_account"
    t.string "vat_account_10"
    t.string "vat_account_8_5"
    t.string "vat_account_5_5"
    t.string "vat_account_2_1"
    t.string "anomaly_account"
    t.boolean "is_default", default: false
    t.boolean "is_expense_categories_editable", default: false, null: false
    t.text "instructions"
    t.integer "organization_id"
    t.integer "user_id"
    t.integer "analytic_reference_id"
    t.boolean "jefacture_enabled"
    t.index ["organization_id"], name: "organization_id"
    t.index ["user_id"], name: "user_id"
  end

  create_table "account_number_rules", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "name"
    t.string "rule_type"
    t.string "rule_target", default: "both"
    t.string "affect"
    t.text "content"
    t.string "third_party_account"
    t.integer "priority", default: 0, null: false
    t.string "categorization"
    t.integer "organization_id"
    t.index ["organization_id"], name: "organization_id"
  end

  create_table "account_number_rules_users", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "user_id"
    t.integer "account_number_rule_id"
  end

  create_table "account_sharings", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "organization_id"
    t.integer "collaborator_id"
    t.integer "account_id"
    t.integer "authorized_by_id"
    t.boolean "is_approved", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_account_sharings_on_account_id"
    t.index ["authorized_by_id"], name: "index_account_sharings_on_authorized_by_id"
    t.index ["collaborator_id"], name: "index_account_sharings_on_collaborator_id"
    t.index ["is_approved"], name: "index_account_sharings_on_is_approved"
    t.index ["organization_id"], name: "index_account_sharings_on_organization_id"
  end

  create_table "accounting_plan_items", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "third_party_account"
    t.string "third_party_name"
    t.string "conterpart_account"
    t.string "code"
    t.integer "accounting_plan_itemable_id"
    t.string "accounting_plan_itemable_type"
    t.string "kind"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.boolean "is_updated", default: true
    t.boolean "vat_autoliquidation"
    t.string "vat_autoliquidation_credit_account"
    t.string "vat_autoliquidation_debit_account"
    t.index ["accounting_plan_itemable_id"], name: "accounting_plan_itemable_id"
    t.index ["accounting_plan_itemable_type"], name: "accounting_plan_itemable_type"
    t.index ["is_updated"], name: "index_accounting_plan_items_on_is_updated"
  end

  create_table "accounting_plan_vat_accounts", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "code"
    t.string "nature"
    t.string "account_number"
    t.integer "accounting_plan_id"
    t.index ["accounting_plan_id"], name: "accounting_plan_id"
  end

  create_table "accounting_plans", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "last_checked_at"
    t.integer "user_id"
    t.boolean "is_updating", default: false
    t.index ["user_id"], name: "user_id"
  end

  create_table "active_storage_attachments", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "addresses", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "first_name"
    t.string "last_name"
    t.string "email"
    t.string "company"
    t.string "company_number"
    t.string "address_1"
    t.string "address_2"
    t.string "city"
    t.string "zip"
    t.string "state"
    t.string "country"
    t.string "building"
    t.string "place_called_or_postal_box"
    t.string "door_code"
    t.string "other"
    t.string "phone"
    t.string "phone_mobile"
    t.boolean "is_for_billing", default: false, null: false
    t.boolean "is_for_paper_return", default: false, null: false
    t.boolean "is_for_paper_set_shipping", default: false, null: false
    t.boolean "is_for_dematbox_shipping", default: false, null: false
    t.integer "locatable_id"
    t.string "locatable_type"
    t.index ["locatable_id"], name: "locatable_id"
    t.index ["locatable_type"], name: "locatable_type"
  end

  create_table "analytic_references", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "a1_name"
    t.text "a1_references"
    t.decimal "a1_ventilation", precision: 5, scale: 2, default: "0.0"
    t.string "a1_axis1"
    t.string "a1_axis2"
    t.string "a1_axis3"
    t.string "a2_name"
    t.text "a2_references"
    t.decimal "a2_ventilation", precision: 5, scale: 2, default: "0.0"
    t.string "a2_axis1"
    t.string "a2_axis2"
    t.string "a2_axis3"
    t.string "a3_name"
    t.text "a3_references"
    t.decimal "a3_ventilation", precision: 5, scale: 2, default: "0.0"
    t.string "a3_axis1"
    t.string "a3_axis2"
    t.string "a3_axis3"
  end

  create_table "archive_budgea_users", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "identifier"
    t.date "signin"
    t.string "platform"
    t.text "encrypted_access_token"
    t.boolean "exist"
    t.boolean "is_updated", default: false
    t.boolean "is_deleted", default: false
    t.datetime "deleted_date"
    t.index ["exist"], name: "index_archive_budgea_users_on_exist"
    t.index ["is_updated"], name: "index_archive_budgea_users_on_is_updated"
  end

  create_table "archive_invoices", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "archive_retrievers", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "owner_id"
    t.integer "budgea_id"
    t.integer "id_connector"
    t.string "state"
    t.text "error"
    t.text "error_message"
    t.datetime "last_update"
    t.datetime "created"
    t.boolean "active"
    t.datetime "last_push"
    t.datetime "next_try"
    t.datetime "expire"
    t.text "log"
    t.boolean "exist"
    t.boolean "is_updated", default: false
    t.boolean "is_deleted", default: false
    t.datetime "deleted_date"
    t.index ["active"], name: "index_archive_retrievers_on_active"
    t.index ["exist"], name: "index_archive_retrievers_on_exist"
    t.index ["is_updated"], name: "index_archive_retrievers_on_is_updated"
    t.index ["state"], name: "index_archive_retrievers_on_state"
  end

  create_table "archive_webhook_contents", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "synced_date"
    t.string "synced_type"
    t.text "json_content"
    t.integer "retriever_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "audits", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "auditable_id"
    t.string "auditable_type"
    t.integer "associated_id"
    t.string "associated_type"
    t.integer "user_id"
    t.string "user_type"
    t.string "username"
    t.string "action"
    t.text "audited_changes"
    t.integer "version", default: 0
    t.string "comment"
    t.string "remote_address"
    t.string "request_uuid"
    t.datetime "created_at"
    t.index ["associated_id", "associated_type"], name: "associated_index"
    t.index ["auditable_id", "auditable_type"], name: "auditable_index"
    t.index ["created_at"], name: "index_audits_on_created_at"
    t.index ["request_uuid"], name: "index_audits_on_request_uuid"
    t.index ["user_id", "user_type"], name: "user_index"
  end

  create_table "bank_accounts", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "bank_name"
    t.string "name"
    t.string "number"
    t.string "journal"
    t.string "currency", limit: 5, default: "EUR"
    t.text "original_currency"
    t.string "foreign_journal"
    t.string "accounting_number", default: "512000", null: false
    t.string "temporary_account", default: "471000", null: false
    t.date "start_date"
    t.integer "user_id"
    t.integer "retriever_id"
    t.string "api_id"
    t.string "api_name", default: "budgea"
    t.boolean "is_used", default: false
    t.boolean "is_to_be_disabled", default: false
    t.string "type_name"
    t.boolean "lock_old_operation", default: true
    t.integer "permitted_late_days", default: 30
    t.index ["retriever_id"], name: "retriever_id"
    t.index ["user_id"], name: "user_id"
  end

  create_table "boxes", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "path", default: "iDocus/:code/:year:month/:account_book", null: false
    t.boolean "is_configured", default: false, null: false
    t.integer "external_file_storage_id"
    t.string "encrypted_access_token"
    t.string "encrypted_refresh_token"
    t.index ["external_file_storage_id"], name: "external_file_storage_id"
  end

  create_table "bridge_accounts", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "encrypted_username"
    t.string "encrypted_password"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "identifier"
    t.bigint "user_id"
    t.index ["user_id"], name: "index_bridge_accounts_on_user_id"
  end

  create_table "budgea_accounts", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "identifier"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.text "encrypted_access_token"
    t.index ["user_id"], name: "fk_rails_bc19f24997"
  end

  create_table "ckeditor_assets", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "data_file_name", null: false
    t.string "data_content_type"
    t.integer "data_file_size"
    t.string "data_fingerprint"
    t.integer "assetable_id"
    t.string "assetable_type", limit: 30
    t.string "type", limit: 30
    t.integer "width"
    t.integer "height"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assetable_type", "assetable_id"], name: "idx_ckeditor_assetable"
    t.index ["assetable_type", "type", "assetable_id"], name: "idx_ckeditor_assetable_type"
  end

  create_table "cms_images", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "original_file_name"
    t.string "content_file_name"
    t.string "content_content_type"
    t.integer "content_file_size"
    t.datetime "content_updated_at"
    t.string "content_fingerprint"
  end

  create_table "compositions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "name"
    t.string "path"
    t.text "document_ids"
    t.integer "user_id"
    t.index ["user_id"], name: "user_id"
  end

  create_table "connectors", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.text "capabilities"
    t.text "apis"
    t.text "active_apis"
    t.integer "budgea_id"
    t.string "fiduceo_ref"
    t.text "combined_fields"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "urls"
  end

  create_table "counter_error_script_mailers", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "error_type"
    t.integer "counter", default: 0
    t.boolean "is_enable", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "csv_descriptors", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "comma_as_number_separator", default: false, null: false
    t.text "directive"
    t.integer "organization_id"
    t.string "organization_id_mongo_id"
    t.integer "user_id"
    t.index ["organization_id"], name: "organization_id"
    t.index ["organization_id_mongo_id"], name: "organization_id_mongo_id"
    t.index ["user_id"], name: "user_id"
  end

  create_table "currency_rates", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "date"
    t.string "exchange_from", limit: 5
    t.string "exchange_to", limit: 5
    t.string "currency_name"
    t.float "exchange_rate"
    t.float "reverse_exchange_rate"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["date", "exchange_from", "exchange_to"], name: "index_exchange_name_date"
  end

  create_table "dba_sequences", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "locked_at"
    t.datetime "locked_until"
    t.string "name"
    t.integer "counter", default: 1, null: false
  end

  create_table "debit_mandates", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "transactionId"
    t.string "transactionStatus"
    t.string "transactionErrorCode"
    t.string "signatureOperationResult"
    t.string "signatureDate"
    t.string "mandateScore"
    t.string "clientReference"
    t.string "cardTransactionId"
    t.string "cardRequestId"
    t.string "cardOperationType"
    t.string "cardOperationResult"
    t.string "collectOperationResult"
    t.string "invoiceReference"
    t.string "invoiceAmount"
    t.string "invoiceExecutionDate"
    t.string "reference"
    t.string "title"
    t.string "firstName"
    t.string "lastName"
    t.string "email"
    t.string "bic"
    t.string "iban"
    t.string "RUM"
    t.string "companyName"
    t.string "organizationId"
    t.string "invoiceLine1"
    t.string "invoiceLine2"
    t.string "invoiceCity"
    t.string "invoiceCountry"
    t.string "invoicePostalCode"
    t.string "deliveryLine1"
    t.string "deliveryLine2"
    t.string "deliveryCity"
    t.string "deliveryCountry"
    t.string "deliveryPostalCode"
    t.integer "organization_id"
    t.index ["organization_id"], name: "index_debit_mandates_on_organization_id"
  end

  create_table "dematbox", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "is_configured", default: false, null: false
    t.datetime "beginning_configuration_at"
    t.integer "user_id"
    t.index ["user_id"], name: "user_id"
  end

  create_table "dematbox_services", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "name"
    t.string "pid"
    t.string "type"
    t.string "state", default: "unknown", null: false
  end

  create_table "dematbox_subscribed_services", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "mongo_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "name"
    t.string "pid"
    t.string "group_name"
    t.string "group_pid"
    t.boolean "is_for_current_period", default: true, null: false
    t.integer "dematbox_id"
    t.index ["dematbox_id"], name: "dematbox_id"
    t.index ["mongo_id"], name: "index_dematbox_subscribed_services_on_mongo_id"
  end

  create_table "document_deliveries", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "provider"
    t.date "date"
    t.boolean "is_processed"
    t.datetime "processed_at"
    t.integer "position", default: 1
  end

  create_table "documents", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "mongo_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "content_text", limit: 4294967295
    t.boolean "is_a_cover", default: false
    t.string "origin"
    t.text "tags", limit: 4294967295
    t.integer "position"
    t.boolean "dirty", default: true, null: false
    t.string "token"
    t.string "content_file_name"
    t.string "content_content_type"
    t.integer "content_file_size"
    t.datetime "content_updated_at"
    t.string "content_fingerprint"
    t.integer "pack_id"
    t.index ["dirty"], name: "index_documents_on_dirty"
    t.index ["is_a_cover"], name: "index_documents_on_is_a_cover"
    t.index ["mongo_id"], name: "index_documents_on_mongo_id"
    t.index ["origin"], name: "index_documents_on_origin"
    t.index ["pack_id"], name: "pack_id"
  end

  create_table "dropbox_basics", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "path", default: ":code/:year:month/:account_book/", null: false
    t.bigint "dropbox_id"
    t.datetime "changed_at"
    t.datetime "checked_at"
    t.text "delta_cursor", limit: 4294967295
    t.string "delta_path_prefix"
    t.text "import_folder_paths", limit: 4294967295
    t.integer "external_file_storage_id"
    t.string "encrypted_access_token"
    t.index ["external_file_storage_id"], name: "external_file_storage_id"
  end

  create_table "emails", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "mongo_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "originally_created_at"
    t.string "to"
    t.string "from"
    t.string "subject"
    t.text "attachment_names"
    t.integer "size", default: 0, null: false
    t.string "state", default: "created", null: false
    t.text "errors_list"
    t.boolean "is_error_notified", default: false, null: false
    t.string "original_content_file_name"
    t.string "original_content_content_type"
    t.integer "original_content_file_size"
    t.datetime "original_content_updated_at"
    t.string "original_content_fingerprint"
    t.integer "to_user_id"
    t.integer "from_user_id"
    t.string "message_id"
    t.index ["from_user_id"], name: "from_user_id"
    t.index ["mongo_id"], name: "index_emails_on_mongo_id"
    t.index ["to_user_id"], name: "to_user_id"
  end

  create_table "events", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "user_code"
    t.string "action"
    t.string "target_type"
    t.string "target_name"
    t.text "target_attributes"
    t.string "path"
    t.string "ip_address"
    t.integer "organization_id"
    t.integer "user_id"
    t.integer "target_id"
    t.index ["organization_id"], name: "organization_id"
    t.index ["user_id"], name: "user_id"
  end

  create_table "exact_online", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.text "encrypted_client_id"
    t.text "encrypted_client_secret"
    t.string "user_name"
    t.string "full_name"
    t.string "email"
    t.string "state"
    t.text "encrypted_refresh_token"
    t.text "encrypted_access_token"
    t.datetime "token_expires_at"
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "exercises", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.date "start_date"
    t.date "end_date"
    t.boolean "is_closed", default: false, null: false
    t.integer "user_id"
    t.index ["user_id"], name: "user_id"
  end

  create_table "expense_categories", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.integer "account_book_type_id"
    t.index ["account_book_type_id"], name: "account_book_type_id"
  end

  create_table "external_file_storages", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "path", default: "iDocus/:code/:year:month/:account_book/", null: false
    t.boolean "is_path_used", default: false, null: false
    t.integer "used", default: 0, null: false
    t.integer "authorized", default: 30, null: false
    t.integer "user_id"
    t.index ["user_id"], name: "user_id"
  end

  create_table "file_naming_policies", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "scope", default: "organization", null: false
    t.string "separator", default: "_", null: false
    t.string "first_user_identifier", default: "code", null: false
    t.integer "first_user_identifier_position", default: 1, null: false
    t.string "second_user_identifier", default: "", null: false
    t.integer "second_user_identifier_position", default: 1, null: false
    t.boolean "is_journal_used", default: true, null: false
    t.integer "journal_position", default: 2, null: false
    t.boolean "is_period_used", default: true, null: false
    t.integer "period_position", default: 3, null: false
    t.boolean "is_piece_number_used", default: true, null: false
    t.integer "piece_number_position", default: 4, null: false
    t.boolean "is_third_party_used", default: false, null: false
    t.integer "third_party_position", default: 5, null: false
    t.boolean "is_invoice_number_used", default: false, null: false
    t.integer "invoice_number_position", default: 6, null: false
    t.boolean "is_invoice_date_used", default: false, null: false
    t.integer "invoice_date_position", default: 7, null: false
    t.integer "organization_id"
    t.index ["organization_id"], name: "organization_id"
  end

  create_table "file_sending_kits", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "title", default: "Title", null: false
    t.text "instruction"
    t.integer "position", default: 0, null: false
    t.string "logo_path", default: "logo/path", null: false
    t.integer "logo_height", default: 0, null: false
    t.integer "logo_width", default: 0, null: false
    t.string "left_logo_path", default: "left/logo/path", null: false
    t.integer "left_logo_height", default: 0, null: false
    t.integer "left_logo_width", default: 0, null: false
    t.string "right_logo_path", default: "right/logo/path", null: false
    t.integer "right_logo_height", default: 0, null: false
    t.integer "right_logo_width", default: 0, null: false
    t.integer "organization_id"
    t.index ["organization_id"], name: "organization_id"
  end

  create_table "firebase_tokens", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "user_id"
    t.string "name"
    t.string "platform"
    t.datetime "last_registration_date"
    t.datetime "last_sending_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "name"], name: "index_owener_id_and_name"
  end

  create_table "ftps", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "path", default: "iDocus/:code/:year:month/:account_book/", null: false
    t.boolean "is_configured", default: false, null: false
    t.datetime "error_fetched_at"
    t.text "error_message", limit: 4294967295
    t.integer "external_file_storage_id"
    t.string "encrypted_host"
    t.string "encrypted_login"
    t.string "encrypted_password"
    t.string "encrypted_port"
    t.boolean "is_passive", default: true
    t.string "root_path", default: "/"
    t.datetime "import_checked_at"
    t.text "previous_import_paths"
    t.integer "organization_id"
    t.index ["external_file_storage_id"], name: "external_file_storage_id"
    t.index ["organization_id"], name: "index_ftps_on_organization_id"
  end

  create_table "google_docs", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "is_configured", default: false, null: false
    t.string "path", default: "iDocus/:code/:year:month/:account_book/", null: false
    t.integer "external_file_storage_id"
    t.text "encrypted_access_token"
    t.text "encrypted_refresh_token"
    t.text "encrypted_access_token_expires_at"
    t.index ["external_file_storage_id"], name: "external_file_storage_id"
  end

  create_table "groups", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "name"
    t.string "description"
    t.string "dropbox_delivery_folder", default: "iDocus_delivery/:code/:year:month/:account_book/", null: false
    t.boolean "is_dropbox_authorized", default: false, null: false
    t.integer "organization_id"
    t.index ["organization_id"], name: "organization_id"
  end

  create_table "groups_members", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "member_id", null: false
    t.integer "group_id", null: false
    t.index ["group_id"], name: "index_groups_members_on_group_id"
    t.index ["member_id", "group_id"], name: "index_groups_members_on_member_id_and_group_id", unique: true
    t.index ["member_id"], name: "index_groups_members_on_member_id"
  end

  create_table "groups_users", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "group_id", null: false
    t.index ["group_id"], name: "index_groups_users_on_group_id"
    t.index ["user_id", "group_id"], name: "index_groups_users_on_user_id_and_group_id", unique: true
    t.index ["user_id"], name: "index_groups_users_on_user_id"
  end

  create_table "ibizabox_folders", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "journal_id"
    t.integer "user_id"
    t.boolean "is_selection_needed", default: true
    t.string "state"
    t.datetime "last_checked_at"
    t.string "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "ibizas", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "state", default: "none", null: false
    t.string "state_2", default: "none", null: false
    t.text "description"
    t.string "description_separator", default: " - ", null: false
    t.text "piece_name_format"
    t.string "piece_name_format_sep", default: " ", null: false
    t.string "voucher_ref_target", default: "piece_number"
    t.boolean "is_auto_deliver", default: false, null: false
    t.integer "organization_id"
    t.text "encrypted_access_token"
    t.text "encrypted_access_token_2"
    t.boolean "is_analysis_activated", default: false
    t.boolean "is_analysis_to_validate", default: false
    t.index ["organization_id"], name: "organization_id"
  end

  create_table "invoice_settings", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "organization_id"
    t.bigint "user_id"
    t.string "user_code"
    t.string "journal_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_invoice_settings_on_organization_id"
    t.index ["user_id"], name: "index_invoice_settings_on_user_id"
  end

  create_table "invoices", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "mongo_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "number"
    t.float "vat_ratio", default: 1.2, null: false
    t.integer "amount_in_cents_w_vat"
    t.string "content_file_name"
    t.string "content_content_type"
    t.integer "content_file_size"
    t.datetime "content_updated_at"
    t.string "content_fingerprint"
    t.integer "organization_id"
    t.integer "user_id"
    t.integer "subscription_id"
    t.integer "period_id"
    t.index ["mongo_id"], name: "index_invoices_on_mongo_id"
    t.index ["organization_id"], name: "organization_id"
    t.index ["period_id"], name: "period_id"
    t.index ["subscription_id"], name: "subscription_id"
    t.index ["user_id"], name: "user_id"
  end

  create_table "job_processings", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.string "state"
    t.text "notifications"
    t.index ["finished_at"], name: "index_job_processings_on_finished_at"
    t.index ["name"], name: "index_job_processings_on_name"
    t.index ["state"], name: "index_job_processings_on_state"
  end

  create_table "knowings", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "is_active", default: true, null: false
    t.string "state", default: "not_performed", null: false
    t.string "pole_name", default: "Pièces", null: false
    t.boolean "is_third_party_included", default: false, null: false
    t.boolean "is_pre_assignment_state_included", default: false, null: false
    t.integer "organization_id"
    t.string "encrypted_url"
    t.string "encrypted_username"
    t.string "encrypted_password"
    t.index ["organization_id"], name: "organization_id"
  end

  create_table "mcf_documents", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "user_id"
    t.string "access_token"
    t.string "code"
    t.string "journal"
    t.string "original_file_name", default: ""
    t.text "file64", limit: 4294967295
    t.string "state", default: "ready"
    t.integer "retake_retry", default: 0
    t.datetime "retake_at"
    t.boolean "is_generated", default: false
    t.boolean "is_moved", default: false
    t.boolean "is_notified", default: false
    t.text "error_message"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.index ["user_id"], name: "index_mcf_documents_on_user_id"
  end

  create_table "mcf_settings", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "organization_id"
    t.string "encrypted_access_token"
    t.string "encrypted_refresh_token"
    t.string "encrypted_access_token_expires_at"
    t.string "delivery_path_pattern", default: "/:year:month/:account_book/"
    t.boolean "is_delivery_activated", default: true
    t.index ["organization_id"], name: "index_mcf_settings_on_organization_id"
  end

  create_table "members", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "role", default: "collaborator", null: false
    t.string "code", null: false
    t.boolean "manage_groups", default: true
    t.boolean "manage_collaborators", default: false
    t.boolean "manage_customers", default: true
    t.boolean "manage_journals", default: true
    t.boolean "manage_customer_journals", default: true
    t.index ["code"], name: "index_members_on_code", unique: true
    t.index ["organization_id", "user_id"], name: "index_organization_user_on_members", unique: true
    t.index ["role"], name: "index_members_on_role"
  end

  create_table "mobile_connexions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "user_id"
    t.string "platform"
    t.string "version"
    t.integer "periode"
    t.integer "daily_counter", default: 1
    t.date "date"
    t.index ["periode"], name: "index_mobile_connexions_on_periode"
    t.index ["platform"], name: "index_mobile_connexions_on_platform"
  end

  create_table "new_provider_requests", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "state", default: "pending", null: false
    t.string "name"
    t.datetime "notified_at"
    t.datetime "processing_at"
    t.integer "user_id"
    t.integer "api_id"
    t.boolean "is_sent", default: false
    t.text "encrypted_url"
    t.text "encrypted_description"
    t.text "encrypted_message"
    t.string "encrypted_email"
    t.string "encrypted_types"
    t.index ["user_id"], name: "user_id"
  end

  create_table "news", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "state", null: false
    t.string "title", null: false
    t.text "body", null: false
    t.string "target_audience", null: false
    t.string "url"
    t.datetime "published_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["published_at"], name: "index_news_on_published_at"
    t.index ["target_audience"], name: "index_news_on_target_audience"
  end

  create_table "notifiables_notifies", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "notifiable_id"
    t.string "notifiable_type"
    t.integer "notify_id"
    t.string "label"
    t.index ["notify_id", "notifiable_id", "notifiable_type", "label"], name: "index_notifiable"
  end

  create_table "notifications", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "user_id"
    t.string "notice_type", null: false
    t.boolean "is_read", default: false, null: false
    t.boolean "is_sent", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title"
    t.text "message"
    t.string "url"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "notifies", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.boolean "to_send_docs", default: true
    t.string "published_docs", default: "delay"
    t.boolean "reception_of_emailed_docs", default: true
    t.boolean "r_wrong_pass", default: false
    t.boolean "r_site_unavailable", default: false
    t.boolean "r_action_needed", default: false
    t.boolean "r_bug", default: false
    t.string "r_new_documents", default: "none"
    t.integer "r_new_documents_count", default: 0
    t.string "r_new_operations", default: "none"
    t.integer "r_new_operations_count", default: 0
    t.boolean "r_no_bank_account_configured", default: false
    t.boolean "document_being_processed", default: false
    t.boolean "paper_quota_reached", default: false
    t.boolean "new_pre_assignment_available", default: false
    t.boolean "dropbox_invalid_access_token", default: true
    t.boolean "dropbox_insufficient_space", default: true
    t.boolean "ftp_auth_failure", default: true
    t.boolean "detected_preseizure_duplication", default: false
    t.integer "detected_preseizure_duplication_count", default: 0
    t.integer "unblocked_preseizure_count", default: 0
    t.boolean "new_scanned_documents", default: false
    t.string "pre_assignment_delivery_errors", default: "none"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.boolean "pre_assignment_ignored_piece", default: false
    t.integer "pre_assignment_ignored_piece_count", default: 0
    t.boolean "mcf_document_errors", default: false
    t.boolean "pre_assignment_export", default: true
    t.index ["r_new_documents_count"], name: "index_notifies_on_r_new_documents_count"
    t.index ["r_new_operations_count"], name: "index_notifies_on_r_new_operations_count"
    t.index ["user_id"], name: "index_notifies_on_user_id"
  end

  create_table "operations", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.date "date"
    t.date "value_date"
    t.date "transaction_date"
    t.text "label", limit: 4294967295
    t.decimal "amount", precision: 11, scale: 2
    t.string "comment"
    t.string "supplier_found"
    t.integer "category_id"
    t.string "category"
    t.datetime "accessed_at"
    t.datetime "processed_at"
    t.boolean "is_locked"
    t.integer "organization_id"
    t.integer "user_id"
    t.integer "bank_account_id"
    t.string "bank_account_id_mongo_id"
    t.integer "pack_id"
    t.string "pack_id_mongo_id"
    t.integer "piece_id"
    t.string "piece_id_mongo_id"
    t.string "api_id"
    t.string "type_id"
    t.string "api_name", default: "budgea"
    t.string "type_name"
    t.boolean "is_coming", default: false
    t.datetime "deleted_at"
    t.datetime "forced_processing_at"
    t.integer "forced_processing_by_user_id"
    t.text "currency"
    t.index ["api_id"], name: "fiduceo_id"
    t.index ["api_name"], name: "index_operations_on_api_name"
    t.index ["bank_account_id"], name: "bank_account_id"
    t.index ["bank_account_id_mongo_id"], name: "bank_account_id_mongo_id"
    t.index ["created_at"], name: "index_operations_on_created_at"
    t.index ["deleted_at"], name: "index_operations_on_deleted_at"
    t.index ["forced_processing_at"], name: "index_operations_on_forced_processing_at"
    t.index ["is_locked"], name: "index_operations_on_is_locked"
    t.index ["organization_id"], name: "organization_id"
    t.index ["pack_id"], name: "pack_id"
    t.index ["pack_id_mongo_id"], name: "pack_id_mongo_id"
    t.index ["piece_id"], name: "piece_id"
    t.index ["piece_id_mongo_id"], name: "piece_id_mongo_id"
    t.index ["processed_at"], name: "index_operations_on_processed_at"
    t.index ["user_id"], name: "user_id"
  end

  create_table "orders", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "locked_at"
    t.datetime "locked_until"
    t.string "state", default: "pending", null: false
    t.string "type"
    t.integer "price_in_cents_wo_vat"
    t.float "vat_ratio", default: 1.2, null: false
    t.integer "dematbox_count", default: 0, null: false
    t.integer "period_duration", default: 1, null: false
    t.integer "paper_set_casing_size", default: 0, null: false
    t.integer "paper_set_folder_count", default: 0, null: false
    t.date "paper_set_start_date"
    t.date "paper_set_end_date"
    t.integer "organization_id"
    t.integer "user_id"
    t.integer "period_id"
    t.datetime "address_created_at"
    t.datetime "address_updated_at"
    t.string "address_first_name"
    t.string "address_last_name"
    t.string "address_email"
    t.string "address_company"
    t.string "address_company_number"
    t.string "address_address_1"
    t.string "address_address_2"
    t.string "address_city"
    t.string "address_zip"
    t.string "address_state"
    t.string "address_country"
    t.string "address_building"
    t.string "address_place_called_or_postal_box"
    t.string "address_door_code"
    t.string "address_other"
    t.string "address_phone"
    t.string "address_phone_mobile"
    t.boolean "address_is_for_billing", default: false, null: false
    t.boolean "address_is_for_paper_return", default: false, null: false
    t.boolean "address_is_for_paper_set_shipping", default: false, null: false
    t.boolean "address_is_for_dematbox_shipping", default: false, null: false
    t.datetime "paper_return_address_created_at"
    t.datetime "paper_return_address_updated_at"
    t.string "paper_return_address_first_name"
    t.string "paper_return_address_last_name"
    t.string "paper_return_address_email"
    t.string "paper_return_address_company"
    t.string "paper_return_address_company_number"
    t.string "paper_return_address_address_1"
    t.string "paper_return_address_address_2"
    t.string "paper_return_address_city"
    t.string "paper_return_address_zip"
    t.string "paper_return_address_state"
    t.string "paper_return_address_country"
    t.string "paper_return_address_building"
    t.string "paper_return_address_place_called_or_postal_box"
    t.string "paper_return_address_door_code"
    t.string "paper_return_address_other"
    t.string "paper_return_address_phone"
    t.string "paper_return_address_phone_mobile"
    t.boolean "paper_return_address_is_for_billing", default: false, null: false
    t.boolean "paper_return_address_is_for_paper_return", default: false, null: false
    t.boolean "paper_return_address_is_for_paper_set_shipping", default: false, null: false
    t.boolean "paper_return_address_is_for_dematbox_shipping", default: false, null: false
    t.integer "paper_set_casing_count"
    t.index ["organization_id"], name: "organization_id"
    t.index ["period_id"], name: "period_id"
    t.index ["user_id"], name: "user_id"
  end

  create_table "organization_groups", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name", null: false
    t.string "description"
    t.boolean "is_auto_membership_activated", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "organization_rights", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "is_groups_management_authorized", default: true, null: false
    t.boolean "is_collaborators_management_authorized", default: false, null: false
    t.boolean "is_customers_management_authorized", default: true, null: false
    t.boolean "is_journals_management_authorized", default: true, null: false
    t.boolean "is_customer_journals_management_authorized", default: true, null: false
    t.integer "user_id"
    t.index ["user_id"], name: "user_id"
  end

  create_table "organizations", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "name"
    t.string "description"
    t.string "code"
    t.boolean "is_detail_authorized", default: false, null: false
    t.boolean "is_period_duration_editable", default: true, null: false
    t.boolean "is_test", default: false, null: false
    t.boolean "is_for_admin", default: false, null: false
    t.boolean "is_active", default: true, null: false
    t.boolean "is_suspended", default: false, null: false
    t.boolean "is_quadratus_used", default: false, null: false
    t.boolean "is_quadratus_auto_deliver", default: false
    t.boolean "is_pre_assignment_date_computed", default: false, null: false
    t.boolean "is_csv_descriptor_used", default: false, null: false
    t.boolean "is_csv_descriptor_auto_deliver", default: false
    t.boolean "is_coala_used", default: false, null: false
    t.boolean "is_coala_auto_deliver", default: false
    t.integer "authd_prev_period", default: 1, null: false
    t.integer "auth_prev_period_until_day", default: 11, null: false
    t.integer "auth_prev_period_until_month", default: 0, null: false
    t.integer "leader_id"
    t.boolean "is_operation_processing_forced", default: false
    t.boolean "is_operation_value_date_needed", default: false
    t.integer "preseizure_date_option", default: 0
    t.boolean "is_duplicate_blocker_activated", default: true
    t.integer "organization_group_id"
    t.boolean "subject_to_vat", default: true
    t.boolean "is_exact_online_used", default: false
    t.boolean "is_exact_online_auto_deliver", default: false
    t.string "invoice_mails"
    t.boolean "is_cegid_used", default: false
    t.boolean "is_cegid_auto_deliver", default: false
    t.boolean "is_fec_agiris_used", default: false
    t.boolean "is_fec_agiris_auto_deliver", default: false
    t.string "vat_identifier"
    t.string "jefacture_api_key"
    t.boolean "specific_mission"
    t.string "default_banking_provider"
    t.index ["leader_id"], name: "leader_id"
    t.index ["organization_group_id"], name: "index_organizations_on_organization_group_id"
    t.index ["specific_mission"], name: "index_organizations_on_specific_mission"
  end

  create_table "pack_dividers", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "name"
    t.string "type"
    t.string "origin"
    t.boolean "is_a_cover", default: false, null: false
    t.integer "pages_number"
    t.integer "position"
    t.integer "pack_id"
    t.index ["is_a_cover"], name: "index_pack_dividers_on_is_a_cover"
    t.index ["origin"], name: "index_pack_dividers_on_origin"
    t.index ["pack_id"], name: "pack_id"
    t.index ["type"], name: "index_pack_dividers_on_type"
  end

  create_table "pack_pieces", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "mongo_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "name"
    t.integer "number"
    t.boolean "is_a_cover", default: false, null: false
    t.boolean "is_signed", default: false
    t.string "origin"
    t.integer "position"
    t.integer "pages_number", default: 0
    t.string "token"
    t.boolean "is_awaiting_pre_assignment", default: false, null: false
    t.string "pre_assignment_state", default: "ready"
    t.string "pre_assignment_comment"
    t.string "content_file_name"
    t.string "content_content_type"
    t.integer "content_file_size"
    t.datetime "content_updated_at"
    t.string "content_fingerprint"
    t.integer "organization_id"
    t.integer "user_id"
    t.integer "pack_id"
    t.integer "analytic_reference_id"
    t.text "content_text", limit: 4294967295
    t.text "tags"
    t.boolean "is_finalized", default: false
    t.datetime "delete_at"
    t.string "delete_by"
    t.integer "detected_third_party_id"
    t.index ["analytic_reference_id"], name: "index_pack_pieces_on_analytic_reference_id"
    t.index ["delete_at"], name: "index_pack_pieces_on_delete_at"
    t.index ["delete_by"], name: "index_pack_pieces_on_delete_by"
    t.index ["is_finalized"], name: "index_pack_pieces_on_is_finalized"
    t.index ["name"], name: "index_pack_pieces_on_name"
    t.index ["number"], name: "index_pack_pieces_on_number"
    t.index ["organization_id"], name: "organization_id"
    t.index ["origin"], name: "index_pack_pieces_on_origin"
    t.index ["pack_id"], name: "pack_id"
    t.index ["position"], name: "index_pack_pieces_on_position"
    t.index ["pre_assignment_state"], name: "index_pack_pieces_on_pre_assignment_state"
    t.index ["user_id"], name: "user_id"
  end

  create_table "pack_report_expenses", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float "amount_in_cents_wo_vat"
    t.float "amount_in_cents_w_vat"
    t.float "vat"
    t.date "date"
    t.string "type"
    t.string "origin"
    t.integer "obs_type"
    t.integer "position"
    t.integer "organization_id"
    t.integer "user_id"
    t.integer "report_id"
    t.integer "piece_id"
    t.index ["organization_id"], name: "organization_id"
    t.index ["piece_id"], name: "piece_id"
    t.index ["report_id"], name: "report_id"
    t.index ["user_id"], name: "user_id"
  end

  create_table "pack_report_observation_guests", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.integer "observation_id"
    t.index ["observation_id"], name: "observation_id"
  end

  create_table "pack_report_observations", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "comment"
    t.integer "expense_id"
    t.index ["expense_id"], name: "expense_id"
  end

  create_table "pack_report_preseizure_accounts", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "type"
    t.string "number"
    t.string "lettering"
    t.integer "preseizure_id"
    t.index ["preseizure_id"], name: "preseizure_id"
  end

  create_table "pack_report_preseizure_entries", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "type"
    t.string "number"
    t.decimal "amount", precision: 11, scale: 2
    t.integer "preseizure_id"
    t.integer "account_id"
    t.index ["account_id"], name: "account_id"
    t.index ["preseizure_id"], name: "preseizure_id"
  end

  create_table "pack_report_preseizures", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "type"
    t.datetime "date"
    t.datetime "deadline_date"
    t.text "operation_label"
    t.string "observation"
    t.integer "position"
    t.string "piece_number"
    t.decimal "amount", precision: 11, scale: 2
    t.string "currency"
    t.string "unit", limit: 5, default: "EUR"
    t.float "conversion_rate"
    t.string "third_party"
    t.integer "category_id"
    t.boolean "is_made_by_abbyy", default: false, null: false
    t.boolean "is_delivered", default: false, null: false
    t.datetime "delivery_tried_at"
    t.text "delivery_message"
    t.boolean "is_locked", default: false, null: false
    t.integer "organization_id"
    t.integer "user_id"
    t.integer "report_id"
    t.integer "piece_id"
    t.integer "operation_id"
    t.integer "similar_preseizure_id"
    t.datetime "duplicate_detected_at"
    t.boolean "is_blocked_for_duplication", default: false
    t.datetime "marked_as_duplicate_at"
    t.integer "marked_as_duplicate_by_user_id"
    t.datetime "duplicate_unblocked_at"
    t.integer "duplicate_unblocked_by_user_id"
    t.decimal "cached_amount", precision: 11, scale: 2
    t.string "is_delivered_to", default: ""
    t.string "exact_online_id"
    t.index ["duplicate_unblocked_by_user_id"], name: "index_pack_report_preseizures_on_duplicate_unblocked_by_user_id"
    t.index ["is_blocked_for_duplication"], name: "index_pack_report_preseizures_on_is_blocked_for_duplication"
    t.index ["is_delivered_to"], name: "index_pack_report_preseizures_on_is_delivered_to"
    t.index ["marked_as_duplicate_by_user_id"], name: "index_pack_report_preseizures_on_marked_as_duplicate_by_user_id"
    t.index ["operation_id"], name: "operation_id"
    t.index ["organization_id"], name: "organization_id"
    t.index ["piece_id"], name: "piece_id"
    t.index ["position"], name: "index_pack_report_preseizures_on_position"
    t.index ["report_id"], name: "report_id"
    t.index ["similar_preseizure_id"], name: "index_pack_report_preseizures_on_similar_preseizure_id"
    t.index ["third_party"], name: "index_pack_report_preseizures_on_third_party"
    t.index ["user_id"], name: "user_id"
  end

  create_table "pack_report_preseizures_pre_assignment_deliveries", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "pre_assignment_delivery_id"
    t.integer "preseizure_id"
  end

  create_table "pack_report_preseizures_pre_assignment_exports", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "preseizure_id"
    t.integer "pre_assignment_export_id"
  end

  create_table "pack_report_preseizures_remote_files", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "remote_file_id"
    t.integer "pack_report_preseizure_id"
  end

  create_table "pack_reports", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "name"
    t.string "type"
    t.boolean "is_delivered", default: false, null: false
    t.datetime "delivery_tried_at"
    t.text "delivery_message"
    t.boolean "is_locked", default: false, null: false
    t.integer "organization_id"
    t.integer "user_id"
    t.integer "pack_id"
    t.integer "document_id"
    t.string "is_delivered_to", default: ""
    t.index ["document_id"], name: "document_id"
    t.index ["is_delivered_to"], name: "index_pack_reports_on_is_delivered_to"
    t.index ["organization_id"], name: "organization_id"
    t.index ["pack_id"], name: "pack_id"
    t.index ["user_id"], name: "user_id"
  end

  create_table "packs", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "mongo_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "locked_at"
    t.datetime "locked_until"
    t.string "name"
    t.string "original_document_id"
    t.string "content_url"
    t.text "content_historic"
    t.text "tags"
    t.integer "pages_count", default: 0, null: false
    t.integer "scanned_pages_count", default: 0, null: false
    t.boolean "is_update_notified", default: true, null: false
    t.boolean "is_fully_processed", default: true, null: false
    t.boolean "is_indexing", default: false, null: false
    t.datetime "remote_files_updated_at"
    t.integer "owner_id"
    t.integer "organization_id"
    t.string "content_file_name"
    t.string "content_content_type"
    t.integer "content_file_size"
    t.datetime "content_updated_at"
    t.string "content_fingerprint"
    t.index ["mongo_id"], name: "index_packs_on_mongo_id"
    t.index ["organization_id"], name: "organization_id"
    t.index ["owner_id"], name: "owner_id"
  end

  create_table "paper_processes", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "type"
    t.string "tracking_number"
    t.string "customer_code"
    t.integer "journals_count"
    t.integer "periods_count"
    t.integer "letter_type"
    t.string "pack_name"
    t.integer "organization_id"
    t.integer "user_id"
    t.integer "period_document_id"
    t.integer "order_id"
    t.index ["order_id"], name: "index_paper_processes_on_order_id"
    t.index ["organization_id"], name: "organization_id"
    t.index ["period_document_id"], name: "period_document_id"
    t.index ["user_id"], name: "user_id"
  end

  create_table "period_billings", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "order", default: 1, null: false
    t.integer "amount_in_cents_wo_vat", default: 0, null: false
    t.integer "excesses_amount_in_cents_wo_vat", default: 0, null: false
    t.integer "scanned_pieces", default: 0, null: false
    t.integer "scanned_sheets", default: 0, null: false
    t.integer "scanned_pages", default: 0, null: false
    t.integer "dematbox_scanned_pieces", default: 0, null: false
    t.integer "dematbox_scanned_pages", default: 0, null: false
    t.integer "uploaded_pieces", default: 0, null: false
    t.integer "uploaded_pages", default: 0, null: false
    t.integer "retrieved_pieces", default: 0, null: false
    t.integer "retrieved_pages", default: 0, null: false
    t.integer "preseizure_pieces", default: 0, null: false
    t.integer "expense_pieces", default: 0, null: false
    t.integer "paperclips", default: 0, null: false
    t.integer "oversized", default: 0, null: false
    t.integer "excess_sheets", default: 0, null: false
    t.integer "excess_uploaded_pages", default: 0, null: false
    t.integer "excess_dematbox_scanned_pages", default: 0, null: false
    t.integer "excess_compta_pieces", default: 0, null: false
    t.integer "period_id"
    t.index ["period_id"], name: "period_id"
  end

  create_table "period_deliveries", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "state", default: "wait", null: false
    t.integer "period_id"
    t.index ["period_id"], name: "period_id"
  end

  create_table "period_documents", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "name", default: "", null: false
    t.integer "pieces", default: 0, null: false
    t.integer "pages", default: 0, null: false
    t.integer "scanned_pieces", default: 0, null: false
    t.integer "scanned_sheets", default: 0, null: false
    t.integer "scanned_pages", default: 0, null: false
    t.integer "dematbox_scanned_pieces", default: 0, null: false
    t.integer "dematbox_scanned_pages", default: 0, null: false
    t.integer "uploaded_pieces", default: 0, null: false
    t.integer "uploaded_pages", default: 0, null: false
    t.integer "retrieved_pieces", default: 0, null: false
    t.integer "retrieved_pages", default: 0, null: false
    t.integer "paperclips", default: 0, null: false
    t.integer "oversized", default: 0, null: false
    t.boolean "is_shared", default: true, null: false
    t.datetime "scanned_at"
    t.string "scanned_by"
    t.integer "organization_id"
    t.integer "user_id"
    t.integer "period_id"
    t.integer "pack_id"
    t.index ["organization_id"], name: "organization_id"
    t.index ["pack_id"], name: "pack_id"
    t.index ["period_id"], name: "period_id"
    t.index ["user_id"], name: "user_id"
  end

  create_table "periods", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "locked_at"
    t.datetime "locked_until"
    t.date "start_date"
    t.date "end_date"
    t.integer "duration", default: 1, null: false
    t.text "current_packages"
    t.boolean "is_centralized", default: true, null: false
    t.integer "price_in_cents_wo_vat", default: 0, null: false
    t.integer "products_price_in_cents_wo_vat", default: 0, null: false
    t.integer "recurrent_products_price_in_cents_wo_vat", default: 0, null: false
    t.integer "ponctual_products_price_in_cents_wo_vat", default: 0, null: false
    t.integer "orders_price_in_cents_wo_vat", default: 0, null: false
    t.integer "excesses_price_in_cents_wo_vat", default: 0, null: false
    t.float "tva_ratio", default: 1.2, null: false
    t.integer "max_sheets_authorized", default: 100, null: false
    t.integer "max_upload_pages_authorized", default: 200, null: false
    t.integer "max_dematbox_scan_pages_authorized", default: 200, null: false
    t.integer "max_preseizure_pieces_authorized", default: 100, null: false
    t.integer "max_expense_pieces_authorized", default: 100, null: false
    t.integer "max_paperclips_authorized", default: 0, null: false
    t.integer "max_oversized_authorized", default: 0, null: false
    t.integer "unit_price_of_excess_sheet", default: 12, null: false
    t.integer "unit_price_of_excess_upload", default: 6, null: false
    t.integer "unit_price_of_excess_dematbox_scan", default: 6, null: false
    t.integer "unit_price_of_excess_preseizure", default: 12, null: false
    t.integer "unit_price_of_excess_expense", default: 12, null: false
    t.integer "unit_price_of_excess_paperclips", default: 20, null: false
    t.integer "unit_price_of_excess_oversized", default: 100, null: false
    t.text "documents_name_tags"
    t.integer "pieces", default: 0, null: false
    t.integer "pages", default: 0, null: false
    t.integer "scanned_pieces", default: 0, null: false
    t.integer "scanned_sheets", default: 0, null: false
    t.integer "scanned_pages", default: 0, null: false
    t.integer "dematbox_scanned_pieces", default: 0, null: false
    t.integer "dematbox_scanned_pages", default: 0, null: false
    t.integer "uploaded_pieces", default: 0, null: false
    t.integer "uploaded_pages", default: 0, null: false
    t.integer "retrieved_pieces", default: 0, null: false
    t.integer "retrieved_pages", default: 0, null: false
    t.integer "paperclips", default: 0, null: false
    t.integer "oversized", default: 0, null: false
    t.integer "preseizure_pieces", default: 0, null: false
    t.integer "expense_pieces", default: 0, null: false
    t.integer "user_id"
    t.integer "organization_id"
    t.integer "subscription_id"
    t.datetime "delivery_created_at"
    t.datetime "delivery_updated_at"
    t.string "delivery_state", default: "wait", null: false
    t.boolean "is_paper_quota_reached_notified", default: false
    t.index ["organization_id"], name: "organization_id"
    t.index ["subscription_id"], name: "subscription_id"
    t.index ["user_id"], name: "user_id"
  end

  create_table "pre_assignment_deliveries", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "pack_name"
    t.string "state"
    t.boolean "is_auto"
    t.integer "total_item"
    t.date "grouped_date"
    t.text "data_to_deliver", limit: 4294967295
    t.text "error_message"
    t.boolean "is_to_notify"
    t.boolean "is_notified"
    t.datetime "notified_at"
    t.integer "organization_id"
    t.integer "report_id"
    t.integer "user_id"
    t.string "software_id"
    t.string "deliver_to", default: "ibiza"
    t.index ["deliver_to"], name: "index_pre_assignment_deliveries_on_deliver_to"
    t.index ["is_auto"], name: "index_pre_assignment_deliveries_on_is_auto"
    t.index ["is_notified"], name: "index_pre_assignment_deliveries_on_is_notified"
    t.index ["is_to_notify"], name: "index_pre_assignment_deliveries_on_is_to_notify"
    t.index ["organization_id"], name: "organization_id"
    t.index ["report_id"], name: "report_id"
    t.index ["state"], name: "index_pre_assignment_deliveries_on_state"
    t.index ["user_id"], name: "user_id"
  end

  create_table "pre_assignment_exports", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "state"
    t.string "pack_name"
    t.string "for"
    t.string "file_name"
    t.integer "total_item", default: 0
    t.text "error_message"
    t.boolean "is_notified", default: false
    t.datetime "notified_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "user_id"
    t.integer "organization_id"
    t.integer "report_id"
    t.index ["for"], name: "index_pre_assignment_exports_on_for"
    t.index ["pack_name"], name: "index_pre_assignment_exports_on_pack_name"
    t.index ["state"], name: "index_pre_assignment_exports_on_state"
  end

  create_table "product_option_orders", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.string "title"
    t.string "group_title"
    t.string "description"
    t.float "price_in_cents_wo_vat"
    t.integer "group_position"
    t.integer "position"
    t.integer "duration"
    t.integer "quantity"
    t.boolean "is_an_extra"
    t.boolean "is_to_be_disabled"
    t.boolean "is_frozen", default: false
    t.integer "product_optionable_id"
    t.string "product_optionable_type"
    t.index ["product_optionable_id"], name: "product_optionable_id"
    t.index ["product_optionable_type"], name: "product_optionable_type"
  end

  create_table "reminder_emails", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "name"
    t.string "subject"
    t.text "content"
    t.integer "delivery_day", default: 1, null: false
    t.integer "period", default: 1, null: false
    t.datetime "delivered_at"
    t.text "delivered_user_ids"
    t.text "processed_user_ids"
    t.integer "organization_id"
    t.index ["organization_id"], name: "organization_id"
  end

  create_table "remote_files", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "remotable_type"
    t.string "path", default: "", null: false
    t.string "temp_path", default: "", null: false
    t.string "extension", default: ".pdf", null: false
    t.integer "size"
    t.datetime "tried_at"
    t.string "state", default: "waiting", null: false
    t.string "service_name"
    t.text "error_message", limit: 4294967295
    t.integer "tried_count", default: 0, null: false
    t.integer "user_id"
    t.integer "pack_id"
    t.integer "organization_id"
    t.integer "group_id"
    t.integer "remotable_id"
    t.index ["extension"], name: "index_remote_files_on_extension"
    t.index ["group_id"], name: "group_id"
    t.index ["organization_id"], name: "organization_id"
    t.index ["pack_id"], name: "pack_id"
    t.index ["remotable_id"], name: "remotable_id"
    t.index ["service_name"], name: "index_remote_files_on_service_name"
    t.index ["state"], name: "index_remote_files_on_state"
    t.index ["tried_count"], name: "index_remote_files_on_tried_count"
    t.index ["user_id"], name: "user_id"
  end

  create_table "retrieved_data", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.text "state"
    t.text "error_message", limit: 16777215
    t.text "processed_connection_ids"
    t.datetime "content_updated_at"
    t.integer "content_file_size"
    t.string "content_content_type"
    t.string "content_file_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["user_id"], name: "fk_rails_c47071c4c1"
  end

  create_table "retrievers", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "budgea_id"
    t.string "name"
    t.string "journal_name"
    t.datetime "sync_at"
    t.boolean "is_sane", default: true
    t.boolean "is_new_password_needed", default: false
    t.boolean "is_selection_needed", default: true
    t.string "state"
    t.text "error_message"
    t.string "budgea_state"
    t.text "budgea_error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.integer "journal_id"
    t.integer "budgea_connector_id"
    t.string "service_name"
    t.text "capabilities"
    t.string "encrypted_login"
    t.string "encrypted_password"
    t.bigint "connector_id"
    t.integer "bridge_id"
    t.string "bridge_status"
    t.string "bridge_status_code_info"
    t.string "bridge_status_code_description"
    t.index ["connector_id"], name: "index_retrievers_on_connector_id"
    t.index ["journal_id"], name: "index_retrievers_on_journal_id"
    t.index ["state"], name: "index_retrievers_on_state"
    t.index ["user_id"], name: "index_retrievers_on_user_id"
  end

  create_table "retrievers_historics", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "user_id"
    t.integer "connector_id"
    t.integer "retriever_id"
    t.string "name"
    t.string "service_name"
    t.integer "banks_count", default: 0
    t.integer "operations_count", default: 0
    t.text "capabilities"
    t.index ["service_name"], name: "index_retrievers_historics_on_service_name"
  end

  create_table "sandbox_bank_accounts", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "api_id"
    t.string "api_name", default: "budgea"
    t.string "bank_name"
    t.string "name"
    t.string "number"
    t.boolean "is_used", default: false
    t.string "journal"
    t.string "foreign_journal"
    t.string "accounting_number", default: "512000"
    t.string "temporary_account", default: "471000"
    t.date "start_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.integer "retriever_id"
    t.string "type_name"
    t.index ["retriever_id"], name: "index_sandbox_bank_accounts_on_retriever_id"
    t.index ["user_id"], name: "index_sandbox_bank_accounts_on_user_id"
  end

  create_table "sandbox_documents", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "api_id"
    t.string "api_name", default: "budgea"
    t.text "retrieved_metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.integer "retriever_id"
    t.string "content_file_name"
    t.string "content_content_type"
    t.integer "content_file_size"
    t.datetime "content_updated_at"
    t.string "content_fingerprint"
    t.index ["api_id"], name: "index_sandbox_documents_on_api_id"
    t.index ["api_name"], name: "index_sandbox_documents_on_api_name"
    t.index ["retriever_id"], name: "index_sandbox_documents_on_retriever_id"
    t.index ["user_id"], name: "index_sandbox_documents_on_user_id"
  end

  create_table "sandbox_operations", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "api_id"
    t.string "api_name", default: "budgea"
    t.date "date"
    t.date "value_date"
    t.date "transaction_date"
    t.string "label"
    t.decimal "amount", precision: 10
    t.string "comment"
    t.string "supplier_found"
    t.string "type_name"
    t.integer "category_id"
    t.string "category"
    t.boolean "is_locked"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "organization_id"
    t.integer "user_id"
    t.integer "sandbox_bank_account_id"
    t.index ["api_id"], name: "index_sandbox_operations_on_api_id"
    t.index ["api_name"], name: "index_sandbox_operations_on_api_name"
    t.index ["organization_id"], name: "index_sandbox_operations_on_organization_id"
  end

  create_table "scanning_providers", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "name"
    t.string "code"
    t.boolean "is_default", default: false, null: false
  end

  create_table "sessions", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "settings", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.text "key"
    t.text "is_journals_modification_authorized"
    t.text "notify_errors_to"
    t.text "notify_ibiza_deliveries_to"
    t.text "notify_on_ibiza_delivery"
    t.text "notify_scans_not_delivered_to"
    t.text "notify_dematbox_order_to"
    t.text "notify_paper_set_order_to"
    t.text "micro_package_authorized_to"
    t.text "paper_process_operators"
    t.text "compta_operators"
    t.text "default_url"
    t.text "inner_url"
    t.text "notify_mcf_errors_to"
  end

  create_table "sftps", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "path", default: "iDocus/:code/:year:month/:account_book/", null: false
    t.boolean "is_configured", default: false, null: false
    t.datetime "error_fetched_at"
    t.text "error_message", limit: 4294967295
    t.bigint "external_file_storage_id"
    t.string "encrypted_host"
    t.string "encrypted_login"
    t.string "encrypted_password"
    t.string "encrypted_port"
    t.string "root_path", default: "/"
    t.datetime "import_checked_at"
    t.string "previous_import_paths"
    t.bigint "organization_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_file_storage_id"], name: "index_sftps_on_external_file_storage_id"
    t.index ["organization_id"], name: "index_sftps_on_organization_id"
  end

  create_table "softwares_settings", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "user_id"
    t.boolean "is_ibiza_used", default: false
    t.integer "is_ibiza_auto_deliver", default: -1, null: false
    t.integer "is_ibiza_auto_updating_accounting_plan", default: 1
    t.integer "is_ibiza_compta_analysis_activated", default: -1, null: false
    t.integer "is_ibiza_analysis_to_validate", default: -1, null: false
    t.boolean "is_coala_used", default: false
    t.integer "is_coala_auto_deliver", default: -1, null: false
    t.boolean "is_quadratus_used", default: false
    t.integer "is_quadratus_auto_deliver", default: -1, null: false
    t.boolean "is_csv_descriptor_used", default: false
    t.boolean "use_own_csv_descriptor_format", default: false
    t.integer "is_csv_descriptor_auto_deliver", default: -1, null: false
    t.boolean "is_exact_online_used", default: false
    t.integer "is_exact_online_auto_deliver", default: -1, null: false
    t.boolean "is_cegid_used", default: false
    t.integer "is_cegid_auto_deliver", default: -1, null: false
    t.boolean "is_fec_agiris_used", default: false
    t.integer "is_fec_agiris_auto_deliver", default: -1, null: false
    t.index ["is_cegid_used"], name: "index_softwares_settings_on_is_cegid_used"
    t.index ["is_coala_used"], name: "index_softwares_settings_on_is_coala_used"
    t.index ["is_csv_descriptor_used"], name: "index_softwares_settings_on_is_csv_descriptor_used"
    t.index ["is_exact_online_used"], name: "index_softwares_settings_on_is_exact_online_used"
    t.index ["is_fec_agiris_used"], name: "index_softwares_settings_on_is_fec_agiris_used"
    t.index ["is_ibiza_used"], name: "index_softwares_settings_on_is_ibiza_used"
    t.index ["is_quadratus_used"], name: "index_softwares_settings_on_is_quadratus_used"
    t.index ["user_id"], name: "index_softwares_settings_on_user_id"
  end

  create_table "statistics", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "information"
    t.float "counter", limit: 53
  end

  create_table "subscription_options", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "name"
    t.integer "price_in_cents_wo_vat", default: 0, null: false
    t.integer "position", default: 1, null: false
    t.integer "period_duration", default: 1, null: false
  end

  create_table "subscription_options_subscriptions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "subscription_id"
    t.integer "subscription_option_id"
  end

  create_table "subscription_statistics", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.date "month"
    t.integer "organization_id"
    t.string "organization_code"
    t.string "organization_name"
    t.text "options"
    t.text "consumption"
    t.text "customers"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["month"], name: "index_subscription_statistics_on_month"
    t.index ["organization_code"], name: "index_subscription_statistics_on_organization_code"
  end

  create_table "subscriptions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "period_duration", default: 1, null: false
    t.float "tva_ratio", default: 1.2, null: false
    t.text "current_packages"
    t.text "futur_packages"
    t.boolean "is_micro_package_active", default: false, null: false
    t.boolean "is_mini_package_active", default: false, null: false
    t.boolean "is_basic_package_active", default: false, null: false
    t.boolean "is_idox_package_active", default: false
    t.boolean "is_mail_package_active", default: false, null: false
    t.boolean "is_scan_box_package_active", default: false, null: false
    t.boolean "is_retriever_package_active", default: false, null: false
    t.boolean "is_annual_package_active", default: false, null: false
    t.integer "number_of_journals", default: 5, null: false
    t.boolean "is_pre_assignment_active", default: true, null: false
    t.boolean "is_micro_package_to_be_disabled"
    t.boolean "is_mini_package_to_be_disabled"
    t.boolean "is_basic_package_to_be_disabled"
    t.boolean "is_idox_package_to_be_disabled", default: false
    t.boolean "is_mail_package_to_be_disabled"
    t.boolean "is_scan_box_package_to_be_disabled"
    t.boolean "is_retriever_package_to_be_disabled"
    t.boolean "is_pre_assignment_to_be_disabled"
    t.date "start_date"
    t.date "end_date"
    t.integer "commitment_counter", default: 1
    t.integer "max_sheets_authorized", default: 100, null: false
    t.integer "max_upload_pages_authorized", default: 200, null: false
    t.integer "max_dematbox_scan_pages_authorized", default: 200, null: false
    t.integer "max_preseizure_pieces_authorized", default: 100, null: false
    t.integer "max_expense_pieces_authorized", default: 100, null: false
    t.integer "max_paperclips_authorized", default: 0, null: false
    t.integer "max_oversized_authorized", default: 0, null: false
    t.integer "unit_price_of_excess_sheet", default: 12, null: false
    t.integer "unit_price_of_excess_upload", default: 6, null: false
    t.integer "unit_price_of_excess_dematbox_scan", default: 6, null: false
    t.integer "unit_price_of_excess_preseizure", default: 12, null: false
    t.integer "unit_price_of_excess_expense", default: 12, null: false
    t.integer "unit_price_of_excess_paperclips", default: 20, null: false
    t.integer "unit_price_of_excess_oversized", default: 100, null: false
    t.integer "user_id"
    t.integer "organization_id"
    t.index ["is_idox_package_active"], name: "index_subscriptions_on_is_idox_package_active"
    t.index ["organization_id"], name: "organization_id"
    t.index ["user_id"], name: "user_id"
  end

  create_table "temp_document_metadata", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin", force: :cascade do |t|
    t.datetime "date"
    t.string "name", limit: 191
    t.decimal "amount", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "temp_document_id"
    t.index ["temp_document_id"], name: "index_temp_document_metadata_on_temp_document_id"
  end

  create_table "temp_documents", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "mongo_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "original_file_name"
    t.boolean "is_thumb_generated", default: false, null: false
    t.integer "pages_number"
    t.integer "position"
    t.boolean "is_an_original", default: true, null: false
    t.integer "parent_document_id"
    t.boolean "is_a_cover", default: false, null: false
    t.boolean "is_ocr_layer_applied"
    t.string "delivered_by"
    t.string "delivery_type"
    t.string "dematbox_text"
    t.string "dematbox_is_notified"
    t.string "dematbox_notified_at"
    t.text "retrieved_metadata", limit: 4294967295
    t.string "retriever_service_name"
    t.string "retriever_name"
    t.boolean "is_corruption_notified"
    t.datetime "corruption_notified_at"
    t.string "state", default: "created", null: false
    t.string "token"
    t.datetime "stated_at"
    t.boolean "is_locked", default: false, null: false
    t.text "scan_bundling_document_ids"
    t.string "content_file_name"
    t.string "content_content_type"
    t.integer "content_file_size"
    t.datetime "content_updated_at"
    t.string "content_fingerprint"
    t.string "original_fingerprint"
    t.string "raw_content_file_name"
    t.string "raw_content_content_type"
    t.integer "raw_content_file_size"
    t.datetime "raw_content_updated_at"
    t.string "raw_content_fingerprint"
    t.integer "organization_id"
    t.integer "user_id"
    t.integer "temp_pack_id"
    t.integer "document_delivery_id"
    t.integer "fiduceo_retriever_id"
    t.integer "email_id"
    t.integer "piece_id"
    t.string "dematbox_doc_id"
    t.string "dematbox_box_id"
    t.string "dematbox_service_id"
    t.string "api_id"
    t.string "api_name"
    t.text "metadata", limit: 16777215
    t.integer "retriever_id"
    t.integer "ibizabox_folder_id"
    t.integer "analytic_reference_id"
    t.index ["analytic_reference_id"], name: "index_temp_documents_on_analytic_reference_id"
    t.index ["api_id"], name: "index_temp_documents_on_api_id"
    t.index ["delivery_type"], name: "index_temp_documents_on_delivery_type"
    t.index ["document_delivery_id"], name: "document_delivery_id"
    t.index ["email_id"], name: "email_id"
    t.index ["fiduceo_retriever_id"], name: "fiduceo_retriever_id"
    t.index ["ibizabox_folder_id"], name: "index_temp_documents_on_ibizabox_folder_id"
    t.index ["is_an_original"], name: "index_temp_documents_on_is_an_original"
    t.index ["mongo_id"], name: "index_temp_documents_on_mongo_id"
    t.index ["organization_id"], name: "organization_id"
    t.index ["parent_document_id"], name: "index_temp_documents_on_parent_document_id"
    t.index ["piece_id"], name: "piece_id"
    t.index ["retriever_id"], name: "index_temp_documents_on_retriever_id"
    t.index ["state"], name: "index_temp_documents_on_state"
    t.index ["temp_pack_id"], name: "temp_pack_id"
    t.index ["user_id"], name: "index_temp_documents_on_user_id"
    t.index ["user_id"], name: "user_id"
  end

  create_table "temp_packs", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "mongo_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "locked_at"
    t.datetime "locked_until"
    t.string "name"
    t.integer "position_counter", default: 0, null: false
    t.integer "organization_id"
    t.integer "user_id"
    t.integer "document_delivery_id"
    t.index ["document_delivery_id"], name: "document_delivery_id"
    t.index ["mongo_id"], name: "index_temp_packs_on_mongo_id"
    t.index ["organization_id"], name: "organization_id"
    t.index ["user_id"], name: "user_id"
  end

  create_table "user_options", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "locked_at"
    t.datetime "locked_until"
    t.integer "max_number_of_journals", default: 5, null: false
    t.boolean "is_preassignment_authorized", default: false, null: false
    t.boolean "is_taxable", default: true, null: false
    t.integer "is_pre_assignment_date_computed", default: -1, null: false
    t.integer "is_auto_deliver", default: -1, null: false
    t.boolean "is_own_csv_descriptor_used", default: false, null: false
    t.boolean "is_upload_authorized", default: false, null: false
    t.integer "user_id"
    t.boolean "is_retriever_authorized", default: false
    t.integer "is_operation_processing_forced", default: -1, null: false
    t.integer "is_operation_value_date_needed", default: -1, null: false
    t.integer "preseizure_date_option", default: -1
    t.string "dashboard_default_summary", default: "last_scans"
    t.integer "is_compta_analysis_activated", default: -1
    t.boolean "skip_accounting_plan_finder", default: false
    t.boolean "keep_account_validation", default: false
    t.string "default_banking_provider"
    t.index ["user_id"], name: "user_id"
  end

  create_table "users", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "email"
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.string "authentication_token"
    t.boolean "is_admin", default: false, null: false
    t.string "code"
    t.string "first_name"
    t.string "last_name"
    t.string "phone_number"
    t.string "company"
    t.boolean "is_prescriber", default: false, null: false
    t.boolean "is_developer", default: false
    t.boolean "is_fake_prescriber", default: false, null: false
    t.datetime "inactive_at"
    t.string "dropbox_delivery_folder", default: "iDocus_delivery/:code/:year:month/:account_book/", null: false
    t.boolean "is_dropbox_extended_authorized", default: false, null: false
    t.boolean "is_centralized", default: true, null: false
    t.boolean "is_operator"
    t.string "knowings_code"
    t.integer "knowings_visibility", default: 0, null: false
    t.boolean "is_disabled", default: false, null: false
    t.string "stamp_name", default: ":code :account_book :period :piece_num", null: false
    t.boolean "is_stamp_background_filled", default: false, null: false
    t.boolean "is_access_by_token_active", default: true, null: false
    t.boolean "is_dematbox_authorized", default: false, null: false
    t.datetime "return_label_generated_at"
    t.string "ibiza_id"
    t.boolean "is_fiduceo_authorized", default: false, null: false
    t.string "email_code"
    t.integer "authd_prev_period", default: 1, null: false
    t.integer "auth_prev_period_until_day", default: 11, null: false
    t.integer "auth_prev_period_until_month", default: 0, null: false
    t.string "current_configuration_step"
    t.string "last_configuration_step"
    t.datetime "organization_rights_created_at"
    t.datetime "organization_rights_updated_at"
    t.boolean "organization_rights_is_groups_management_authorized", default: true, null: false
    t.boolean "organization_rights_is_collaborators_management_authorized", default: false, null: false
    t.boolean "is_pre_assignement_displayed", default: false
    t.boolean "organization_rights_is_customers_management_authorized", default: true, null: false
    t.boolean "organization_rights_is_journals_management_authorized", default: true, null: false
    t.boolean "organization_rights_is_customer_journals_management_authorized", default: true, null: false
    t.integer "organization_id"
    t.integer "parent_id"
    t.integer "scanning_provider_id"
    t.text "group_ids"
    t.boolean "is_guest", default: false
    t.datetime "news_read_at"
    t.string "mcf_storage"
    t.integer "manager_id"
    t.string "jefacture_account_id"
    t.index ["manager_id"], name: "index_users_on_manager_id"
    t.index ["organization_id"], name: "organization_id"
    t.index ["parent_id"], name: "parent_id"
    t.index ["scanning_provider_id"], name: "scanning_provider_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "budgea_accounts", "users"
  add_foreign_key "debit_mandates", "organizations"
  add_foreign_key "notifications", "users"
  add_foreign_key "retrieved_data", "users"
end
