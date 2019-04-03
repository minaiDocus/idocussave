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

ActiveRecord::Schema.define(version: 20191003081504) do
  create_table "account_book_types", force: :cascade do |t|
    t.string   "mongo_id",                       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",                           limit: 255
    t.string   "pseudonym",                      limit: 255
    t.string   "description",                    limit: 255,   default: "",    null: false
    t.integer  "position",                       limit: 4,     default: 0,     null: false
    t.integer  "entry_type",                     limit: 4,     default: 0,     null: false
    t.string   "currency",                       limit: 5,     default: "EUR"
    t.string   "domain",                         limit: 255,   default: "",    null: false
    t.string   "account_number",                 limit: 255
    t.string   "default_account_number",         limit: 255
    t.string   "charge_account",                 limit: 255
    t.string   "default_charge_account",         limit: 255
    t.string   "vat_account",                    limit: 255
    t.string   "vat_account_10",                 limit: 255
    t.string   "vat_account_8_5",                limit: 255
    t.string   "vat_account_5_5",                limit: 255
    t.string   "vat_account_2_1",                limit: 255
    t.string   "anomaly_account",                limit: 255
    t.boolean  "is_default",                                   default: false
    t.boolean  "is_expense_categories_editable",               default: false, null: false
    t.text     "instructions",                   limit: 65535
    t.integer  "organization_id",                limit: 4
    t.string   "organization_id_mongo_id",       limit: 255
    t.integer  "user_id",                        limit: 4
    t.string   "user_id_mongo_id",               limit: 255
    t.integer  "analytic_reference_id",          limit: 4
  end

  add_index "account_book_types", ["mongo_id"], name: "index_account_book_types_on_mongo_id", using: :btree
  add_index "account_book_types", ["organization_id"], name: "organization_id", using: :btree
  add_index "account_book_types", ["organization_id_mongo_id"], name: "organization_id_mongo_id", using: :btree
  add_index "account_book_types", ["user_id"], name: "user_id", using: :btree
  add_index "account_book_types", ["user_id_mongo_id"], name: "user_id_mongo_id", using: :btree

  create_table "account_number_rules", force: :cascade do |t|
    t.string   "mongo_id",                 limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",                     limit: 255
    t.string   "rule_type",                limit: 255
    t.string   "rule_target",              limit: 255,   default: "both"
    t.string   "affect",                   limit: 255
    t.text     "content",                  limit: 65535
    t.string   "third_party_account",      limit: 255
    t.integer  "priority",                 limit: 4,     default: 0,      null: false
    t.string   "categorization",           limit: 255
    t.integer  "organization_id",          limit: 4
    t.string   "organization_id_mongo_id", limit: 255
  end

  add_index "account_number_rules", ["mongo_id"], name: "index_account_number_rules_on_mongo_id", using: :btree
  add_index "account_number_rules", ["organization_id"], name: "organization_id", using: :btree
  add_index "account_number_rules", ["organization_id_mongo_id"], name: "organization_id_mongo_id", using: :btree

  create_table "account_number_rules_users", force: :cascade do |t|
    t.integer "user_id",                limit: 4
    t.integer "account_number_rule_id", limit: 4
  end

  create_table "account_sharings", force: :cascade do |t|
    t.integer  "organization_id",  limit: 4
    t.integer  "collaborator_id",  limit: 4
    t.integer  "account_id",       limit: 4
    t.integer  "authorized_by_id", limit: 4
    t.boolean  "is_approved",                default: false
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
  end

  add_index "account_sharings", ["account_id"], name: "index_account_sharings_on_account_id", using: :btree
  add_index "account_sharings", ["authorized_by_id"], name: "index_account_sharings_on_authorized_by_id", using: :btree
  add_index "account_sharings", ["collaborator_id"], name: "index_account_sharings_on_collaborator_id", using: :btree
  add_index "account_sharings", ["is_approved"], name: "index_account_sharings_on_is_approved", using: :btree
  add_index "account_sharings", ["organization_id"], name: "index_account_sharings_on_organization_id", using: :btree

  create_table "accounting_plan_items", force: :cascade do |t|
    t.string   "mongo_id",                             limit: 255
    t.string   "third_party_account",                  limit: 255
    t.string   "third_party_name",                     limit: 255
    t.string   "conterpart_account",                   limit: 255
    t.string   "code",                                 limit: 255
    t.integer  "accounting_plan_itemable_id",          limit: 4
    t.string   "accounting_plan_itemable_type",        limit: 255
    t.string   "accounting_plan_itemable_id_mongo_id", limit: 255
    t.string   "kind",                                 limit: 255
    t.datetime "updated_at"
    t.datetime "created_at"
    t.boolean  "is_updated",                                       default: true
  end

  add_index "accounting_plan_items", ["accounting_plan_itemable_id"], name: "accounting_plan_itemable_id", using: :btree
  add_index "accounting_plan_items", ["accounting_plan_itemable_id_mongo_id"], name: "accounting_plan_itemable_id_mongo_id", using: :btree
  add_index "accounting_plan_items", ["accounting_plan_itemable_type"], name: "accounting_plan_itemable_type", using: :btree
  add_index "accounting_plan_items", ["is_updated"], name: "index_accounting_plan_items_on_is_updated", using: :btree
  add_index "accounting_plan_items", ["mongo_id"], name: "index_accounting_plan_items_on_mongo_id", using: :btree

  create_table "accounting_plan_vat_accounts", force: :cascade do |t|
    t.string  "mongo_id",                    limit: 255
    t.string  "code",                        limit: 255
    t.string  "nature",                      limit: 255
    t.string  "account_number",              limit: 255
    t.integer "accounting_plan_id",          limit: 4
    t.string  "accounting_plan_id_mongo_id", limit: 255
  end

  add_index "accounting_plan_vat_accounts", ["accounting_plan_id"], name: "accounting_plan_id", using: :btree
  add_index "accounting_plan_vat_accounts", ["accounting_plan_id_mongo_id"], name: "accounting_plan_id_mongo_id", using: :btree
  add_index "accounting_plan_vat_accounts", ["mongo_id"], name: "index_accounting_plan_vat_accounts_on_mongo_id", using: :btree

  create_table "accounting_plans", force: :cascade do |t|
    t.string   "mongo_id",         limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "last_checked_at"
    t.integer  "user_id",          limit: 4
    t.string   "user_id_mongo_id", limit: 255
    t.boolean  "is_updating",                  default: false
  end

  add_index "accounting_plans", ["mongo_id"], name: "index_accounting_plans_on_mongo_id", using: :btree
  add_index "accounting_plans", ["user_id"], name: "user_id", using: :btree
  add_index "accounting_plans", ["user_id_mongo_id"], name: "user_id_mongo_id", using: :btree

  create_table "addresses", force: :cascade do |t|
    t.string   "mongo_id",                   limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "first_name",                 limit: 255
    t.string   "last_name",                  limit: 255
    t.string   "email",                      limit: 255
    t.string   "company",                    limit: 255
    t.string   "company_number",             limit: 255
    t.string   "address_1",                  limit: 255
    t.string   "address_2",                  limit: 255
    t.string   "city",                       limit: 255
    t.string   "zip",                        limit: 255
    t.string   "state",                      limit: 255
    t.string   "country",                    limit: 255
    t.string   "building",                   limit: 255
    t.string   "place_called_or_postal_box", limit: 255
    t.string   "door_code",                  limit: 255
    t.string   "other",                      limit: 255
    t.string   "phone",                      limit: 255
    t.string   "phone_mobile",               limit: 255
    t.boolean  "is_for_billing",                         default: false, null: false
    t.boolean  "is_for_paper_return",                    default: false, null: false
    t.boolean  "is_for_paper_set_shipping",              default: false, null: false
    t.boolean  "is_for_dematbox_shipping",               default: false, null: false
    t.integer  "locatable_id",               limit: 4
    t.string   "locatable_type",             limit: 255
    t.string   "locatable_id_mongo_id",      limit: 255
  end

  add_index "addresses", ["locatable_id"], name: "locatable_id", using: :btree
  add_index "addresses", ["locatable_id_mongo_id"], name: "locatable_id_mongo_id", using: :btree
  add_index "addresses", ["locatable_type"], name: "locatable_type", using: :btree
  add_index "addresses", ["mongo_id"], name: "index_addresses_on_mongo_id", using: :btree

  create_table "advanced_preseizures", force: :cascade do |t|
    t.integer  "user_id",           limit: 4
    t.integer  "organization_id",   limit: 4
    t.integer  "report_id",         limit: 4
    t.integer  "piece_id",          limit: 4
    t.integer  "pack_id",           limit: 4
    t.integer  "operation_id",      limit: 4
    t.integer  "position",          limit: 4
    t.datetime "date"
    t.datetime "deadline_date"
    t.datetime "delivery_tried_at"
    t.text     "delivery_message",  limit: 65535
    t.string   "name",              limit: 255
    t.string   "piece_number",      limit: 255
    t.string   "third_party",       limit: 255
    t.decimal  "cached_amount",                   precision: 11, scale: 2
    t.string   "delivery_state",    limit: 20
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "checked_at"
  end

  add_index "advanced_preseizures", ["checked_at"], name: "index_advanced_preseizures_on_checked_at", using: :btree
  add_index "advanced_preseizures", ["delivery_state"], name: "index_advanced_preseizures_on_delivery_state", using: :btree
  add_index "advanced_preseizures", ["name"], name: "index_advanced_preseizures_on_name", using: :btree
  add_index "advanced_preseizures", ["position"], name: "index_advanced_preseizures_on_position", using: :btree
  add_index "advanced_preseizures", ["third_party"], name: "index_advanced_preseizures_on_third_party", using: :btree
  add_index "advanced_preseizures", ["updated_at"], name: "index_advanced_preseizures_on_updated_at", using: :btree

  create_table "analytic_references", force: :cascade do |t|
    t.string  "a1_name",        limit: 255
    t.text    "a1_references",  limit: 65535
    t.decimal "a1_ventilation",               precision: 5, scale: 2, default: 0.0
    t.string  "a1_axis1",       limit: 255
    t.string  "a1_axis2",       limit: 255
    t.string  "a1_axis3",       limit: 255
    t.string  "a2_name",        limit: 255
    t.text    "a2_references",  limit: 65535
    t.decimal "a2_ventilation",               precision: 5, scale: 2, default: 0.0
    t.string  "a2_axis1",       limit: 255
    t.string  "a2_axis2",       limit: 255
    t.string  "a2_axis3",       limit: 255
    t.string  "a3_name",        limit: 255
    t.text    "a3_references",  limit: 65535
    t.decimal "a3_ventilation",               precision: 5, scale: 2, default: 0.0
    t.string  "a3_axis1",       limit: 255
    t.string  "a3_axis2",       limit: 255
    t.string  "a3_axis3",       limit: 255
  end

  create_table "ar_internal_metadata", primary_key: "key", force: :cascade do |t|
    t.string   "value",      limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "audits", force: :cascade do |t|
    t.integer  "auditable_id",    limit: 4
    t.string   "auditable_type",  limit: 255
    t.integer  "associated_id",   limit: 4
    t.string   "associated_type", limit: 255
    t.integer  "user_id",         limit: 4
    t.string   "user_type",       limit: 255
    t.string   "username",        limit: 255
    t.string   "action",          limit: 255
    t.text     "audited_changes", limit: 65535
    t.integer  "version",         limit: 4,     default: 0
    t.string   "comment",         limit: 255
    t.string   "remote_address",  limit: 255
    t.string   "request_uuid",    limit: 255
    t.datetime "created_at"
  end

  add_index "audits", ["associated_id", "associated_type"], name: "associated_index", using: :btree
  add_index "audits", ["auditable_id", "auditable_type"], name: "auditable_index", using: :btree
  add_index "audits", ["created_at"], name: "index_audits_on_created_at", using: :btree
  add_index "audits", ["request_uuid"], name: "index_audits_on_request_uuid", using: :btree
  add_index "audits", ["user_id", "user_type"], name: "user_index", using: :btree

  create_table "bank_accounts", force: :cascade do |t|
    t.string   "mongo_id",              limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "bank_name",             limit: 255
    t.string   "name",                  limit: 255
    t.string   "number",                limit: 255
    t.string   "journal",               limit: 255
    t.string   "currency",              limit: 5,     default: "EUR"
    t.text     "original_currency",     limit: 65535
    t.string   "foreign_journal",       limit: 255
    t.string   "accounting_number",     limit: 255,   default: "512000", null: false
    t.string   "temporary_account",     limit: 255,   default: "471000", null: false
    t.date     "start_date"
    t.integer  "user_id",               limit: 4
    t.string   "user_id_mongo_id",      limit: 255
    t.integer  "retriever_id",          limit: 4
    t.string   "retriever_id_mongo_id", limit: 255
    t.string   "api_id",                limit: 255
    t.string   "api_name",              limit: 255,   default: "budgea"
    t.boolean  "is_used",                             default: false
    t.string   "type_name",             limit: 255
    t.boolean  "lock_old_operation",                  default: true
    t.integer  "permitted_late_days",   limit: 4,     default: 7
  end

  add_index "bank_accounts", ["mongo_id"], name: "index_bank_accounts_on_mongo_id", using: :btree
  add_index "bank_accounts", ["retriever_id"], name: "retriever_id", using: :btree
  add_index "bank_accounts", ["retriever_id_mongo_id"], name: "retriever_id_mongo_id", using: :btree
  add_index "bank_accounts", ["user_id"], name: "user_id", using: :btree
  add_index "bank_accounts", ["user_id_mongo_id"], name: "user_id_mongo_id", using: :btree

  create_table "boxes", force: :cascade do |t|
    t.string   "mongo_id",                          limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "path",                              limit: 255, default: "iDocus/:code/:year:month/:account_book", null: false
    t.boolean  "is_configured",                                 default: false,                                    null: false
    t.integer  "external_file_storage_id",          limit: 4
    t.string   "external_file_storage_id_mongo_id", limit: 255
    t.string   "encrypted_access_token",            limit: 255
    t.string   "encrypted_refresh_token",           limit: 255
  end

  add_index "boxes", ["external_file_storage_id"], name: "external_file_storage_id", using: :btree
  add_index "boxes", ["external_file_storage_id_mongo_id"], name: "external_file_storage_id_mongo_id", using: :btree
  add_index "boxes", ["mongo_id"], name: "index_boxes_on_mongo_id", using: :btree

  create_table "budgea_accounts", force: :cascade do |t|
    t.string   "identifier",             limit: 255
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.integer  "user_id",                limit: 4
    t.string   "encrypted_access_token", limit: 255
  end

  add_index "budgea_accounts", ["user_id"], name: "fk_rails_bc19f24997", using: :btree

  create_table "ckeditor_assets", force: :cascade do |t|
    t.string   "data_file_name",    limit: 255, null: false
    t.string   "data_content_type", limit: 255
    t.integer  "data_file_size",    limit: 4
    t.string   "data_fingerprint",  limit: 255
    t.integer  "assetable_id",      limit: 4
    t.string   "assetable_type",    limit: 30
    t.string   "type",              limit: 30
    t.integer  "width",             limit: 4
    t.integer  "height",            limit: 4
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
  end

  add_index "ckeditor_assets", ["assetable_type", "assetable_id"], name: "idx_ckeditor_assetable", using: :btree
  add_index "ckeditor_assets", ["assetable_type", "type", "assetable_id"], name: "idx_ckeditor_assetable_type", using: :btree

  create_table "cms_images", force: :cascade do |t|
    t.string   "mongo_id",                   limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "original_file_name",         limit: 255
    t.string   "content_file_name",          limit: 255
    t.string   "content_content_type",       limit: 255
    t.integer  "content_file_size",          limit: 4
    t.string   "cloud_content_file_name",    limit: 255
    t.string   "cloud_content_content_type", limit: 255
    t.integer  "cloud_content_file_size",    limit: 4
    t.boolean  "is_sane",                                  default: true
    t.boolean  "is_new_password_needed",                   default: false
    t.boolean  "is_selection_needed",                      default: true
    t.string   "state",                      limit: 255
    t.text     "error_message",              limit: 65535
    t.string   "budgea_state",               limit: 255
    t.text     "budgea_additionnal_fields",  limit: 65535
    t.text     "budgea_error_message",       limit: 65535
    t.string   "fiduceo_state",              limit: 255
    t.text     "fiduceo_additionnal_fields", limit: 65535
    t.string   "fiduceo_error_message",      limit: 255
    t.datetime "created_at",                                               null: false
    t.datetime "updated_at",                                               null: false
    t.integer  "user_id",                    limit: 4
    t.integer  "journal_id",                 limit: 4
    t.string   "service_name",               limit: 255
    t.text     "capabilities",               limit: 65535
    t.text     "encrypted_answers",          limit: 65535
    t.text     "encrypted_param5",           limit: 65535
    t.text     "encrypted_param4",           limit: 65535
    t.text     "encrypted_param3",           limit: 65535
    t.text     "encrypted_param2",           limit: 65535
    t.text     "encrypted_param1",           limit: 65535
    t.integer  "connector_id",               limit: 4
    t.string   "fiduceo_error_message",      limit: 255
    t.text     "fiduceo_additionnal_fields", limit: 65535
    t.string   "fiduceo_state",              limit: 255
    t.text     "budgea_additionnal_fields",  limit: 65535
    t.text     "additionnal_fields",         limit: 65535
    t.string   "fiduceo_transaction_id",     limit: 255
    t.string   "fiduceo_id",                 limit: 255
  end
    t.boolean  "is_sane",                              default: true
    t.boolean  "is_new_password_needed",               default: false
    t.boolean  "is_selection_needed",                  default: true
    t.string   "state",                  limit: 255
    t.string   "error_message",          limit: 255
    t.string   "budgea_state",           limit: 255
    t.string   "budgea_error_message",   limit: 255
    t.datetime "created_at",                                           null: false
    t.datetime "updated_at",                                           null: false
    t.integer  "user_id",                limit: 4
    t.integer  "journal_id",             limit: 4
    t.integer  "budgea_connector_id",    limit: 4
    t.string   "service_name",           limit: 255
    t.text     "capabilities",           limit: 65535
    t.integer  "budgea_connector_id",        limit: 4
    t.string   "service_name",               limit: 255
    t.text     "capabilities",               limit: 65535
    t.text     "encrypted_answers",          limit: 65535
    t.text     "encrypted_param5",           limit: 65535
    t.text     "encrypted_param4",           limit: 65535
    t.text     "encrypted_param3",           limit: 65535
    t.text     "encrypted_param2",           limit: 65535
    t.text     "encrypted_param1",           limit: 65535
    t.integer  "connector_id",               limit: 4
    t.string   "fiduceo_error_message",      limit: 255
    t.text     "fiduceo_additionnal_fields", limit: 65535
    t.string   "fiduceo_state",              limit: 255
    t.text     "budgea_additionnal_fields",  limit: 65535
    t.text     "additionnal_fields",         limit: 65535
    t.string   "fiduceo_transaction_id",     limit: 255
    t.string   "fiduceo_id",                 limit: 255
  end
  add_index "retrievers", ["journal_id"], name: "index_retrievers_on_journal_id", using: :btree
  add_index "retrievers", ["state"], name: "index_retrievers_on_state", using: :btree
  add_index "retrievers", ["user_id"], name: "index_retrievers_on_user_id", using: :btree

  create_table "retrievers_historics", force: :cascade do |t|
    t.integer "user_id",          limit: 4
    t.integer "connector_id",     limit: 4
    t.integer "retriever_id",     limit: 4
    t.string  "name",             limit: 255
    t.string  "service_name",     limit: 255
    t.integer "banks_count",      limit: 4,     default: 0
    t.integer "operations_count", limit: 4,     default: 0
    t.text    "capabilities",     limit: 65535
  end

  add_index "retrievers_historics", ["service_name"], name: "index_retrievers_historics_on_service_name", using: :btree

  create_table "sandbox_bank_accounts", force: :cascade do |t|
    t.string   "api_id",            limit: 255
    t.string   "api_name",          limit: 255, default: "budgea"
    t.string   "bank_name",         limit: 255
    t.string   "name",              limit: 255
    t.string   "number",            limit: 255
    t.boolean  "is_used",                       default: false
    t.string   "journal",           limit: 255
    t.string   "foreign_journal",   limit: 255
    t.string   "accounting_number", limit: 255, default: "512000"
    t.string   "temporary_account", limit: 255, default: "471000"
    t.date     "start_date"
    t.datetime "created_at",                                       null: false
    t.datetime "updated_at",                                       null: false
    t.integer  "user_id",           limit: 4
    t.integer  "retriever_id",      limit: 4
    t.string   "type_name",         limit: 255
  end

  add_index "sandbox_bank_accounts", ["retriever_id"], name: "index_sandbox_bank_accounts_on_retriever_id", using: :btree
  add_index "sandbox_bank_accounts", ["user_id"], name: "index_sandbox_bank_accounts_on_user_id", using: :btree

  create_table "sandbox_documents", force: :cascade do |t|
    t.string   "api_id",               limit: 255
    t.string   "api_name",             limit: 255,   default: "budgea"
    t.text     "retrieved_metadata",   limit: 65535
    t.datetime "created_at",                                            null: false
    t.datetime "updated_at",                                            null: false
    t.integer  "user_id",              limit: 4
    t.integer  "retriever_id",         limit: 4
    t.string   "content_file_name",    limit: 255
    t.string   "content_content_type", limit: 255
    t.integer  "content_file_size",    limit: 4
    t.boolean "is_sane", default: true
    t.boolean "is_new_password_needed", default: false
    t.boolean "is_selection_needed", default: true
    t.string "state"
    t.string "error_message"
    t.string "budgea_state"
    t.text "budgea_error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.integer "journal_id"
    t.integer "budgea_connector_id"
    t.string "service_name"
    t.text "capabilities"
    t.index ["journal_id"], name: "index_retrievers_on_journal_id"
    t.index ["state"], name: "index_retrievers_on_state"
    t.index ["user_id"], name: "index_retrievers_on_user_id"
  end

  create_table "retrievers_historics", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
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
    t.string   "content_fingerprint",  limit: 255
  end

  add_index "sandbox_documents", ["api_id"], name: "index_sandbox_documents_on_api_id", using: :btree
  add_index "sandbox_documents", ["api_name"], name: "index_sandbox_documents_on_api_name", using: :btree
  add_index "sandbox_documents", ["retriever_id"], name: "index_sandbox_documents_on_retriever_id", using: :btree
  add_index "sandbox_documents", ["user_id"], name: "index_sandbox_documents_on_user_id", using: :btree

  create_table "sandbox_operations", force: :cascade do |t|
    t.string   "api_id",                  limit: 255
    t.string   "api_name",                limit: 255,                default: "budgea"
    t.date     "date"
    t.date     "value_date"
    t.date     "transaction_date"
    t.string   "label",                   limit: 255
    t.decimal  "amount",                              precision: 10
    t.string   "comment",                 limit: 255
    t.string   "supplier_found",          limit: 255
    t.string   "type_name",               limit: 255
    t.integer  "category_id",             limit: 4
    t.string   "category",                limit: 255
    t.boolean  "is_locked"
    t.datetime "created_at",                                                            null: false
    t.datetime "updated_at",                                                            null: false
    t.integer  "organization_id",         limit: 4
    t.integer  "user_id",                 limit: 4
    t.integer  "sandbox_bank_account_id", limit: 4
  end

  add_index "sandbox_operations", ["api_id"], name: "index_sandbox_operations_on_api_id", using: :btree
  add_index "sandbox_operations", ["api_name"], name: "index_sandbox_operations_on_api_name", using: :btree
  add_index "sandbox_operations", ["organization_id"], name: "index_sandbox_operations_on_organization_id", using: :btree

  create_table "scanning_providers", force: :cascade do |t|
    t.string   "mongo_id",   limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",       limit: 255
    t.string   "code",       limit: 255
    t.boolean  "is_default",             default: false, null: false
  end

  add_index "scanning_providers", ["mongo_id"], name: "index_scanning_providers_on_mongo_id", using: :btree

  create_table "settings", force: :cascade do |t|
    t.string "mongo_id",                            limit: 255
    t.text   "key",                                 limit: 65535
    t.text   "is_journals_modification_authorized", limit: 65535
    t.text   "notify_errors_to",                    limit: 65535
    t.text   "notify_ibiza_deliveries_to",          limit: 65535
    t.text   "notify_on_ibiza_delivery",            limit: 65535
    t.text   "notify_scans_not_delivered_to",       limit: 65535
    t.text   "notify_dematbox_order_to",            limit: 65535
    t.text   "notify_paper_set_order_to",           limit: 65535
    t.text   "micro_package_authorized_to",         limit: 65535
    t.text   "paper_process_operators",             limit: 65535
    t.text   "compta_operators",                    limit: 65535
    t.text   "default_url",                         limit: 65535
    t.text   "inner_url",                           limit: 65535
    t.text   "notify_mcf_errors_to",                limit: 65535
  end

  add_index "settings", ["mongo_id"], name: "index_mongoid_app_settings_records_on_mongo_id", using: :btree

  create_table "softwares_settings", force: :cascade do |t|
    t.integer "user_id",                            limit: 4
    t.boolean "is_ibiza_used",                                default: false
    t.integer "is_ibiza_auto_deliver",              limit: 4, default: -1,    null: false
    t.integer "is_ibiza_compta_analysis_activated", limit: 4, default: -1,    null: false
    t.integer "is_ibiza_analysis_to_validate",      limit: 4, default: -1,    null: false
    t.boolean "is_coala_used",                                default: false
    t.integer "is_coala_auto_deliver",              limit: 4, default: -1,    null: false
    t.boolean "is_quadratus_used",                            default: false
    t.integer "is_quadratus_auto_deliver",          limit: 4, default: -1,    null: false
    t.boolean "is_csv_descriptor_used",                       default: false
    t.boolean "use_own_csv_descriptor_format",                default: false
    t.integer "is_csv_descriptor_auto_deliver",     limit: 4, default: -1,    null: false
    t.boolean "is_exact_online_used",                         default: false
    t.integer "is_exact_online_auto_deliver",       limit: 4, default: -1,    null: false
    t.boolean "is_cegid_used",                                default: false
    t.integer "is_cegid_auto_deliver",              limit: 4, default: -1,    null: false
  end

  add_index "softwares_settings", ["is_cegid_used"], name: "index_softwares_settings_on_is_cegid_used", using: :btree
  add_index "softwares_settings", ["is_coala_used"], name: "index_softwares_settings_on_is_coala_used", using: :btree
  add_index "softwares_settings", ["is_csv_descriptor_used"], name: "index_softwares_settings_on_is_csv_descriptor_used", using: :btree
  add_index "softwares_settings", ["is_exact_online_used"], name: "index_softwares_settings_on_is_exact_online_used", using: :btree
  add_index "softwares_settings", ["is_ibiza_used"], name: "index_softwares_settings_on_is_ibiza_used", using: :btree
  add_index "softwares_settings", ["is_quadratus_used"], name: "index_softwares_settings_on_is_quadratus_used", using: :btree
  add_index "softwares_settings", ["user_id"], name: "index_softwares_settings_on_user_id", using: :btree

  create_table "statistics", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "information", limit: 255
    t.float    "counter",     limit: 53
  end

  create_table "subscription_options", force: :cascade do |t|
    t.string   "mongo_id",              limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",                  limit: 255
    t.integer  "price_in_cents_wo_vat", limit: 4,   default: 0, null: false
    t.integer  "position",              limit: 4,   default: 1, null: false
    t.integer  "period_duration",       limit: 4,   default: 1, null: false
  end

  add_index "subscription_options", ["mongo_id"], name: "index_subscription_options_on_mongo_id", using: :btree

  create_table "subscription_options_subscriptions", force: :cascade do |t|
    t.integer "subscription_id",        limit: 4
    t.integer "subscription_option_id", limit: 4
  end

  create_table "subscription_statistics", force: :cascade do |t|
    t.date     "month"
    t.integer  "organization_id",   limit: 4
    t.string   "organization_code", limit: 255
    t.string   "organization_name", limit: 255
    t.text     "options",           limit: 65535
    t.text     "consumption",       limit: 65535
    t.text     "customers",         limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "subscription_statistics", ["month"], name: "index_subscription_statistics_on_month", using: :btree
  add_index "subscription_statistics", ["organization_code"], name: "index_subscription_statistics_on_organization_code", using: :btree

  create_table "subscriptions", force: :cascade do |t|
    t.string   "mongo_id",                            limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "period_duration",                     limit: 4,   default: 1,     null: false
    t.float    "tva_ratio",                           limit: 24,  default: 1.2,   null: false
    t.boolean  "is_micro_package_active",                         default: false, null: false
    t.boolean  "is_mini_package_active",                          default: false, null: false
    t.boolean  "is_basic_package_active",                         default: false, null: false
    t.boolean  "is_mail_package_active",                          default: false, null: false
    t.boolean  "is_scan_box_package_active",                      default: false, null: false
    t.boolean  "is_retriever_package_active",                     default: false, null: false
    t.boolean  "is_annual_package_active",                        default: false, null: false
    t.integer  "number_of_journals",                  limit: 4,   default: 5,     null: false
    t.boolean  "is_pre_assignment_active",                        default: true,  null: false
    t.boolean  "is_stamp_active",                                 default: false, null: false
    t.boolean  "is_micro_package_to_be_disabled"
    t.boolean  "is_mini_package_to_be_disabled"
    t.boolean  "is_basic_package_to_be_disabled"
    t.boolean  "is_mail_package_to_be_disabled"
    t.boolean  "is_scan_box_package_to_be_disabled"
    t.boolean  "is_retriever_package_to_be_disabled"
    t.boolean  "is_pre_assignment_to_be_disabled"
    t.boolean  "is_stamp_to_be_disabled"
    t.date     "start_date"
    t.date     "end_date"
    t.integer  "max_sheets_authorized",               limit: 4,   default: 100,   null: false
    t.integer  "max_upload_pages_authorized",         limit: 4,   default: 200,   null: false
    t.integer  "max_dematbox_scan_pages_authorized",  limit: 4,   default: 200,   null: false
    t.integer  "max_preseizure_pieces_authorized",    limit: 4,   default: 100,   null: false
    t.integer  "max_expense_pieces_authorized",       limit: 4,   default: 100,   null: false
    t.integer  "max_paperclips_authorized",           limit: 4,   default: 0,     null: false
    t.integer  "max_oversized_authorized",            limit: 4,   default: 0,     null: false
    t.integer  "unit_price_of_excess_sheet",          limit: 4,   default: 12,    null: false
    t.integer  "unit_price_of_excess_upload",         limit: 4,   default: 6,     null: false
    t.integer  "unit_price_of_excess_dematbox_scan",  limit: 4,   default: 6,     null: false
    t.integer  "unit_price_of_excess_preseizure",     limit: 4,   default: 12,    null: false
    t.integer  "unit_price_of_excess_expense",        limit: 4,   default: 12,    null: false
    t.integer  "unit_price_of_excess_paperclips",     limit: 4,   default: 20,    null: false
    t.integer  "unit_price_of_excess_oversized",      limit: 4,   default: 100,   null: false
    t.integer  "user_id",                             limit: 4
    t.string   "user_id_mongo_id",                    limit: 255
    t.integer  "organization_id",                     limit: 4
    t.string   "organization_id_mongo_id",            limit: 255
  end

  add_index "subscriptions", ["mongo_id"], name: "index_subscriptions_on_mongo_id", using: :btree
  add_index "subscriptions", ["organization_id"], name: "organization_id", using: :btree
  add_index "subscriptions", ["organization_id_mongo_id"], name: "organization_id_mongo_id", using: :btree
  add_index "subscriptions", ["user_id"], name: "user_id", using: :btree
  add_index "subscriptions", ["user_id_mongo_id"], name: "user_id_mongo_id", using: :btree

  create_table "temp_document_metadata", force: :cascade do |t|
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
    t.string "mongo_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "name"
    t.string "code"
    t.boolean "is_default", default: false, null: false
    t.index ["mongo_id"], name: "index_scanning_providers_on_mongo_id"
  end

  create_table "settings", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "mongo_id"
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
    t.index ["mongo_id"], name: "index_mongoid_app_settings_records_on_mongo_id"
  end

  create_table "softwares_settings", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "user_id"
    t.boolean "is_ibiza_used", default: false
    t.integer "is_ibiza_auto_deliver", default: -1, null: false
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
    t.index ["is_coala_used"], name: "index_softwares_settings_on_is_coala_used"
    t.index ["is_csv_descriptor_used"], name: "index_softwares_settings_on_is_csv_descriptor_used"
    t.index ["is_exact_online_used"], name: "index_softwares_settings_on_is_exact_online_used"
    t.index ["is_ibiza_used"], name: "index_softwares_settings_on_is_ibiza_used"
    t.index ["is_quadratus_used"], name: "index_softwares_settings_on_is_quadratus_used"
    t.index ["user_id"], name: "index_softwares_settings_on_user_id"
  end

  create_table "softwares_settings_backup", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.integer "user_id"
    t.boolean "is_ibiza_used", default: false
    t.integer "is_ibiza_auto_deliver", default: -1, null: false
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
    t.index ["is_coala_used"], name: "index_softwares_settings_on_is_coala_used"
    t.index ["is_csv_descriptor_used"], name: "index_softwares_settings_on_is_csv_descriptor_used"
    t.index ["is_exact_online_used"], name: "index_softwares_settings_on_is_exact_online_used"
    t.index ["is_ibiza_used"], name: "index_softwares_settings_on_is_ibiza_used"
    t.index ["is_quadratus_used"], name: "index_softwares_settings_on_is_quadratus_used"
  end

  create_table "statistics", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "information"
    t.float "counter", limit: 53
  end

  create_table "subscription_options", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "mongo_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "name"
    t.integer "price_in_cents_wo_vat", default: 0, null: false
    t.integer "position", default: 1, null: false
    t.integer "period_duration", default: 1, null: false
    t.index ["mongo_id"], name: "index_subscription_options_on_mongo_id"
  end

  create_table "subscription_options_subscriptions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "subscription_id"
    t.integer "subscription_option_id"
  end

  create_table "subscription_statistics", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
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
    t.string "mongo_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "period_duration", default: 1, null: false
    t.float "tva_ratio", default: 1.2, null: false
    t.boolean "is_micro_package_active", default: false, null: false
    t.boolean "is_mini_package_active", default: false, null: false
    t.boolean "is_basic_package_active", default: false, null: false
    t.boolean "is_mail_package_active", default: false, null: false
    t.boolean "is_scan_box_package_active", default: false, null: false
    t.boolean "is_retriever_package_active", default: false, null: false
    t.boolean "is_annual_package_active", default: false, null: false
    t.integer "number_of_journals", default: 5, null: false
    t.boolean "is_pre_assignment_active", default: true, null: false
    t.boolean "is_stamp_active", default: false, null: false
    t.boolean "is_micro_package_to_be_disabled"
    t.boolean "is_mini_package_to_be_disabled"
    t.boolean "is_basic_package_to_be_disabled"
    t.boolean "is_mail_package_to_be_disabled"
    t.boolean "is_scan_box_package_to_be_disabled"
    t.boolean "is_retriever_package_to_be_disabled"
    t.boolean "is_pre_assignment_to_be_disabled"
    t.boolean "is_stamp_to_be_disabled"
    t.date "start_date"
    t.date "end_date"
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
    t.string "user_id_mongo_id"
    t.integer "organization_id"
    t.string "organization_id_mongo_id"
    t.index ["mongo_id"], name: "index_subscriptions_on_mongo_id"
    t.index ["organization_id"], name: "organization_id"
    t.index ["organization_id_mongo_id"], name: "organization_id_mongo_id"
    t.index ["user_id"], name: "user_id"
    t.index ["user_id_mongo_id"], name: "user_id_mongo_id"
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
    t.datetime "stated_at"
    t.boolean "is_locked", default: false, null: false
    t.text "scan_bundling_document_ids"
    t.string "content_file_name"
    t.string "content_content_type"
    t.integer "content_file_size"
    t.datetime "content_updated_at"
    t.string "content_fingerprint"
    t.string "original_fingerprint"
    t.string "cloud_content_file_name"
    t.string "cloud_content_content_type"
    t.integer "cloud_content_file_size"
    t.datetime "cloud_content_updated_at"
    t.string "cloud_content_fingerprint"
    t.string "raw_content_file_name"
    t.string "raw_content_content_type"
    t.integer "raw_content_file_size"
    t.datetime "raw_content_updated_at"
    t.string "raw_content_fingerprint"
    t.string "cloud_raw_content_file_name"
    t.string "cloud_raw_content_content_type"
    t.integer "cloud_raw_content_file_size"
    t.datetime "cloud_raw_content_updated_at"
    t.string "cloud_raw_content_fingerprint"
    t.integer "organization_id"
    t.string "organization_id_mongo_id"
    t.integer "user_id"
    t.string "user_id_mongo_id"
    t.integer "temp_pack_id"
    t.string "temp_pack_id_mongo_id"
    t.integer "document_delivery_id"
    t.string "document_delivery_id_mongo_id"
    t.integer "fiduceo_retriever_id"
    t.string "fiduceo_retriever_id_mongo_id"
    t.integer "email_id"
    t.string "email_id_mongo_id"
    t.integer "piece_id"
    t.string "piece_id_mongo_id"
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
    t.index ["document_delivery_id_mongo_id"], name: "document_delivery_id_mongo_id"
    t.index ["email_id"], name: "email_id"
    t.index ["email_id_mongo_id"], name: "email_id_mongo_id"
    t.index ["fiduceo_retriever_id"], name: "fiduceo_retriever_id"
    t.index ["fiduceo_retriever_id_mongo_id"], name: "fiduceo_retriever_id_mongo_id"
    t.index ["ibizabox_folder_id"], name: "index_temp_documents_on_ibizabox_folder_id"
    t.index ["is_an_original"], name: "index_temp_documents_on_is_an_original"
    t.index ["mongo_id"], name: "index_temp_documents_on_mongo_id"
    t.index ["organization_id"], name: "organization_id"
    t.index ["organization_id_mongo_id"], name: "organization_id_mongo_id"
    t.index ["piece_id"], name: "piece_id"
    t.index ["piece_id_mongo_id"], name: "piece_id_mongo_id"
    t.index ["retriever_id"], name: "index_temp_documents_on_retriever_id"
    t.index ["state"], name: "index_temp_documents_on_state"
    t.index ["temp_pack_id"], name: "temp_pack_id"
    t.index ["temp_pack_id_mongo_id"], name: "temp_pack_id_mongo_id"
    t.index ["user_id"], name: "index_temp_documents_on_user_id"
    t.index ["user_id"], name: "user_id"
    t.index ["user_id_mongo_id"], name: "user_id_mongo_id"
  end

  create_table "temp_packs", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "mongo_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "locked_at"
    t.datetime "locked_until"
    t.string "name"
    t.integer "position_counter", default: 0, null: false
    t.integer "document_not_processed_count", default: 0, null: false
    t.integer "document_bundling_count", default: 0, null: false
    t.integer "document_bundle_needed_count", default: 0, null: false
    t.integer "organization_id"
    t.string "organization_id_mongo_id"
    t.integer "user_id"
    t.string "user_id_mongo_id"
    t.integer "document_delivery_id"
    t.string "document_delivery_id_mongo_id"
    t.index ["document_delivery_id"], name: "document_delivery_id"
    t.index ["document_delivery_id_mongo_id"], name: "document_delivery_id_mongo_id"
    t.index ["mongo_id"], name: "index_temp_packs_on_mongo_id"
    t.index ["organization_id"], name: "organization_id"
    t.index ["organization_id_mongo_id"], name: "organization_id_mongo_id"
    t.index ["user_id"], name: "user_id"
    t.index ["user_id_mongo_id"], name: "user_id_mongo_id"
  end

  create_table "user_options", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "mongo_id"
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
    t.string "user_id_mongo_id"
    t.boolean "is_retriever_authorized", default: false
    t.integer "is_operation_processing_forced", default: -1, null: false
    t.integer "is_operation_value_date_needed", default: -1, null: false
    t.integer "preseizure_date_option", default: -1
    t.string "dashboard_default_summary", default: "last_scans"
    t.integer "is_compta_analysis_activated", default: -1
    t.index ["mongo_id"], name: "index_user_options_on_mongo_id"
    t.index ["user_id"], name: "user_id"
    t.index ["user_id_mongo_id"], name: "user_id_mongo_id"
  end

  create_table "users", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "mongo_id"
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
    t.boolean "organization_rights_is_customers_management_authorized", default: true, null: false
    t.boolean "organization_rights_is_journals_management_authorized", default: true, null: false
    t.boolean "organization_rights_is_customer_journals_management_authorized", default: true, null: false
    t.integer "organization_id"
    t.string "organization_id_mongo_id"
    t.integer "parent_id"
    t.string "parent_id_mongo_id"
    t.integer "scanning_provider_id"
    t.string "scanning_provider_id_mongo_id"
    t.string "fiduceo_id"
    t.text "group_ids"
    t.boolean "is_guest", default: false
    t.datetime "news_read_at"
    t.string "mcf_storage"
    t.integer "manager_id"
    t.index ["manager_id"], name: "index_users_on_manager_id"
    t.index ["mongo_id"], name: "index_users_on_mongo_id"
    t.index ["organization_id"], name: "organization_id"
    t.index ["organization_id_mongo_id"], name: "organization_id_mongo_id"
    t.index ["parent_id"], name: "parent_id"
    t.index ["parent_id_mongo_id"], name: "parent_id_mongo_id"
    t.index ["scanning_provider_id"], name: "scanning_provider_id"
    t.index ["scanning_provider_id_mongo_id"], name: "scanning_provider_id_mongo_id"
  end

  add_foreign_key "budgea_accounts", "users"
  add_foreign_key "debit_mandates", "organizations"
  add_foreign_key "notifications", "users"
  add_foreign_key "retrieved_data", "users"
end
