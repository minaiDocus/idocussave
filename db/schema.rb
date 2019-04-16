# encoding: UTF-8
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


ActiveRecord::Schema.define(version: 20190415064821) do
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
    t.string  "mongo_id",                             limit: 255
    t.string  "third_party_account",                  limit: 255
    t.string  "third_party_name",                     limit: 255
    t.string  "conterpart_account",                   limit: 255
    t.string  "code",                                 limit: 255
    t.integer "accounting_plan_itemable_id",          limit: 4
    t.string  "accounting_plan_itemable_type",        limit: 255
    t.string  "accounting_plan_itemable_id_mongo_id", limit: 255
    t.string  "kind",                                 limit: 255
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
    t.integer  "permitted_late_days",   limit: 4,     default: 30
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
    t.datetime "content_updated_at"
    t.string   "content_fingerprint",        limit: 255
  end

  add_index "cms_images", ["mongo_id"], name: "index_cms_images_on_mongo_id", using: :btree

  create_table "compositions", force: :cascade do |t|
    t.string   "mongo_id",         limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",             limit: 255
    t.string   "path",             limit: 255
    t.text     "document_ids",     limit: 65535
    t.integer  "user_id",          limit: 4
    t.string   "user_id_mongo_id", limit: 255
  end

  add_index "compositions", ["mongo_id"], name: "index_compositions_on_mongo_id", using: :btree
  add_index "compositions", ["user_id"], name: "user_id", using: :btree
  add_index "compositions", ["user_id_mongo_id"], name: "user_id_mongo_id", using: :btree

  create_table "connectors", force: :cascade do |t|
    t.string   "name",            limit: 255
    t.text     "capabilities",    limit: 65535
    t.text     "apis",            limit: 65535
    t.text     "active_apis",     limit: 65535
    t.integer  "budgea_id",       limit: 4
    t.string   "fiduceo_ref",     limit: 255
    t.text     "combined_fields", limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "urls",            limit: 65535
  end

  create_table "csv_descriptors", force: :cascade do |t|
    t.string   "mongo_id",                  limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "comma_as_number_separator",               default: false, null: false
    t.text     "directive",                 limit: 65535
    t.integer  "organization_id",           limit: 4
    t.string   "organization_id_mongo_id",  limit: 255
    t.integer  "user_id",                   limit: 4
    t.string   "user_id_mongo_id",          limit: 255
  end

  add_index "csv_descriptors", ["mongo_id"], name: "index_csv_descriptors_on_mongo_id", using: :btree
  add_index "csv_descriptors", ["organization_id"], name: "organization_id", using: :btree
  add_index "csv_descriptors", ["organization_id_mongo_id"], name: "organization_id_mongo_id", using: :btree
  add_index "csv_descriptors", ["user_id"], name: "user_id", using: :btree
  add_index "csv_descriptors", ["user_id_mongo_id"], name: "user_id_mongo_id", using: :btree

  create_table "currency_rates", force: :cascade do |t|
    t.datetime "date"
    t.string   "exchange_from",         limit: 5
    t.string   "exchange_to",           limit: 5
    t.string   "currency_name",         limit: 255
    t.float    "exchange_rate",         limit: 24
    t.float    "reverse_exchange_rate", limit: 24
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "currency_rates", ["date", "exchange_from", "exchange_to"], name: "index_exchange_name_date", using: :btree

  create_table "dba_sequences", force: :cascade do |t|
    t.string   "mongo_id",     limit: 255
    t.datetime "locked_at"
    t.datetime "locked_until"
    t.string   "name",         limit: 255
    t.integer  "counter",      limit: 4,   default: 1, null: false
  end

  add_index "dba_sequences", ["mongo_id"], name: "index_dba_sequences_on_mongo_id", using: :btree

  create_table "debit_mandates", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "transactionId",            limit: 255
    t.string   "transactionStatus",        limit: 255
    t.string   "transactionErrorCode",     limit: 255
    t.string   "signatureOperationResult", limit: 255
    t.string   "signatureDate",            limit: 255
    t.string   "mandateScore",             limit: 255
    t.string   "clientReference",          limit: 255
    t.string   "cardTransactionId",        limit: 255
    t.string   "cardRequestId",            limit: 255
    t.string   "cardOperationType",        limit: 255
    t.string   "cardOperationResult",      limit: 255
    t.string   "collectOperationResult",   limit: 255
    t.string   "invoiceReference",         limit: 255
    t.string   "invoiceAmount",            limit: 255
    t.string   "invoiceExecutionDate",     limit: 255
    t.string   "reference",                limit: 255
    t.string   "title",                    limit: 255
    t.string   "firstName",                limit: 255
    t.string   "lastName",                 limit: 255
    t.string   "email",                    limit: 255
    t.string   "bic",                      limit: 255
    t.string   "iban",                     limit: 255
    t.string   "RUM",                      limit: 255
    t.string   "companyName",              limit: 255
    t.string   "organizationId",           limit: 255
    t.string   "invoiceLine1",             limit: 255
    t.string   "invoiceLine2",             limit: 255
    t.string   "invoiceCity",              limit: 255
    t.string   "invoiceCountry",           limit: 255
    t.string   "invoicePostalCode",        limit: 255
    t.string   "deliveryLine1",            limit: 255
    t.string   "deliveryLine2",            limit: 255
    t.string   "deliveryCity",             limit: 255
    t.string   "deliveryCountry",          limit: 255
    t.string   "deliveryPostalCode",       limit: 255
    t.integer  "organization_id",          limit: 4
  end

  add_index "debit_mandates", ["organization_id"], name: "index_debit_mandates_on_organization_id", using: :btree

  create_table "delayed_backend_mongoid_jobs", force: :cascade do |t|
    t.string   "mongo_id",   limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "priority",   limit: 4,   default: 0, null: false
    t.integer  "attempts",   limit: 4,   default: 0, null: false
    t.string   "handler",    limit: 255
    t.datetime "run_at"
    t.datetime "locked_at"
    t.string   "locked_by",  limit: 255
    t.datetime "failed_at"
    t.string   "last_error", limit: 255
    t.string   "queue",      limit: 255
  end

  add_index "delayed_backend_mongoid_jobs", ["mongo_id"], name: "index_delayed_backend_mongoid_jobs_on_mongo_id", using: :btree

  create_table "dematbox", force: :cascade do |t|
    t.string   "mongo_id",                   limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_configured",                          default: false, null: false
    t.datetime "beginning_configuration_at"
    t.integer  "user_id",                    limit: 4
    t.string   "user_id_mongo_id",           limit: 255
  end

  add_index "dematbox", ["mongo_id"], name: "index_dematbox_on_mongo_id", using: :btree
  add_index "dematbox", ["user_id"], name: "user_id", using: :btree
  add_index "dematbox", ["user_id_mongo_id"], name: "user_id_mongo_id", using: :btree

  create_table "dematbox_services", force: :cascade do |t|
    t.string   "mongo_id",   limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",       limit: 255
    t.string   "pid",        limit: 255
    t.string   "type",       limit: 255
    t.string   "state",      limit: 255, default: "unknown", null: false
  end

  add_index "dematbox_services", ["mongo_id"], name: "index_dematbox_services_on_mongo_id", using: :btree

  create_table "dematbox_subscribed_services", force: :cascade do |t|
    t.string   "mongo_id",              limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",                  limit: 255
    t.string   "pid",                   limit: 255
    t.string   "group_name",            limit: 255
    t.string   "group_pid",             limit: 255
    t.boolean  "is_for_current_period",             default: true, null: false
    t.integer  "dematbox_id",           limit: 4
    t.string   "dematbox_id_mongo_id",  limit: 255
  end

  add_index "dematbox_subscribed_services", ["dematbox_id"], name: "dematbox_id", using: :btree
  add_index "dematbox_subscribed_services", ["dematbox_id_mongo_id"], name: "dematbox_id_mongo_id", using: :btree
  add_index "dematbox_subscribed_services", ["mongo_id"], name: "index_dematbox_subscribed_services_on_mongo_id", using: :btree

  create_table "document_deliveries", force: :cascade do |t|
    t.string   "mongo_id",     limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "provider",     limit: 255
    t.date     "date"
    t.boolean  "is_processed"
    t.datetime "processed_at"
    t.integer  "position",     limit: 4,   default: 1
  end

  add_index "document_deliveries", ["mongo_id"], name: "index_document_deliveries_on_mongo_id", using: :btree

  create_table "documents", force: :cascade do |t|
    t.string   "mongo_id",                   limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "content_text",               limit: 4294967295
    t.boolean  "is_a_cover",                                    default: false
    t.string   "origin",                     limit: 255
    t.text     "tags",                       limit: 4294967295
    t.integer  "position",                   limit: 4
    t.boolean  "dirty",                                         default: true,  null: false
    t.string   "token",                      limit: 255
    t.string   "content_file_name",          limit: 255
    t.string   "content_content_type",       limit: 255
    t.integer  "content_file_size",          limit: 4
    t.string   "cloud_content_file_name",    limit: 255
    t.string   "cloud_content_content_type", limit: 255
    t.integer  "cloud_content_file_size",    limit: 4
    t.datetime "content_updated_at"
    t.string   "content_fingerprint",        limit: 255
    t.integer  "pack_id",                    limit: 4
    t.string   "pack_id_mongo_id",           limit: 255
  end

  add_index "documents", ["dirty"], name: "index_documents_on_dirty", using: :btree
  add_index "documents", ["is_a_cover"], name: "index_documents_on_is_a_cover", using: :btree
  add_index "documents", ["mongo_id"], name: "index_documents_on_mongo_id", using: :btree
  add_index "documents", ["origin"], name: "index_documents_on_origin", using: :btree
  add_index "documents", ["pack_id"], name: "pack_id", using: :btree
  add_index "documents", ["pack_id_mongo_id"], name: "pack_id_mongo_id", using: :btree

  create_table "dropbox_basics", force: :cascade do |t|
    t.string   "mongo_id",                          limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "path",                              limit: 255,        default: ":code/:year:month/:account_book/", null: false
    t.integer  "dropbox_id",                        limit: 4
    t.datetime "changed_at"
    t.datetime "checked_at"
    t.text     "delta_cursor",                      limit: 4294967295
    t.string   "delta_path_prefix",                 limit: 255
    t.text     "import_folder_paths",               limit: 4294967295
    t.integer  "external_file_storage_id",          limit: 4
    t.string   "external_file_storage_id_mongo_id", limit: 255
    t.string   "encrypted_access_token",            limit: 255
  end

  add_index "dropbox_basics", ["external_file_storage_id"], name: "external_file_storage_id", using: :btree
  add_index "dropbox_basics", ["external_file_storage_id_mongo_id"], name: "external_file_storage_id_mongo_id", using: :btree
  add_index "dropbox_basics", ["mongo_id"], name: "index_dropbox_basics_on_mongo_id", using: :btree

  create_table "emails", force: :cascade do |t|
    t.string   "mongo_id",                            limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "originally_created_at"
    t.string   "to",                                  limit: 255
    t.string   "from",                                limit: 255
    t.string   "subject",                             limit: 255
    t.text     "attachment_names",                    limit: 65535
    t.integer  "size",                                limit: 4,     default: 0,         null: false
    t.string   "state",                               limit: 255,   default: "created", null: false
    t.text     "errors_list",                         limit: 65535
    t.boolean  "is_error_notified",                                 default: false,     null: false
    t.string   "original_content_file_name",          limit: 255
    t.string   "original_content_content_type",       limit: 255
    t.integer  "original_content_file_size",          limit: 4
    t.datetime "original_content_updated_at"
    t.string   "original_content_fingerprint",        limit: 255
    t.string   "cloud_original_content_file_name",    limit: 255
    t.string   "cloud_original_content_content_type", limit: 255
    t.integer  "cloud_original_content_file_size",    limit: 4
    t.datetime "cloud_original_content_updated_at"
    t.string   "cloud_original_content_fingerprint",  limit: 255
    t.integer  "to_user_id",                          limit: 4
    t.string   "to_user_id_mongo_id",                 limit: 255
    t.integer  "from_user_id",                        limit: 4
    t.string   "from_user_id_mongo_id",               limit: 255
    t.string   "message_id",                          limit: 255
  end

  add_index "emails", ["from_user_id"], name: "from_user_id", using: :btree
  add_index "emails", ["from_user_id_mongo_id"], name: "from_user_id_mongo_id", using: :btree
  add_index "emails", ["mongo_id"], name: "index_emails_on_mongo_id", using: :btree
  add_index "emails", ["to_user_id"], name: "to_user_id", using: :btree
  add_index "emails", ["to_user_id_mongo_id"], name: "to_user_id_mongo_id", using: :btree

  create_table "events", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "user_code",         limit: 255
    t.string   "action",            limit: 255
    t.string   "target_type",       limit: 255
    t.string   "target_name",       limit: 255
    t.text     "target_attributes", limit: 65535
    t.string   "path",              limit: 255
    t.string   "ip_address",        limit: 255
    t.integer  "organization_id",   limit: 4
    t.integer  "user_id",           limit: 4
    t.integer  "target_id",         limit: 4
  end

  add_index "events", ["organization_id"], name: "organization_id", using: :btree
  add_index "events", ["user_id"], name: "user_id", using: :btree

  create_table "exact_online", force: :cascade do |t|
    t.text     "encrypted_client_id",     limit: 65535
    t.text     "encrypted_client_secret", limit: 65535
    t.string   "user_name",               limit: 255
    t.string   "full_name",               limit: 255
    t.string   "email",                   limit: 255
    t.string   "state",                   limit: 255
    t.text     "encrypted_refresh_token", limit: 65535
    t.text     "encrypted_access_token",  limit: 65535
    t.datetime "token_expires_at"
    t.integer  "user_id",                 limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "exercises", force: :cascade do |t|
    t.string   "mongo_id",         limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.date     "start_date"
    t.date     "end_date"
    t.boolean  "is_closed",                    default: false, null: false
    t.integer  "user_id",          limit: 4
    t.string   "user_id_mongo_id", limit: 255
  end

  add_index "exercises", ["mongo_id"], name: "index_exercises_on_mongo_id", using: :btree
  add_index "exercises", ["user_id"], name: "user_id", using: :btree
  add_index "exercises", ["user_id_mongo_id"], name: "user_id_mongo_id", using: :btree

  create_table "expense_categories", force: :cascade do |t|
    t.string  "mongo_id",                      limit: 255
    t.string  "name",                          limit: 255
    t.string  "description",                   limit: 255
    t.integer "account_book_type_id",          limit: 4
    t.string  "account_book_type_id_mongo_id", limit: 255
  end

  add_index "expense_categories", ["account_book_type_id"], name: "account_book_type_id", using: :btree
  add_index "expense_categories", ["account_book_type_id_mongo_id"], name: "account_book_type_id_mongo_id", using: :btree
  add_index "expense_categories", ["mongo_id"], name: "index_expense_categories_on_mongo_id", using: :btree

  create_table "external_file_storages", force: :cascade do |t|
    t.string   "mongo_id",         limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "path",             limit: 255, default: "iDocus/:code/:year:month/:account_book/", null: false
    t.boolean  "is_path_used",                 default: false,                                     null: false
    t.integer  "used",             limit: 4,   default: 0,                                         null: false
    t.integer  "authorized",       limit: 4,   default: 30,                                        null: false
    t.integer  "user_id",          limit: 4
    t.string   "user_id_mongo_id", limit: 255
  end

  add_index "external_file_storages", ["mongo_id"], name: "index_external_file_storages_on_mongo_id", using: :btree
  add_index "external_file_storages", ["user_id"], name: "user_id", using: :btree
  add_index "external_file_storages", ["user_id_mongo_id"], name: "user_id_mongo_id", using: :btree

  create_table "fiduceo_retrievers", force: :cascade do |t|
    t.string   "mongo_id",                     limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "service_name",                 limit: 255
    t.string   "type",                         limit: 255,   default: "provider", null: false
    t.string   "name",                         limit: 255
    t.string   "login",                        limit: 255
    t.string   "cash_register",                limit: 255
    t.string   "state",                        limit: 255
    t.boolean  "is_active",                                  default: true,       null: false
    t.boolean  "is_selection_needed",                        default: true,       null: false
    t.boolean  "is_auto",                                    default: true,       null: false
    t.boolean  "is_sane",                                    default: true,       null: false
    t.boolean  "is_password_renewal_notified",               default: false,      null: false
    t.boolean  "wait_for_user",                              default: false,      null: false
    t.string   "wait_for_user_label",          limit: 255
    t.text     "pending_document_ids",         limit: 65535
    t.string   "frequency",                    limit: 255,   default: "day",      null: false
    t.string   "journal_name",                 limit: 255
    t.string   "transaction_status",           limit: 255
    t.integer  "user_id",                      limit: 4
    t.string   "user_id_mongo_id",             limit: 255
    t.integer  "journal_id",                   limit: 4
    t.string   "journal_id_mongo_id",          limit: 255
    t.string   "provider_id",                  limit: 255
    t.string   "fiduceo_id",                   limit: 255
    t.string   "bank_id",                      limit: 255
  end

  add_index "fiduceo_retrievers", ["journal_id"], name: "journal_id", using: :btree
  add_index "fiduceo_retrievers", ["journal_id_mongo_id"], name: "journal_id_mongo_id", using: :btree
  add_index "fiduceo_retrievers", ["mongo_id"], name: "index_fiduceo_retrievers_on_mongo_id", using: :btree
  add_index "fiduceo_retrievers", ["user_id"], name: "user_id", using: :btree
  add_index "fiduceo_retrievers", ["user_id_mongo_id"], name: "user_id_mongo_id", using: :btree

  create_table "fiduceo_transactions", force: :cascade do |t|
    t.string   "mongo_id",               limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "status",                 limit: 255,        default: "PENDING",  null: false
    t.text     "events",                 limit: 4294967295
    t.text     "wait_for_user_labels",   limit: 65535
    t.text     "retrieved_document_ids", limit: 65535
    t.boolean  "is_processed",                              default: false,      null: false
    t.string   "type",                   limit: 255,        default: "provider", null: false
    t.string   "service_name",           limit: 255
    t.string   "custom_service_name",    limit: 255
    t.integer  "user_id",                limit: 4
    t.string   "user_id_mongo_id",       limit: 255
    t.integer  "retriever_id",           limit: 4
    t.string   "retriever_id_mongo_id",  limit: 255
    t.string   "fiduceo_id",             limit: 255
  end

  add_index "fiduceo_transactions", ["mongo_id"], name: "index_fiduceo_transactions_on_mongo_id", using: :btree
  add_index "fiduceo_transactions", ["retriever_id"], name: "retriever_id", using: :btree
  add_index "fiduceo_transactions", ["retriever_id_mongo_id"], name: "retriever_id_mongo_id", using: :btree
  add_index "fiduceo_transactions", ["user_id"], name: "user_id", using: :btree
  add_index "fiduceo_transactions", ["user_id_mongo_id"], name: "user_id_mongo_id", using: :btree

  create_table "file_naming_policies", force: :cascade do |t|
    t.string   "mongo_id",                        limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "scope",                           limit: 255, default: "organization", null: false
    t.string   "separator",                       limit: 255, default: "_",            null: false
    t.string   "first_user_identifier",           limit: 255, default: "code",         null: false
    t.integer  "first_user_identifier_position",  limit: 4,   default: 1,              null: false
    t.string   "second_user_identifier",          limit: 255, default: "",             null: false
    t.integer  "second_user_identifier_position", limit: 4,   default: 1,              null: false
    t.boolean  "is_journal_used",                             default: true,           null: false
    t.integer  "journal_position",                limit: 4,   default: 2,              null: false
    t.boolean  "is_period_used",                              default: true,           null: false
    t.integer  "period_position",                 limit: 4,   default: 3,              null: false
    t.boolean  "is_piece_number_used",                        default: true,           null: false
    t.integer  "piece_number_position",           limit: 4,   default: 4,              null: false
    t.boolean  "is_third_party_used",                         default: false,          null: false
    t.integer  "third_party_position",            limit: 4,   default: 5,              null: false
    t.boolean  "is_invoice_number_used",                      default: false,          null: false
    t.integer  "invoice_number_position",         limit: 4,   default: 6,              null: false
    t.boolean  "is_invoice_date_used",                        default: false,          null: false
    t.integer  "invoice_date_position",           limit: 4,   default: 7,              null: false
    t.integer  "organization_id",                 limit: 4
    t.string   "organization_id_mongo_id",        limit: 255
  end

  add_index "file_naming_policies", ["mongo_id"], name: "index_file_naming_policies_on_mongo_id", using: :btree
  add_index "file_naming_policies", ["organization_id"], name: "organization_id", using: :btree
  add_index "file_naming_policies", ["organization_id_mongo_id"], name: "organization_id_mongo_id", using: :btree

  create_table "file_sending_kits", force: :cascade do |t|
    t.string   "mongo_id",                 limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "title",                    limit: 255,   default: "Title",           null: false
    t.text     "instruction",              limit: 65535
    t.integer  "position",                 limit: 4,     default: 0,                 null: false
    t.string   "logo_path",                limit: 255,   default: "logo/path",       null: false
    t.integer  "logo_height",              limit: 4,     default: 0,                 null: false
    t.integer  "logo_width",               limit: 4,     default: 0,                 null: false
    t.string   "left_logo_path",           limit: 255,   default: "left/logo/path",  null: false
    t.integer  "left_logo_height",         limit: 4,     default: 0,                 null: false
    t.integer  "left_logo_width",          limit: 4,     default: 0,                 null: false
    t.string   "right_logo_path",          limit: 255,   default: "right/logo/path", null: false
    t.integer  "right_logo_height",        limit: 4,     default: 0,                 null: false
    t.integer  "right_logo_width",         limit: 4,     default: 0,                 null: false
    t.integer  "organization_id",          limit: 4
    t.string   "organization_id_mongo_id", limit: 255
  end

  add_index "file_sending_kits", ["mongo_id"], name: "index_file_sending_kits_on_mongo_id", using: :btree
  add_index "file_sending_kits", ["organization_id"], name: "organization_id", using: :btree
  add_index "file_sending_kits", ["organization_id_mongo_id"], name: "organization_id_mongo_id", using: :btree

  create_table "firebase_tokens", force: :cascade do |t|
    t.integer  "user_id",                limit: 4
    t.string   "name",                   limit: 255
    t.string   "platform",               limit: 255
    t.datetime "last_registration_date"
    t.datetime "last_sending_date"
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
  end

  add_index "firebase_tokens", ["user_id", "name"], name: "index_owener_id_and_name", using: :btree

  create_table "ftps", force: :cascade do |t|
    t.string   "mongo_id",                          limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "path",                              limit: 255,   default: "iDocus/:code/:year:month/:account_book/", null: false
    t.boolean  "is_configured",                                   default: false,                                     null: false
    t.integer  "external_file_storage_id",          limit: 4
    t.string   "external_file_storage_id_mongo_id", limit: 255
    t.string   "encrypted_host",                    limit: 255
    t.string   "encrypted_login",                   limit: 255
    t.string   "encrypted_password",                limit: 255
    t.string   "encrypted_port",                    limit: 255
    t.boolean  "is_passive",                                      default: true
    t.string   "root_path",                         limit: 255,   default: "/"
    t.datetime "import_checked_at"
    t.text     "previous_import_paths",             limit: 65535
    t.integer  "organization_id",                   limit: 4
  end

  add_index "ftps", ["external_file_storage_id"], name: "external_file_storage_id", using: :btree
  add_index "ftps", ["external_file_storage_id_mongo_id"], name: "external_file_storage_id_mongo_id", using: :btree
  add_index "ftps", ["mongo_id"], name: "index_ftps_on_mongo_id", using: :btree
  add_index "ftps", ["organization_id"], name: "index_ftps_on_organization_id", using: :btree

  create_table "google_docs", force: :cascade do |t|
    t.string   "mongo_id",                          limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_configured",                                 default: false,                                     null: false
    t.string   "path",                              limit: 255, default: "iDocus/:code/:year:month/:account_book/", null: false
    t.integer  "external_file_storage_id",          limit: 4
    t.string   "external_file_storage_id_mongo_id", limit: 255
    t.string   "encrypted_access_token",            limit: 255
    t.string   "encrypted_refresh_token",           limit: 255
    t.string   "encrypted_access_token_expires_at", limit: 255
  end

  add_index "google_docs", ["external_file_storage_id"], name: "external_file_storage_id", using: :btree
  add_index "google_docs", ["external_file_storage_id_mongo_id"], name: "external_file_storage_id_mongo_id", using: :btree
  add_index "google_docs", ["mongo_id"], name: "index_google_docs_on_mongo_id", using: :btree

  create_table "groups", force: :cascade do |t|
    t.string   "mongo_id",                 limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",                     limit: 255
    t.string   "description",              limit: 255
    t.string   "dropbox_delivery_folder",  limit: 255, default: "iDocus_delivery/:code/:year:month/:account_book/", null: false
    t.boolean  "is_dropbox_authorized",                default: false,                                              null: false
    t.integer  "organization_id",          limit: 4
    t.string   "organization_id_mongo_id", limit: 255
  end

  add_index "groups", ["mongo_id"], name: "index_groups_on_mongo_id", using: :btree
  add_index "groups", ["organization_id"], name: "organization_id", using: :btree
  add_index "groups", ["organization_id_mongo_id"], name: "organization_id_mongo_id", using: :btree

  create_table "groups_members", force: :cascade do |t|
    t.integer "member_id", limit: 4, null: false
    t.integer "group_id",  limit: 4, null: false
  end

  add_index "groups_members", ["group_id"], name: "index_groups_members_on_group_id", using: :btree
  add_index "groups_members", ["member_id", "group_id"], name: "index_groups_members_on_member_id_and_group_id", unique: true, using: :btree
  add_index "groups_members", ["member_id"], name: "index_groups_members_on_member_id", using: :btree

  create_table "groups_users", force: :cascade do |t|
    t.integer "user_id",  limit: 4, null: false
    t.integer "group_id", limit: 4, null: false
  end

  add_index "groups_users", ["group_id"], name: "index_groups_users_on_group_id", using: :btree
  add_index "groups_users", ["user_id", "group_id"], name: "index_groups_users_on_user_id_and_group_id", unique: true, using: :btree
  add_index "groups_users", ["user_id"], name: "index_groups_users_on_user_id", using: :btree

  create_table "ibizabox_folders", force: :cascade do |t|
    t.integer  "journal_id",          limit: 4
    t.integer  "user_id",             limit: 4
    t.boolean  "is_selection_needed",             default: true
    t.string   "state",               limit: 255
    t.datetime "last_checked_at"
    t.string   "error_message",       limit: 255
    t.datetime "created_at",                                     null: false
    t.datetime "updated_at",                                     null: false
  end

  create_table "ibizas", force: :cascade do |t|
    t.string   "mongo_id",                 limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "state",                    limit: 255,   default: "none",         null: false
    t.string   "state_2",                  limit: 255,   default: "none",         null: false
    t.text     "description",              limit: 65535
    t.string   "description_separator",    limit: 255,   default: " - ",          null: false
    t.text     "piece_name_format",        limit: 65535
    t.string   "piece_name_format_sep",    limit: 255,   default: " ",            null: false
    t.string   "voucher_ref_target",       limit: 255,   default: "piece_number"
    t.boolean  "is_auto_deliver",                        default: false,          null: false
    t.integer  "organization_id",          limit: 4
    t.string   "organization_id_mongo_id", limit: 255
    t.text     "encrypted_access_token",   limit: 65535
    t.text     "encrypted_access_token_2", limit: 65535
    t.boolean  "is_analysis_activated",                  default: false
    t.boolean  "is_analysis_to_validate",                default: false
  end

  add_index "ibizas", ["mongo_id"], name: "index_ibizas_on_mongo_id", using: :btree
  add_index "ibizas", ["organization_id"], name: "organization_id", using: :btree
  add_index "ibizas", ["organization_id_mongo_id"], name: "organization_id_mongo_id", using: :btree

  create_table "invoices", force: :cascade do |t|
    t.string   "mongo_id",                   limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "number",                     limit: 255
    t.float    "vat_ratio",                  limit: 24,  default: 1.2, null: false
    t.integer  "amount_in_cents_w_vat",      limit: 4
    t.string   "content_file_name",          limit: 255
    t.string   "content_content_type",       limit: 255
    t.integer  "content_file_size",          limit: 4
    t.datetime "content_updated_at"
    t.string   "content_fingerprint",        limit: 255
    t.string   "cloud_content_file_name",    limit: 255
    t.string   "cloud_content_content_type", limit: 255
    t.integer  "cloud_content_file_size",    limit: 4
    t.datetime "cloud_content_updated_at"
    t.string   "cloud_content_fingerprint",  limit: 255
    t.integer  "organization_id",            limit: 4
    t.string   "organization_id_mongo_id",   limit: 255
    t.integer  "user_id",                    limit: 4
    t.string   "user_id_mongo_id",           limit: 255
    t.integer  "subscription_id",            limit: 4
    t.string   "subscription_id_mongo_id",   limit: 255
    t.integer  "period_id",                  limit: 4
    t.string   "period_id_mongo_id",         limit: 255
  end

  add_index "invoices", ["mongo_id"], name: "index_invoices_on_mongo_id", using: :btree
  add_index "invoices", ["organization_id"], name: "organization_id", using: :btree
  add_index "invoices", ["organization_id_mongo_id"], name: "organization_id_mongo_id", using: :btree
  add_index "invoices", ["period_id"], name: "period_id", using: :btree
  add_index "invoices", ["period_id_mongo_id"], name: "period_id_mongo_id", using: :btree
  add_index "invoices", ["subscription_id"], name: "subscription_id", using: :btree
  add_index "invoices", ["subscription_id_mongo_id"], name: "subscription_id_mongo_id", using: :btree
  add_index "invoices", ["user_id"], name: "user_id", using: :btree
  add_index "invoices", ["user_id_mongo_id"], name: "user_id_mongo_id", using: :btree

  create_table "knowings", force: :cascade do |t|
    t.string   "mongo_id",                         limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_active",                                    default: true,            null: false
    t.string   "state",                            limit: 255, default: "not_performed", null: false
    t.string   "pole_name",                        limit: 255, default: "Pièces",        null: false
    t.boolean  "is_third_party_included",                      default: false,           null: false
    t.boolean  "is_pre_assignment_state_included",             default: false,           null: false
    t.integer  "organization_id",                  limit: 4
    t.string   "organization_id_mongo_id",         limit: 255
    t.string   "encrypted_url",                    limit: 255
    t.string   "encrypted_username",               limit: 255
    t.string   "encrypted_password",               limit: 255
  end

  add_index "knowings", ["mongo_id"], name: "index_knowings_on_mongo_id", using: :btree
  add_index "knowings", ["organization_id"], name: "organization_id", using: :btree
  add_index "knowings", ["organization_id_mongo_id"], name: "organization_id_mongo_id", using: :btree

  create_table "mcf_documents", force: :cascade do |t|
    t.integer  "user_id",            limit: 4
    t.string   "access_token",       limit: 255
    t.string   "code",               limit: 255
    t.string   "journal",            limit: 255
    t.string   "original_file_name", limit: 255,        default: ""
    t.text     "file64",             limit: 4294967295
    t.string   "state",              limit: 255,        default: "ready"
    t.integer  "retake_retry",       limit: 4,          default: 0
    t.datetime "retake_at"
    t.boolean  "is_generated",                          default: false
    t.boolean  "is_moved",                              default: false
    t.boolean  "is_notified",                           default: false
    t.text     "error_message",      limit: 65535
    t.datetime "updated_at"
    t.datetime "created_at"
  end

  add_index "mcf_documents", ["user_id"], name: "index_mcf_documents_on_user_id", using: :btree

  create_table "mcf_settings", force: :cascade do |t|
    t.integer "organization_id",                   limit: 4
    t.string  "encrypted_access_token",            limit: 255
    t.string  "encrypted_refresh_token",           limit: 255
    t.string  "encrypted_access_token_expires_at", limit: 255
    t.string  "delivery_path_pattern",             limit: 255, default: "/:year:month/:account_book/"
    t.boolean "is_delivery_activated",                         default: true
  end

  add_index "mcf_settings", ["organization_id"], name: "index_mcf_settings_on_organization_id", using: :btree

  create_table "members", force: :cascade do |t|
    t.integer  "organization_id",          limit: 4,                            null: false
    t.integer  "user_id",                  limit: 4,                            null: false
    t.datetime "created_at",                                                    null: false
    t.datetime "updated_at",                                                    null: false
    t.string   "role",                     limit: 255, default: "collaborator", null: false
    t.string   "code",                     limit: 255,                          null: false
    t.boolean  "manage_groups",                        default: true
    t.boolean  "manage_collaborators",                 default: false
    t.boolean  "manage_customers",                     default: true
    t.boolean  "manage_journals",                      default: true
    t.boolean  "manage_customer_journals",             default: true
  end

  add_index "members", ["code"], name: "index_members_on_code", unique: true, using: :btree
  add_index "members", ["organization_id", "user_id"], name: "index_organization_user_on_members", unique: true, using: :btree
  add_index "members", ["role"], name: "index_members_on_role", using: :btree

  create_table "mobile_connexions", force: :cascade do |t|
    t.integer "user_id",       limit: 4
    t.string  "platform",      limit: 255
    t.string  "version",       limit: 255
    t.integer "periode",       limit: 4
    t.integer "daily_counter", limit: 4,   default: 1
    t.date    "date"
  end

  add_index "mobile_connexions", ["periode"], name: "index_mobile_connexions_on_periode", using: :btree
  add_index "mobile_connexions", ["platform"], name: "index_mobile_connexions_on_platform", using: :btree

  create_table "new_provider_requests", force: :cascade do |t|
    t.string   "mongo_id",              limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "state",                 limit: 255,   default: "pending", null: false
    t.string   "name",                  limit: 255
    t.datetime "notified_at"
    t.datetime "processing_at"
    t.integer  "user_id",               limit: 4
    t.string   "user_id_mongo_id",      limit: 255
    t.integer  "api_id",                limit: 4
    t.boolean  "is_sent",                             default: false
    t.text     "encrypted_url",         limit: 65535
    t.string   "encrypted_login",       limit: 255
    t.text     "encrypted_description", limit: 65535
    t.text     "encrypted_message",     limit: 65535
    t.string   "encrypted_email",       limit: 255
    t.string   "encrypted_password",    limit: 255
    t.string   "encrypted_types",       limit: 255
  end

  add_index "new_provider_requests", ["mongo_id"], name: "index_new_provider_requests_on_mongo_id", using: :btree
  add_index "new_provider_requests", ["user_id"], name: "user_id", using: :btree
  add_index "new_provider_requests", ["user_id_mongo_id"], name: "user_id_mongo_id", using: :btree

  create_table "news", force: :cascade do |t|
    t.string   "state",           limit: 255,   null: false
    t.string   "title",           limit: 255,   null: false
    t.text     "body",            limit: 65535, null: false
    t.string   "target_audience", limit: 255,   null: false
    t.string   "url",             limit: 255
    t.datetime "published_at"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
  end

  add_index "news", ["published_at"], name: "index_news_on_published_at", using: :btree
  add_index "news", ["target_audience"], name: "index_news_on_target_audience", using: :btree

  create_table "notifiables_notifies", force: :cascade do |t|
    t.integer "notifiable_id",   limit: 4
    t.string  "notifiable_type", limit: 255
    t.integer "notify_id",       limit: 4
    t.string  "label",           limit: 255
  end

  add_index "notifiables_notifies", ["notify_id", "notifiable_id", "notifiable_type", "label"], name: "index_notifiable", using: :btree

  create_table "notifications", force: :cascade do |t|
    t.integer  "user_id",     limit: 4
    t.string   "notice_type", limit: 255,                   null: false
    t.boolean  "is_read",                   default: false, null: false
    t.boolean  "is_sent",                   default: false, null: false
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
    t.string   "title",       limit: 255
    t.text     "message",     limit: 65535
    t.string   "url",         limit: 255
  end

  add_index "notifications", ["user_id"], name: "index_notifications_on_user_id", using: :btree

  create_table "notifies", force: :cascade do |t|
    t.boolean  "to_send_docs",                                      default: true
    t.string   "published_docs",                        limit: 255, default: "delay"
    t.boolean  "reception_of_emailed_docs",                         default: true
    t.boolean  "r_wrong_pass",                                      default: false
    t.boolean  "r_site_unavailable",                                default: false
    t.boolean  "r_action_needed",                                   default: false
    t.boolean  "r_bug",                                             default: false
    t.string   "r_new_documents",                       limit: 255, default: "none"
    t.integer  "r_new_documents_count",                 limit: 4,   default: 0
    t.string   "r_new_operations",                      limit: 255, default: "none"
    t.integer  "r_new_operations_count",                limit: 4,   default: 0
    t.boolean  "r_no_bank_account_configured",                      default: false
    t.boolean  "document_being_processed",                          default: false
    t.boolean  "paper_quota_reached",                               default: false
    t.boolean  "new_pre_assignment_available",                      default: false
    t.boolean  "dropbox_invalid_access_token",                      default: true
    t.boolean  "dropbox_insufficient_space",                        default: true
    t.boolean  "ftp_auth_failure",                                  default: true
    t.boolean  "detected_preseizure_duplication",                   default: false
    t.integer  "detected_preseizure_duplication_count", limit: 4,   default: 0
    t.integer  "unblocked_preseizure_count",            limit: 4,   default: 0
    t.boolean  "new_scanned_documents",                             default: false
    t.string   "pre_assignment_delivery_errors",        limit: 255, default: "none"
    t.datetime "created_at",                                                          null: false
    t.datetime "updated_at",                                                          null: false
    t.integer  "user_id",                               limit: 4
    t.boolean  "pre_assignment_ignored_piece",                      default: false
    t.integer  "pre_assignment_ignored_piece_count",    limit: 4,   default: 0
    t.boolean  "mcf_document_errors",                               default: false
    t.boolean  "pre_assignment_export",                             default: true
  end

  add_index "notifies", ["r_new_documents_count"], name: "index_notifies_on_r_new_documents_count", using: :btree
  add_index "notifies", ["r_new_operations_count"], name: "index_notifies_on_r_new_operations_count", using: :btree
  add_index "notifies", ["user_id"], name: "index_notifies_on_user_id", using: :btree

  create_table "operations", force: :cascade do |t|
    t.string   "mongo_id",                     limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.date     "date"
    t.date     "value_date"
    t.date     "transaction_date"
    t.text     "label",                        limit: 4294967295
    t.decimal  "amount",                                          precision: 11, scale: 2
    t.string   "comment",                      limit: 255
    t.string   "supplier_found",               limit: 255
    t.integer  "category_id",                  limit: 4
    t.string   "category",                     limit: 255
    t.datetime "accessed_at"
    t.datetime "processed_at"
    t.boolean  "is_locked"
    t.integer  "organization_id",              limit: 4
    t.string   "organization_id_mongo_id",     limit: 255
    t.integer  "user_id",                      limit: 4
    t.string   "user_id_mongo_id",             limit: 255
    t.integer  "bank_account_id",              limit: 4
    t.string   "bank_account_id_mongo_id",     limit: 255
    t.integer  "pack_id",                      limit: 4
    t.string   "pack_id_mongo_id",             limit: 255
    t.integer  "piece_id",                     limit: 4
    t.string   "piece_id_mongo_id",            limit: 255
    t.string   "api_id",                       limit: 255
    t.string   "type_id",                      limit: 255
    t.string   "api_name",                     limit: 255,                                 default: "budgea"
    t.string   "type_name",                    limit: 255
    t.boolean  "is_coming",                                                                default: false
    t.datetime "deleted_at"
    t.datetime "forced_processing_at"
    t.integer  "forced_processing_by_user_id", limit: 4
    t.text     "currency",                     limit: 65535
  end

  add_index "operations", ["api_id"], name: "fiduceo_id", using: :btree
  add_index "operations", ["api_name"], name: "index_operations_on_api_name", using: :btree
  add_index "operations", ["bank_account_id"], name: "bank_account_id", using: :btree
  add_index "operations", ["bank_account_id_mongo_id"], name: "bank_account_id_mongo_id", using: :btree
  add_index "operations", ["created_at"], name: "index_operations_on_created_at", using: :btree
  add_index "operations", ["deleted_at"], name: "index_operations_on_deleted_at", using: :btree
  add_index "operations", ["forced_processing_at"], name: "index_operations_on_forced_processing_at", using: :btree
  add_index "operations", ["is_locked"], name: "index_operations_on_is_locked", using: :btree
  add_index "operations", ["mongo_id"], name: "index_operations_on_mongo_id", using: :btree
  add_index "operations", ["organization_id"], name: "organization_id", using: :btree
  add_index "operations", ["organization_id_mongo_id"], name: "organization_id_mongo_id", using: :btree
  add_index "operations", ["pack_id"], name: "pack_id", using: :btree
  add_index "operations", ["pack_id_mongo_id"], name: "pack_id_mongo_id", using: :btree
  add_index "operations", ["piece_id"], name: "piece_id", using: :btree
  add_index "operations", ["piece_id_mongo_id"], name: "piece_id_mongo_id", using: :btree
  add_index "operations", ["processed_at"], name: "index_operations_on_processed_at", using: :btree
  add_index "operations", ["user_id"], name: "user_id", using: :btree
  add_index "operations", ["user_id_mongo_id"], name: "user_id_mongo_id", using: :btree

  create_table "orders", force: :cascade do |t|
    t.string   "mongo_id",                                        limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "locked_at"
    t.datetime "locked_until"
    t.string   "state",                                           limit: 255, default: "pending", null: false
    t.string   "type",                                            limit: 255
    t.integer  "price_in_cents_wo_vat",                           limit: 4
    t.float    "vat_ratio",                                       limit: 24,  default: 1.2,       null: false
    t.integer  "dematbox_count",                                  limit: 4,   default: 0,         null: false
    t.integer  "period_duration",                                 limit: 4,   default: 1,         null: false
    t.integer  "paper_set_casing_size",                           limit: 4,   default: 0,         null: false
    t.integer  "paper_set_folder_count",                          limit: 4,   default: 0,         null: false
    t.date     "paper_set_start_date"
    t.date     "paper_set_end_date"
    t.integer  "organization_id",                                 limit: 4
    t.string   "organization_id_mongo_id",                        limit: 255
    t.integer  "user_id",                                         limit: 4
    t.string   "user_id_mongo_id",                                limit: 255
    t.integer  "period_id",                                       limit: 4
    t.string   "period_id_mongo_id",                              limit: 255
    t.datetime "address_created_at"
    t.datetime "address_updated_at"
    t.string   "address_first_name",                              limit: 255
    t.string   "address_last_name",                               limit: 255
    t.string   "address_email",                                   limit: 255
    t.string   "address_company",                                 limit: 255
    t.string   "address_company_number",                          limit: 255
    t.string   "address_address_1",                               limit: 255
    t.string   "address_address_2",                               limit: 255
    t.string   "address_city",                                    limit: 255
    t.string   "address_zip",                                     limit: 255
    t.string   "address_state",                                   limit: 255
    t.string   "address_country",                                 limit: 255
    t.string   "address_building",                                limit: 255
    t.string   "address_place_called_or_postal_box",              limit: 255
    t.string   "address_door_code",                               limit: 255
    t.string   "address_other",                                   limit: 255
    t.string   "address_phone",                                   limit: 255
    t.string   "address_phone_mobile",                            limit: 255
    t.boolean  "address_is_for_billing",                                      default: false,     null: false
    t.boolean  "address_is_for_paper_return",                                 default: false,     null: false
    t.boolean  "address_is_for_paper_set_shipping",                           default: false,     null: false
    t.boolean  "address_is_for_dematbox_shipping",                            default: false,     null: false
    t.datetime "paper_return_address_created_at"
    t.datetime "paper_return_address_updated_at"
    t.string   "paper_return_address_first_name",                 limit: 255
    t.string   "paper_return_address_last_name",                  limit: 255
    t.string   "paper_return_address_email",                      limit: 255
    t.string   "paper_return_address_company",                    limit: 255
    t.string   "paper_return_address_company_number",             limit: 255
    t.string   "paper_return_address_address_1",                  limit: 255
    t.string   "paper_return_address_address_2",                  limit: 255
    t.string   "paper_return_address_city",                       limit: 255
    t.string   "paper_return_address_zip",                        limit: 255
    t.string   "paper_return_address_state",                      limit: 255
    t.string   "paper_return_address_country",                    limit: 255
    t.string   "paper_return_address_building",                   limit: 255
    t.string   "paper_return_address_place_called_or_postal_box", limit: 255
    t.string   "paper_return_address_door_code",                  limit: 255
    t.string   "paper_return_address_other",                      limit: 255
    t.string   "paper_return_address_phone",                      limit: 255
    t.string   "paper_return_address_phone_mobile",               limit: 255
    t.boolean  "paper_return_address_is_for_billing",                         default: false,     null: false
    t.boolean  "paper_return_address_is_for_paper_return",                    default: false,     null: false
    t.boolean  "paper_return_address_is_for_paper_set_shipping",              default: false,     null: false
    t.boolean  "paper_return_address_is_for_dematbox_shipping",               default: false,     null: false
  end

  add_index "orders", ["mongo_id"], name: "index_orders_on_mongo_id", using: :btree
  add_index "orders", ["organization_id"], name: "organization_id", using: :btree
  add_index "orders", ["organization_id_mongo_id"], name: "organization_id_mongo_id", using: :btree
  add_index "orders", ["period_id"], name: "period_id", using: :btree
  add_index "orders", ["period_id_mongo_id"], name: "period_id_mongo_id", using: :btree
  add_index "orders", ["user_id"], name: "user_id", using: :btree
  add_index "orders", ["user_id_mongo_id"], name: "user_id_mongo_id", using: :btree

  create_table "organization_groups", force: :cascade do |t|
    t.string   "name",                         limit: 255,                 null: false
    t.string   "description",                  limit: 255
    t.boolean  "is_auto_membership_activated",             default: false, null: false
    t.datetime "created_at",                                               null: false
    t.datetime "updated_at",                                               null: false
  end

  create_table "organization_rights", force: :cascade do |t|
    t.string   "mongo_id",                                   limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_groups_management_authorized",                        default: true,  null: false
    t.boolean  "is_collaborators_management_authorized",                 default: false, null: false
    t.boolean  "is_customers_management_authorized",                     default: true,  null: false
    t.boolean  "is_journals_management_authorized",                      default: true,  null: false
    t.boolean  "is_customer_journals_management_authorized",             default: true,  null: false
    t.integer  "user_id",                                    limit: 4
    t.string   "user_id_mongo_id",                           limit: 255
  end

  add_index "organization_rights", ["mongo_id"], name: "index_organization_rights_on_mongo_id", using: :btree
  add_index "organization_rights", ["user_id"], name: "user_id", using: :btree
  add_index "organization_rights", ["user_id_mongo_id"], name: "user_id_mongo_id", using: :btree

  create_table "organizations", force: :cascade do |t|
    t.string   "mongo_id",                        limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",                            limit: 255
    t.string   "description",                     limit: 255
    t.string   "code",                            limit: 255
    t.boolean  "is_detail_authorized",                        default: false, null: false
    t.boolean  "is_period_duration_editable",                 default: true,  null: false
    t.boolean  "is_test",                                     default: false, null: false
    t.boolean  "is_for_admin",                                default: false, null: false
    t.boolean  "is_active",                                   default: true,  null: false
    t.boolean  "is_suspended",                                default: false, null: false
    t.boolean  "is_quadratus_used",                           default: false, null: false
    t.boolean  "is_quadratus_auto_deliver",                   default: false
    t.boolean  "is_pre_assignment_date_computed",             default: false, null: false
    t.boolean  "is_csv_descriptor_used",                      default: false, null: false
    t.boolean  "is_csv_descriptor_auto_deliver",              default: false
    t.boolean  "is_coala_used",                               default: false, null: false
    t.boolean  "is_coala_auto_deliver",                       default: false
    t.integer  "authd_prev_period",               limit: 4,   default: 1,     null: false
    t.integer  "auth_prev_period_until_day",      limit: 4,   default: 11,    null: false
    t.integer  "auth_prev_period_until_month",    limit: 4,   default: 0,     null: false
    t.integer  "leader_id",                       limit: 4
    t.string   "leader_id_mongo_id",              limit: 255
    t.boolean  "is_operation_processing_forced",              default: false
    t.boolean  "is_operation_value_date_needed",              default: false
    t.integer  "preseizure_date_option",          limit: 4,   default: 0
    t.boolean  "is_duplicate_blocker_activated",              default: true
    t.integer  "organization_group_id",           limit: 4
    t.boolean  "subject_to_vat",                              default: true
    t.boolean  "is_exact_online_used",                        default: false
    t.boolean  "is_exact_online_auto_deliver",                default: false
    t.string   "invoice_mails",                   limit: 255
    t.boolean  "is_cegid_used",                               default: false
    t.boolean  "is_cegid_auto_deliver",                       default: false
  end

  add_index "organizations", ["leader_id"], name: "leader_id", using: :btree
  add_index "organizations", ["leader_id_mongo_id"], name: "leader_id_mongo_id", using: :btree
  add_index "organizations", ["mongo_id"], name: "index_organizations_on_mongo_id", using: :btree
  add_index "organizations", ["organization_group_id"], name: "index_organizations_on_organization_group_id", using: :btree

  create_table "pack_dividers", force: :cascade do |t|
    t.string   "mongo_id",         limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",             limit: 255
    t.string   "type",             limit: 255
    t.string   "origin",           limit: 255
    t.boolean  "is_a_cover",                   default: false, null: false
    t.integer  "pages_number",     limit: 4
    t.integer  "position",         limit: 4
    t.integer  "pack_id",          limit: 4
    t.string   "pack_id_mongo_id", limit: 255
  end

  add_index "pack_dividers", ["is_a_cover"], name: "index_pack_dividers_on_is_a_cover", using: :btree
  add_index "pack_dividers", ["mongo_id"], name: "index_pack_dividers_on_mongo_id", using: :btree
  add_index "pack_dividers", ["origin"], name: "index_pack_dividers_on_origin", using: :btree
  add_index "pack_dividers", ["pack_id"], name: "pack_id", using: :btree
  add_index "pack_dividers", ["pack_id_mongo_id"], name: "pack_id_mongo_id", using: :btree
  add_index "pack_dividers", ["type"], name: "index_pack_dividers_on_type", using: :btree

  create_table "pack_pieces", force: :cascade do |t|
    t.string   "mongo_id",                   limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",                       limit: 255
    t.integer  "number",                     limit: 4
    t.boolean  "is_a_cover",                                    default: false,   null: false
    t.string   "origin",                     limit: 255
    t.integer  "position",                   limit: 4
    t.integer  "pages_number",               limit: 4,          default: 0
    t.string   "token",                      limit: 255
    t.boolean  "is_awaiting_pre_assignment",                    default: false,   null: false
    t.string   "pre_assignment_state",       limit: 255,        default: "ready"
    t.string   "pre_assignment_comment",     limit: 255
    t.string   "content_file_name",          limit: 255
    t.string   "content_content_type",       limit: 255
    t.integer  "content_file_size",          limit: 4
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
    t.index ["mongo_id"], name: "index_orders_on_mongo_id"
    t.index ["organization_id"], name: "organization_id"
    t.index ["organization_id_mongo_id"], name: "organization_id_mongo_id"
    t.index ["period_id"], name: "period_id"
    t.index ["period_id_mongo_id"], name: "period_id_mongo_id"
    t.index ["user_id"], name: "user_id"
    t.index ["user_id_mongo_id"], name: "user_id_mongo_id"
  end

  create_table "organization_groups", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "description"
    t.boolean "is_auto_membership_activated", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "organization_rights", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "mongo_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "is_groups_management_authorized", default: true, null: false
    t.boolean "is_collaborators_management_authorized", default: false, null: false
    t.boolean "is_customers_management_authorized", default: true, null: false
    t.boolean "is_journals_management_authorized", default: true, null: false
    t.boolean "is_customer_journals_management_authorized", default: true, null: false
    t.integer "user_id"
    t.string "user_id_mongo_id"
    t.index ["mongo_id"], name: "index_organization_rights_on_mongo_id"
    t.index ["user_id"], name: "user_id"
    t.index ["user_id_mongo_id"], name: "user_id_mongo_id"
  end

  create_table "organizations", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "mongo_id"
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
    t.string "leader_id_mongo_id"
    t.boolean "is_operation_processing_forced", default: false
    t.boolean "is_operation_value_date_needed", default: false
    t.integer "preseizure_date_option", default: 0
    t.boolean "is_duplicate_blocker_activated", default: true
    t.integer "organization_group_id"
    t.boolean "subject_to_vat", default: true
    t.boolean "is_exact_online_used", default: false
    t.boolean "is_exact_online_auto_deliver", default: false
    t.index ["leader_id"], name: "leader_id"
    t.index ["leader_id_mongo_id"], name: "leader_id_mongo_id"
    t.index ["mongo_id"], name: "index_organizations_on_mongo_id"
    t.index ["organization_group_id"], name: "index_organizations_on_organization_group_id"
  end

  create_table "pack_dividers", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "mongo_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "name"
    t.string "type"
    t.string "origin"
    t.boolean "is_a_cover", default: false, null: false
    t.integer "pages_number"
    t.integer "position"
    t.integer "pack_id"
    t.string "pack_id_mongo_id"
    t.index ["is_a_cover"], name: "index_pack_dividers_on_is_a_cover"
    t.index ["mongo_id"], name: "index_pack_dividers_on_mongo_id"
    t.index ["origin"], name: "index_pack_dividers_on_origin"
    t.index ["pack_id"], name: "pack_id"
    t.index ["pack_id_mongo_id"], name: "pack_id_mongo_id"
    t.index ["type"], name: "index_pack_dividers_on_type"
  end

  create_table "pack_pieces", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "mongo_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "name"
    t.integer "number"
    t.boolean "is_a_cover", default: false, null: false
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
    t.string   "content_fingerprint",        limit: 255
    t.string   "cloud_content_file_name",    limit: 255
    t.string   "cloud_content_content_type", limit: 255
    t.integer  "cloud_content_file_size",    limit: 4
    t.datetime "cloud_content_updated_at"
    t.string   "cloud_content_fingerprint",  limit: 255
    t.integer  "organization_id",            limit: 4
    t.string   "organization_id_mongo_id",   limit: 255
    t.integer  "user_id",                    limit: 4
    t.string   "user_id_mongo_id",           limit: 255
    t.integer  "pack_id",                    limit: 4
    t.string   "pack_id_mongo_id",           limit: 255
    t.integer  "analytic_reference_id",      limit: 4
    t.text     "content_text",               limit: 4294967295
    t.text     "tags",                       limit: 65535
    t.boolean  "is_finalized",                                  default: false
  end

  add_index "pack_pieces", ["analytic_reference_id"], name: "index_pack_pieces_on_analytic_reference_id", using: :btree
  add_index "pack_pieces", ["is_finalized"], name: "index_pack_pieces_on_is_finalized", using: :btree
  add_index "pack_pieces", ["name"], name: "index_pack_pieces_on_name", using: :btree
  add_index "pack_pieces", ["number"], name: "index_pack_pieces_on_number", using: :btree
  add_index "pack_pieces", ["organization_id"], name: "organization_id", using: :btree
  add_index "pack_pieces", ["pack_id"], name: "pack_id", using: :btree
  add_index "pack_pieces", ["position"], name: "index_pack_pieces_on_position", using: :btree
  add_index "pack_pieces", ["user_id"], name: "user_id", using: :btree

  create_table "pack_report_expenses", force: :cascade do |t|
    t.string   "mongo_id",                 limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "amount_in_cents_wo_vat",   limit: 24
    t.float    "amount_in_cents_w_vat",    limit: 24
    t.float    "vat",                      limit: 24
    t.date     "date"
    t.string   "type",                     limit: 255
    t.string   "origin",                   limit: 255
    t.integer  "obs_type",                 limit: 4
    t.integer  "position",                 limit: 4
    t.integer  "organization_id",          limit: 4
    t.string   "organization_id_mongo_id", limit: 255
    t.integer  "user_id",                  limit: 4
    t.string   "user_id_mongo_id",         limit: 255
    t.integer  "report_id",                limit: 4
    t.string   "report_id_mongo_id",       limit: 255
    t.integer  "piece_id",                 limit: 4
    t.string   "piece_id_mongo_id",        limit: 255
  end

  add_index "pack_report_expenses", ["mongo_id"], name: "index_pack_report_expenses_on_mongo_id", using: :btree
  add_index "pack_report_expenses", ["organization_id"], name: "organization_id", using: :btree
  add_index "pack_report_expenses", ["organization_id_mongo_id"], name: "organization_id_mongo_id", using: :btree
  add_index "pack_report_expenses", ["piece_id"], name: "piece_id", using: :btree
  add_index "pack_report_expenses", ["piece_id_mongo_id"], name: "piece_id_mongo_id", using: :btree
  add_index "pack_report_expenses", ["report_id"], name: "report_id", using: :btree
  add_index "pack_report_expenses", ["report_id_mongo_id"], name: "report_id_mongo_id", using: :btree
  add_index "pack_report_expenses", ["user_id"], name: "user_id", using: :btree
  add_index "pack_report_expenses", ["user_id_mongo_id"], name: "user_id_mongo_id", using: :btree

  create_table "pack_report_observation_guests", force: :cascade do |t|
    t.string  "mongo_id",                limit: 255
    t.string  "first_name",              limit: 255
    t.string  "last_name",               limit: 255
    t.integer "observation_id",          limit: 4
    t.string  "observation_id_mongo_id", limit: 255
  end

  add_index "pack_report_observation_guests", ["mongo_id"], name: "index_pack_report_observation_guests_on_mongo_id", using: :btree
  add_index "pack_report_observation_guests", ["observation_id"], name: "observation_id", using: :btree
  add_index "pack_report_observation_guests", ["observation_id_mongo_id"], name: "observation_id_mongo_id", using: :btree

  create_table "pack_report_observations", force: :cascade do |t|
    t.string  "mongo_id",            limit: 255
    t.string  "comment",             limit: 255
    t.integer "expense_id",          limit: 4
    t.string  "expense_id_mongo_id", limit: 255
  end

  add_index "pack_report_observations", ["expense_id"], name: "expense_id", using: :btree
  add_index "pack_report_observations", ["expense_id_mongo_id"], name: "expense_id_mongo_id", using: :btree
  add_index "pack_report_observations", ["mongo_id"], name: "index_pack_report_observations_on_mongo_id", using: :btree

  create_table "pack_report_preseizure_accounts", force: :cascade do |t|
    t.string   "mongo_id",               limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "type",                   limit: 4
    t.string   "number",                 limit: 255
    t.string   "lettering",              limit: 255
    t.integer  "preseizure_id",          limit: 4
    t.string   "preseizure_id_mongo_id", limit: 255
  end

  add_index "pack_report_preseizure_accounts", ["mongo_id"], name: "index_pack_report_preseizure_accounts_on_mongo_id", using: :btree
  add_index "pack_report_preseizure_accounts", ["preseizure_id"], name: "preseizure_id", using: :btree
  add_index "pack_report_preseizure_accounts", ["preseizure_id_mongo_id"], name: "preseizure_id_mongo_id", using: :btree

  create_table "pack_report_preseizure_entries", force: :cascade do |t|
    t.string   "mongo_id",               limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "type",                   limit: 4
    t.string   "number",                 limit: 255
    t.decimal  "amount",                             precision: 11, scale: 2
    t.integer  "preseizure_id",          limit: 4
    t.string   "preseizure_id_mongo_id", limit: 255
    t.integer  "account_id",             limit: 4
    t.string   "account_id_mongo_id",    limit: 255
  end

  add_index "pack_report_preseizure_entries", ["account_id"], name: "account_id", using: :btree
  add_index "pack_report_preseizure_entries", ["account_id_mongo_id"], name: "account_id_mongo_id", using: :btree
  add_index "pack_report_preseizure_entries", ["mongo_id"], name: "index_pack_report_preseizure_entries_on_mongo_id", using: :btree
  add_index "pack_report_preseizure_entries", ["preseizure_id"], name: "preseizure_id", using: :btree
  add_index "pack_report_preseizure_entries", ["preseizure_id_mongo_id"], name: "preseizure_id_mongo_id", using: :btree

  create_table "pack_report_preseizures", force: :cascade do |t|
    t.string   "mongo_id",                       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "type",                           limit: 255
    t.datetime "date"
    t.datetime "deadline_date"
    t.text     "operation_label",                limit: 65535
    t.string   "observation",                    limit: 255
    t.integer  "position",                       limit: 4
    t.string   "piece_number",                   limit: 255
    t.decimal  "amount",                                       precision: 11, scale: 2
    t.string   "currency",                       limit: 255
    t.string   "unit",                           limit: 5,                              default: "EUR"
    t.float    "conversion_rate",                limit: 24
    t.string   "third_party",                    limit: 255
    t.integer  "category_id",                    limit: 4
    t.boolean  "is_made_by_abbyy",                                                      default: false, null: false
    t.boolean  "is_delivered",                                                          default: false, null: false
    t.datetime "delivery_tried_at"
    t.text     "delivery_message",               limit: 65535
    t.boolean  "is_locked",                                                             default: false, null: false
    t.integer  "organization_id",                limit: 4
    t.string   "organization_id_mongo_id",       limit: 255
    t.integer  "user_id",                        limit: 4
    t.string   "user_id_mongo_id",               limit: 255
    t.integer  "report_id",                      limit: 4
    t.string   "report_id_mongo_id",             limit: 255
    t.integer  "piece_id",                       limit: 4
    t.string   "piece_id_mongo_id",              limit: 255
    t.integer  "operation_id",                   limit: 4
    t.string   "operation_id_mongo_id",          limit: 255
    t.integer  "similar_preseizure_id",          limit: 4
    t.datetime "duplicate_detected_at"
    t.boolean  "is_blocked_for_duplication",                                            default: false
    t.datetime "marked_as_duplicate_at"
    t.integer  "marked_as_duplicate_by_user_id", limit: 4
    t.datetime "duplicate_unblocked_at"
    t.integer  "duplicate_unblocked_by_user_id", limit: 4
    t.decimal  "cached_amount",                                precision: 11, scale: 2
    t.string   "is_delivered_to",                limit: 255,                            default: ""
    t.string   "exact_online_id",                limit: 255
  end

  add_index "pack_report_preseizures", ["duplicate_unblocked_by_user_id"], name: "index_pack_report_preseizures_on_duplicate_unblocked_by_user_id", using: :btree
  add_index "pack_report_preseizures", ["is_blocked_for_duplication"], name: "index_pack_report_preseizures_on_is_blocked_for_duplication", using: :btree
  add_index "pack_report_preseizures", ["is_delivered_to"], name: "index_pack_report_preseizures_on_is_delivered_to", using: :btree
  add_index "pack_report_preseizures", ["marked_as_duplicate_by_user_id"], name: "index_pack_report_preseizures_on_marked_as_duplicate_by_user_id", using: :btree
  add_index "pack_report_preseizures", ["operation_id"], name: "operation_id", using: :btree
  add_index "pack_report_preseizures", ["organization_id"], name: "organization_id", using: :btree
  add_index "pack_report_preseizures", ["piece_id"], name: "piece_id", using: :btree
  add_index "pack_report_preseizures", ["position"], name: "index_pack_report_preseizures_on_position", using: :btree
  add_index "pack_report_preseizures", ["report_id"], name: "report_id", using: :btree
  add_index "pack_report_preseizures", ["similar_preseizure_id"], name: "index_pack_report_preseizures_on_similar_preseizure_id", using: :btree
  add_index "pack_report_preseizures", ["third_party"], name: "index_pack_report_preseizures_on_third_party", using: :btree
  add_index "pack_report_preseizures", ["user_id"], name: "user_id", using: :btree

  create_table "pack_report_preseizures_pre_assignment_deliveries", force: :cascade do |t|
    t.integer "pre_assignment_delivery_id", limit: 4
    t.integer "preseizure_id",              limit: 4
  end

  create_table "pack_report_preseizures_pre_assignment_exports", force: :cascade do |t|
    t.integer "preseizure_id",            limit: 4
    t.integer "pre_assignment_export_id", limit: 4
  end

  create_table "pack_report_preseizures_remote_files", force: :cascade do |t|
    t.integer "remote_file_id",            limit: 4
    t.integer "pack_report_preseizure_id", limit: 4
  end

  create_table "pack_reports", force: :cascade do |t|
    t.string   "mongo_id",                 limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",                     limit: 255
    t.string   "type",                     limit: 255
    t.boolean  "is_delivered",                           default: false, null: false
    t.datetime "delivery_tried_at"
    t.text     "delivery_message",         limit: 65535
    t.boolean  "is_locked",                              default: false, null: false
    t.integer  "organization_id",          limit: 4
    t.string   "organization_id_mongo_id", limit: 255
    t.integer  "user_id",                  limit: 4
    t.string   "user_id_mongo_id",         limit: 255
    t.integer  "pack_id",                  limit: 4
    t.string   "pack_id_mongo_id",         limit: 255
    t.integer  "document_id",              limit: 4
    t.string   "document_id_mongo_id",     limit: 255
    t.string   "is_delivered_to",          limit: 255,   default: ""
  end

  add_index "pack_reports", ["document_id"], name: "document_id", using: :btree
  add_index "pack_reports", ["document_id_mongo_id"], name: "document_id_mongo_id", using: :btree
  add_index "pack_reports", ["is_delivered_to"], name: "index_pack_reports_on_is_delivered_to", using: :btree
  add_index "pack_reports", ["mongo_id"], name: "index_pack_reports_on_mongo_id", using: :btree
  add_index "pack_reports", ["organization_id"], name: "organization_id", using: :btree
  add_index "pack_reports", ["organization_id_mongo_id"], name: "organization_id_mongo_id", using: :btree
  add_index "pack_reports", ["pack_id"], name: "pack_id", using: :btree
  add_index "pack_reports", ["pack_id_mongo_id"], name: "pack_id_mongo_id", using: :btree
  add_index "pack_reports", ["user_id"], name: "user_id", using: :btree
  add_index "pack_reports", ["user_id_mongo_id"], name: "user_id_mongo_id", using: :btree

  create_table "packs", force: :cascade do |t|
    t.string   "mongo_id",                 limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "locked_at"
    t.datetime "locked_until"
    t.string   "name",                     limit: 255
    t.string   "original_document_id",     limit: 255
    t.string   "content_url",              limit: 255
    t.text     "content_historic",         limit: 65535
    t.text     "tags",                     limit: 65535
    t.integer  "pages_count",              limit: 4,     default: 0,     null: false
    t.integer  "scanned_pages_count",      limit: 4,     default: 0,     null: false
    t.boolean  "is_update_notified",                     default: true,  null: false
    t.boolean  "is_fully_processed",                     default: true,  null: false
    t.boolean  "is_indexing",                            default: false, null: false
    t.datetime "remote_files_updated_at"
    t.integer  "owner_id",                 limit: 4
    t.string   "owner_id_mongo_id",        limit: 255
    t.integer  "organization_id",          limit: 4
    t.string   "organization_id_mongo_id", limit: 255
    t.string   "content_file_name",        limit: 255
    t.string   "content_content_type",     limit: 255
    t.integer  "content_file_size",        limit: 4
    t.datetime "content_updated_at"
    t.string   "content_fingerprint",      limit: 255
  end

  add_index "packs", ["mongo_id"], name: "index_packs_on_mongo_id", using: :btree
  add_index "packs", ["organization_id"], name: "organization_id", using: :btree
  add_index "packs", ["organization_id_mongo_id"], name: "organization_id_mongo_id", using: :btree
  add_index "packs", ["owner_id"], name: "owner_id", using: :btree
  add_index "packs", ["owner_id_mongo_id"], name: "owner_id_mongo_id", using: :btree

  create_table "paper_processes", force: :cascade do |t|
    t.string   "mongo_id",                    limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "type",                        limit: 255
    t.string   "tracking_number",             limit: 255
    t.string   "customer_code",               limit: 255
    t.integer  "journals_count",              limit: 4
    t.integer  "periods_count",               limit: 4
    t.integer  "letter_type",                 limit: 4
    t.string   "pack_name",                   limit: 255
    t.integer  "organization_id",             limit: 4
    t.string   "organization_id_mongo_id",    limit: 255
    t.integer  "user_id",                     limit: 4
    t.string   "user_id_mongo_id",            limit: 255
    t.integer  "period_document_id",          limit: 4
    t.string   "period_document_id_mongo_id", limit: 255
    t.integer  "order_id",                    limit: 4
  end

  add_index "paper_processes", ["mongo_id"], name: "index_paper_processes_on_mongo_id", using: :btree
  add_index "paper_processes", ["order_id"], name: "index_paper_processes_on_order_id", using: :btree
  add_index "paper_processes", ["organization_id"], name: "organization_id", using: :btree
  add_index "paper_processes", ["organization_id_mongo_id"], name: "organization_id_mongo_id", using: :btree
  add_index "paper_processes", ["period_document_id"], name: "period_document_id", using: :btree
  add_index "paper_processes", ["period_document_id_mongo_id"], name: "period_document_id_mongo_id", using: :btree
  add_index "paper_processes", ["user_id"], name: "user_id", using: :btree
  add_index "paper_processes", ["user_id_mongo_id"], name: "user_id_mongo_id", using: :btree

  create_table "period_billings", force: :cascade do |t|
    t.string  "mongo_id",                        limit: 255
    t.integer "order",                           limit: 4,   default: 1, null: false
    t.integer "amount_in_cents_wo_vat",          limit: 4,   default: 0, null: false
    t.integer "excesses_amount_in_cents_wo_vat", limit: 4,   default: 0, null: false
    t.integer "scanned_pieces",                  limit: 4,   default: 0, null: false
    t.integer "scanned_sheets",                  limit: 4,   default: 0, null: false
    t.integer "scanned_pages",                   limit: 4,   default: 0, null: false
    t.integer "dematbox_scanned_pieces",         limit: 4,   default: 0, null: false
    t.integer "dematbox_scanned_pages",          limit: 4,   default: 0, null: false
    t.integer "uploaded_pieces",                 limit: 4,   default: 0, null: false
    t.integer "uploaded_pages",                  limit: 4,   default: 0, null: false
    t.integer "retrieved_pieces",                limit: 4,   default: 0, null: false
    t.integer "retrieved_pages",                 limit: 4,   default: 0, null: false
    t.integer "preseizure_pieces",               limit: 4,   default: 0, null: false
    t.integer "expense_pieces",                  limit: 4,   default: 0, null: false
    t.integer "paperclips",                      limit: 4,   default: 0, null: false
    t.integer "oversized",                       limit: 4,   default: 0, null: false
    t.integer "excess_sheets",                   limit: 4,   default: 0, null: false
    t.integer "excess_uploaded_pages",           limit: 4,   default: 0, null: false
    t.integer "excess_dematbox_scanned_pages",   limit: 4,   default: 0, null: false
    t.integer "excess_compta_pieces",            limit: 4,   default: 0, null: false
    t.integer "period_id",                       limit: 4
    t.string  "period_id_mongo_id",              limit: 255
  end

  add_index "period_billings", ["mongo_id"], name: "index_period_billings_on_mongo_id", using: :btree
  add_index "period_billings", ["period_id"], name: "period_id", using: :btree
  add_index "period_billings", ["period_id_mongo_id"], name: "period_id_mongo_id", using: :btree

  create_table "period_deliveries", force: :cascade do |t|
    t.string   "mongo_id",           limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "state",              limit: 255, default: "wait", null: false
    t.integer  "period_id",          limit: 4
    t.string   "period_id_mongo_id", limit: 255
  end

  add_index "period_deliveries", ["mongo_id"], name: "index_period_deliveries_on_mongo_id", using: :btree
  add_index "period_deliveries", ["period_id"], name: "period_id", using: :btree
  add_index "period_deliveries", ["period_id_mongo_id"], name: "period_id_mongo_id", using: :btree

  create_table "period_documents", force: :cascade do |t|
    t.string   "mongo_id",                 limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",                     limit: 255, default: "",   null: false
    t.integer  "pieces",                   limit: 4,   default: 0,    null: false
    t.integer  "pages",                    limit: 4,   default: 0,    null: false
    t.integer  "scanned_pieces",           limit: 4,   default: 0,    null: false
    t.integer  "scanned_sheets",           limit: 4,   default: 0,    null: false
    t.integer  "scanned_pages",            limit: 4,   default: 0,    null: false
    t.integer  "dematbox_scanned_pieces",  limit: 4,   default: 0,    null: false
    t.integer  "dematbox_scanned_pages",   limit: 4,   default: 0,    null: false
    t.integer  "uploaded_pieces",          limit: 4,   default: 0,    null: false
    t.integer  "uploaded_pages",           limit: 4,   default: 0,    null: false
    t.integer  "retrieved_pieces",         limit: 4,   default: 0,    null: false
    t.integer  "retrieved_pages",          limit: 4,   default: 0,    null: false
    t.integer  "paperclips",               limit: 4,   default: 0,    null: false
    t.integer  "oversized",                limit: 4,   default: 0,    null: false
    t.boolean  "is_shared",                            default: true, null: false
    t.datetime "scanned_at"
    t.string   "scanned_by",               limit: 255
    t.integer  "organization_id",          limit: 4
    t.string   "organization_id_mongo_id", limit: 255
    t.integer  "user_id",                  limit: 4
    t.string   "user_id_mongo_id",         limit: 255
    t.integer  "period_id",                limit: 4
    t.string   "period_id_mongo_id",       limit: 255
    t.integer  "pack_id",                  limit: 4
    t.string   "pack_id_mongo_id",         limit: 255
  end

  add_index "period_documents", ["mongo_id"], name: "index_period_documents_on_mongo_id", using: :btree
  add_index "period_documents", ["organization_id"], name: "organization_id", using: :btree
  add_index "period_documents", ["organization_id_mongo_id"], name: "organization_id_mongo_id", using: :btree
  add_index "period_documents", ["pack_id"], name: "pack_id", using: :btree
  add_index "period_documents", ["pack_id_mongo_id"], name: "pack_id_mongo_id", using: :btree
  add_index "period_documents", ["period_id"], name: "period_id", using: :btree
  add_index "period_documents", ["period_id_mongo_id"], name: "period_id_mongo_id", using: :btree
  add_index "period_documents", ["user_id"], name: "user_id", using: :btree
  add_index "period_documents", ["user_id_mongo_id"], name: "user_id_mongo_id", using: :btree

  create_table "periods", force: :cascade do |t|
    t.string   "mongo_id",                                 limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "locked_at"
    t.datetime "locked_until"
    t.date     "start_date"
    t.date     "end_date"
    t.integer  "duration",                                 limit: 4,     default: 1,      null: false
    t.boolean  "is_centralized",                                         default: true,   null: false
    t.integer  "price_in_cents_wo_vat",                    limit: 4,     default: 0,      null: false
    t.integer  "products_price_in_cents_wo_vat",           limit: 4,     default: 0,      null: false
    t.integer  "recurrent_products_price_in_cents_wo_vat", limit: 4,     default: 0,      null: false
    t.integer  "ponctual_products_price_in_cents_wo_vat",  limit: 4,     default: 0,      null: false
    t.integer  "orders_price_in_cents_wo_vat",             limit: 4,     default: 0,      null: false
    t.integer  "excesses_price_in_cents_wo_vat",           limit: 4,     default: 0,      null: false
    t.float    "tva_ratio",                                limit: 24,    default: 1.2,    null: false
    t.integer  "max_sheets_authorized",                    limit: 4,     default: 100,    null: false
    t.integer  "max_upload_pages_authorized",              limit: 4,     default: 200,    null: false
    t.integer  "max_dematbox_scan_pages_authorized",       limit: 4,     default: 200,    null: false
    t.integer  "max_preseizure_pieces_authorized",         limit: 4,     default: 100,    null: false
    t.integer  "max_expense_pieces_authorized",            limit: 4,     default: 100,    null: false
    t.integer  "max_paperclips_authorized",                limit: 4,     default: 0,      null: false
    t.integer  "max_oversized_authorized",                 limit: 4,     default: 0,      null: false
    t.integer  "unit_price_of_excess_sheet",               limit: 4,     default: 12,     null: false
    t.integer  "unit_price_of_excess_upload",              limit: 4,     default: 6,      null: false
    t.integer  "unit_price_of_excess_dematbox_scan",       limit: 4,     default: 6,      null: false
    t.integer  "unit_price_of_excess_preseizure",          limit: 4,     default: 12,     null: false
    t.integer  "unit_price_of_excess_expense",             limit: 4,     default: 12,     null: false
    t.integer  "unit_price_of_excess_paperclips",          limit: 4,     default: 20,     null: false
    t.integer  "unit_price_of_excess_oversized",           limit: 4,     default: 100,    null: false
    t.text     "documents_name_tags",                      limit: 65535
    t.integer  "pieces",                                   limit: 4,     default: 0,      null: false
    t.integer  "pages",                                    limit: 4,     default: 0,      null: false
    t.integer  "scanned_pieces",                           limit: 4,     default: 0,      null: false
    t.integer  "scanned_sheets",                           limit: 4,     default: 0,      null: false
    t.integer  "scanned_pages",                            limit: 4,     default: 0,      null: false
    t.integer  "dematbox_scanned_pieces",                  limit: 4,     default: 0,      null: false
    t.integer  "dematbox_scanned_pages",                   limit: 4,     default: 0,      null: false
    t.integer  "uploaded_pieces",                          limit: 4,     default: 0,      null: false
    t.integer  "uploaded_pages",                           limit: 4,     default: 0,      null: false
    t.integer  "retrieved_pieces",                         limit: 4,     default: 0,      null: false
    t.integer  "retrieved_pages",                          limit: 4,     default: 0,      null: false
    t.integer  "paperclips",                               limit: 4,     default: 0,      null: false
    t.integer  "oversized",                                limit: 4,     default: 0,      null: false
    t.integer  "preseizure_pieces",                        limit: 4,     default: 0,      null: false
    t.integer  "expense_pieces",                           limit: 4,     default: 0,      null: false
    t.integer  "user_id",                                  limit: 4
    t.string   "user_id_mongo_id",                         limit: 255
    t.integer  "organization_id",                          limit: 4
    t.string   "organization_id_mongo_id",                 limit: 255
    t.integer  "subscription_id",                          limit: 4
    t.string   "subscription_id_mongo_id",                 limit: 255
    t.datetime "delivery_created_at"
    t.datetime "delivery_updated_at"
    t.string   "delivery_state",                           limit: 255,   default: "wait", null: false
    t.boolean  "is_paper_quota_reached_notified",                        default: false
  end

  add_index "periods", ["mongo_id"], name: "index_periods_on_mongo_id", using: :btree
  add_index "periods", ["organization_id"], name: "organization_id", using: :btree
  add_index "periods", ["organization_id_mongo_id"], name: "organization_id_mongo_id", using: :btree
  add_index "periods", ["subscription_id"], name: "subscription_id", using: :btree
  add_index "periods", ["subscription_id_mongo_id"], name: "subscription_id_mongo_id", using: :btree
  add_index "periods", ["user_id"], name: "user_id", using: :btree
  add_index "periods", ["user_id_mongo_id"], name: "user_id_mongo_id", using: :btree

  create_table "pre_assignment_deliveries", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "pack_name",       limit: 255
    t.string   "state",           limit: 255
    t.boolean  "is_auto"
    t.integer  "total_item",      limit: 4
    t.date     "grouped_date"
    t.text     "data_to_deliver", limit: 4294967295
    t.text     "error_message",   limit: 65535
    t.boolean  "is_to_notify"
    t.boolean  "is_notified"
    t.datetime "notified_at"
    t.integer  "organization_id", limit: 4
    t.integer  "report_id",       limit: 4
    t.integer  "user_id",         limit: 4
    t.string   "software_id",     limit: 255
    t.string   "deliver_to",      limit: 255,        default: "ibiza"
  end

  add_index "pre_assignment_deliveries", ["deliver_to"], name: "index_pre_assignment_deliveries_on_deliver_to", using: :btree
  add_index "pre_assignment_deliveries", ["is_auto"], name: "index_pre_assignment_deliveries_on_is_auto", using: :btree
  add_index "pre_assignment_deliveries", ["is_notified"], name: "index_pre_assignment_deliveries_on_is_notified", using: :btree
  add_index "pre_assignment_deliveries", ["is_to_notify"], name: "index_pre_assignment_deliveries_on_is_to_notify", using: :btree
  add_index "pre_assignment_deliveries", ["organization_id"], name: "organization_id", using: :btree
  add_index "pre_assignment_deliveries", ["report_id"], name: "report_id", using: :btree
  add_index "pre_assignment_deliveries", ["state"], name: "index_pre_assignment_deliveries_on_state", using: :btree
  add_index "pre_assignment_deliveries", ["user_id"], name: "user_id", using: :btree

  create_table "pre_assignment_exports", force: :cascade do |t|
    t.string   "state",           limit: 255
    t.string   "pack_name",       limit: 255
    t.string   "for",             limit: 255
    t.string   "file_name",       limit: 255
    t.integer  "total_item",      limit: 4,     default: 0
    t.text     "error_message",   limit: 65535
    t.boolean  "is_notified",                   default: false
    t.datetime "notified_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id",         limit: 4
    t.integer  "organization_id", limit: 4
    t.integer  "report_id",       limit: 4
  end

  add_index "pre_assignment_exports", ["for"], name: "index_pre_assignment_exports_on_for", using: :btree
  add_index "pre_assignment_exports", ["pack_name"], name: "index_pre_assignment_exports_on_pack_name", using: :btree
  add_index "pre_assignment_exports", ["state"], name: "index_pre_assignment_exports_on_state", using: :btree

  create_table "product_option_orders", force: :cascade do |t|
    t.string  "mongo_id",                       limit: 255
    t.string  "name",                           limit: 255
    t.string  "title",                          limit: 255
    t.string  "group_title",                    limit: 255
    t.string  "description",                    limit: 255
    t.float   "price_in_cents_wo_vat",          limit: 24
    t.integer "group_position",                 limit: 4
    t.integer "position",                       limit: 4
    t.integer "duration",                       limit: 4
    t.integer "quantity",                       limit: 4
    t.boolean "is_an_extra"
    t.boolean "is_to_be_disabled"
    t.integer "product_optionable_id",          limit: 4
    t.string  "product_optionable_type",        limit: 255
    t.string  "product_optionable_id_mongo_id", limit: 255
  end

  add_index "product_option_orders", ["mongo_id"], name: "index_product_option_orders_on_mongo_id", using: :btree
  add_index "product_option_orders", ["product_optionable_id"], name: "product_optionable_id", using: :btree
  add_index "product_option_orders", ["product_optionable_id_mongo_id"], name: "product_optionable_id_mongo_id", using: :btree
  add_index "product_option_orders", ["product_optionable_type"], name: "product_optionable_type", using: :btree

  create_table "reminder_emails", force: :cascade do |t|
    t.string   "mongo_id",                 limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",                     limit: 255
    t.string   "subject",                  limit: 255
    t.text     "content",                  limit: 65535
    t.integer  "delivery_day",             limit: 4,     default: 1, null: false
    t.integer  "period",                   limit: 4,     default: 1, null: false
    t.datetime "delivered_at"
    t.text     "delivered_user_ids",       limit: 65535
    t.text     "processed_user_ids",       limit: 65535
    t.integer  "organization_id",          limit: 4
    t.string   "organization_id_mongo_id", limit: 255
  end

  add_index "reminder_emails", ["mongo_id"], name: "index_reminder_emails_on_mongo_id", using: :btree
  add_index "reminder_emails", ["organization_id"], name: "organization_id", using: :btree
  add_index "reminder_emails", ["organization_id_mongo_id"], name: "organization_id_mongo_id", using: :btree

  create_table "remote_files", force: :cascade do |t|
    t.string   "mongo_id",                 limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remotable_type",           limit: 255
    t.string   "path",                     limit: 255,        default: "",        null: false
    t.string   "temp_path",                limit: 255,        default: "",        null: false
    t.string   "extension",                limit: 255,        default: ".pdf",    null: false
    t.integer  "size",                     limit: 4
    t.datetime "tried_at"
    t.string   "state",                    limit: 255,        default: "waiting", null: false
    t.string   "service_name",             limit: 255
    t.text     "error_message",            limit: 4294967295
    t.integer  "tried_count",              limit: 4,          default: 0,         null: false
    t.integer  "user_id",                  limit: 4
    t.string   "user_id_mongo_id",         limit: 255
    t.integer  "pack_id",                  limit: 4
    t.string   "pack_id_mongo_id",         limit: 255
    t.integer  "organization_id",          limit: 4
    t.string   "organization_id_mongo_id", limit: 255
    t.integer  "group_id",                 limit: 4
    t.string   "group_id_mongo_id",        limit: 255
    t.integer  "remotable_id",             limit: 4
    t.string   "remotable_id_mongo_id",    limit: 255
  end

  add_index "remote_files", ["extension"], name: "index_remote_files_on_extension", using: :btree
  add_index "remote_files", ["group_id"], name: "group_id", using: :btree
  add_index "remote_files", ["group_id_mongo_id"], name: "group_id_mongo_id", using: :btree
  add_index "remote_files", ["mongo_id"], name: "index_remote_files_on_mongo_id", using: :btree
  add_index "remote_files", ["organization_id"], name: "organization_id", using: :btree
  add_index "remote_files", ["organization_id_mongo_id"], name: "organization_id_mongo_id", using: :btree
  add_index "remote_files", ["pack_id"], name: "pack_id", using: :btree
  add_index "remote_files", ["pack_id_mongo_id"], name: "pack_id_mongo_id", using: :btree
  add_index "remote_files", ["remotable_id"], name: "remotable_id", using: :btree
  add_index "remote_files", ["remotable_id_mongo_id"], name: "remotable_id_mongo_id", using: :btree
  add_index "remote_files", ["service_name"], name: "index_remote_files_on_service_name", using: :btree
  add_index "remote_files", ["state"], name: "index_remote_files_on_state", using: :btree
  add_index "remote_files", ["tried_count"], name: "index_remote_files_on_tried_count", using: :btree
  add_index "remote_files", ["user_id"], name: "user_id", using: :btree
  add_index "remote_files", ["user_id_mongo_id"], name: "user_id_mongo_id", using: :btree

  create_table "retrieved_data", force: :cascade do |t|
    t.text     "state",                    limit: 65535
    t.text     "error_message",            limit: 16777215
    t.text     "processed_connection_ids", limit: 65535
    t.datetime "content_updated_at"
    t.integer  "content_file_size",        limit: 4
    t.string   "content_content_type",     limit: 255
    t.string   "content_file_name",        limit: 255
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
    t.integer  "user_id",                  limit: 4
  end

  add_index "retrieved_data", ["user_id"], name: "fk_rails_c47071c4c1", using: :btree

  create_table "retrievers", force: :cascade do |t|
    t.integer  "budgea_id",                  limit: 4
    t.string   "fiduceo_id",                 limit: 255
    t.string   "fiduceo_transaction_id",     limit: 255
    t.string   "name",                       limit: 255
    t.text     "additionnal_fields",         limit: 65535
    t.string   "journal_name",               limit: 255
    t.datetime "sync_at"
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
    t.integer  "connector_id",               limit: 4
    t.string   "service_name",               limit: 255
    t.text     "capabilities",               limit: 65535
    t.text     "encrypted_param1",           limit: 65535
    t.text     "encrypted_param2",           limit: 65535
    t.text     "encrypted_param3",           limit: 65535
    t.text     "encrypted_param4",           limit: 65535
    t.text     "encrypted_param5",           limit: 65535
    t.text     "encrypted_answers",          limit: 65535
  end
  add_index "retrievers", ["connector_id"], name: "index_retrievers_on_connector_id", using: :btree
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

  create_table "sandbox_operations", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
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

  create_table "scanning_providers", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "mongo_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "name"
    t.string "code"
    t.boolean "is_default", default: false, null: false
    t.index ["mongo_id"], name: "index_scanning_providers_on_mongo_id"
  end

  create_table "settings", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
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

  create_table "softwares_settings", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
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

  create_table "statistics", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "information"
    t.float "counter", limit: 53
  end

  create_table "subscription_options", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "mongo_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "name"
    t.integer "price_in_cents_wo_vat", default: 0, null: false
    t.integer "position", default: 1, null: false
    t.integer "period_duration", default: 1, null: false
    t.index ["mongo_id"], name: "index_subscription_options_on_mongo_id"
  end

  create_table "subscription_options_subscriptions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
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

  create_table "subscriptions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
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
    t.string   "name",             limit: 191
    t.decimal  "amount",                       precision: 10, scale: 2
    t.datetime "created_at",                                            null: false
    t.datetime "updated_at",                                            null: false
    t.integer  "temp_document_id", limit: 4
  end

  add_index "temp_document_metadata", ["temp_document_id"], name: "index_temp_document_metadata_on_temp_document_id", using: :btree

  create_table "temp_documents", force: :cascade do |t|
    t.string   "mongo_id",                       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "original_file_name",             limit: 255
    t.boolean  "is_thumb_generated",                                default: false,     null: false
    t.integer  "pages_number",                   limit: 4
    t.integer  "position",                       limit: 4
    t.boolean  "is_an_original",                                    default: true,      null: false
    t.boolean  "is_a_cover",                                        default: false,     null: false
    t.boolean  "is_ocr_layer_applied"
    t.string   "delivered_by",                   limit: 255
    t.string   "delivery_type",                  limit: 255
    t.string   "dematbox_text",                  limit: 255
    t.string   "dematbox_is_notified",           limit: 255
    t.string   "dematbox_notified_at",           limit: 255
    t.text     "retrieved_metadata",             limit: 4294967295
    t.string   "retriever_service_name",         limit: 255
    t.string   "retriever_name",                 limit: 255
    t.boolean  "is_corruption_notified"
    t.datetime "corruption_notified_at"
    t.string   "state",                          limit: 255,        default: "created", null: false
    t.datetime "stated_at"
    t.boolean  "is_locked",                                         default: false,     null: false
    t.text     "scan_bundling_document_ids",     limit: 65535
    t.string   "content_file_name",              limit: 255
    t.string   "content_content_type",           limit: 255
    t.integer  "content_file_size",              limit: 4
    t.datetime "content_updated_at"
    t.string   "content_fingerprint",            limit: 255
    t.string   "original_fingerprint",           limit: 255
    t.string   "cloud_content_file_name",        limit: 255
    t.string   "cloud_content_content_type",     limit: 255
    t.integer  "cloud_content_file_size",        limit: 4
    t.datetime "cloud_content_updated_at"
    t.string   "cloud_content_fingerprint",      limit: 255
    t.string   "raw_content_file_name",          limit: 255
    t.string   "raw_content_content_type",       limit: 255
    t.integer  "raw_content_file_size",          limit: 4
    t.datetime "raw_content_updated_at"
    t.string   "raw_content_fingerprint",        limit: 255
    t.string   "cloud_raw_content_file_name",    limit: 255
    t.string   "cloud_raw_content_content_type", limit: 255
    t.integer  "cloud_raw_content_file_size",    limit: 4
    t.datetime "cloud_raw_content_updated_at"
    t.string   "cloud_raw_content_fingerprint",  limit: 255
    t.integer  "organization_id",                limit: 4
    t.string   "organization_id_mongo_id",       limit: 255
    t.integer  "user_id",                        limit: 4
    t.string   "user_id_mongo_id",               limit: 255
    t.integer  "temp_pack_id",                   limit: 4
    t.string   "temp_pack_id_mongo_id",          limit: 255
    t.integer  "document_delivery_id",           limit: 4
    t.string   "document_delivery_id_mongo_id",  limit: 255
    t.integer  "fiduceo_retriever_id",           limit: 4
    t.string   "fiduceo_retriever_id_mongo_id",  limit: 255
    t.integer  "email_id",                       limit: 4
    t.string   "email_id_mongo_id",              limit: 255
    t.integer  "piece_id",                       limit: 4
    t.string   "piece_id_mongo_id",              limit: 255
    t.string   "dematbox_doc_id",                limit: 255
    t.string   "dematbox_box_id",                limit: 255
    t.string   "dematbox_service_id",            limit: 255
    t.string   "api_id",                         limit: 255
    t.string   "api_name",                       limit: 255
    t.text     "metadata",                       limit: 16777215
    t.integer  "retriever_id",                   limit: 4
    t.integer  "ibizabox_folder_id",             limit: 4
    t.integer  "analytic_reference_id",          limit: 4
  end

  add_index "temp_documents", ["analytic_reference_id"], name: "index_temp_documents_on_analytic_reference_id", using: :btree
  add_index "temp_documents", ["api_id"], name: "index_temp_documents_on_api_id", using: :btree
  add_index "temp_documents", ["delivery_type"], name: "index_temp_documents_on_delivery_type", using: :btree
  add_index "temp_documents", ["document_delivery_id"], name: "document_delivery_id", using: :btree
  add_index "temp_documents", ["document_delivery_id_mongo_id"], name: "document_delivery_id_mongo_id", using: :btree
  add_index "temp_documents", ["email_id"], name: "email_id", using: :btree
  add_index "temp_documents", ["email_id_mongo_id"], name: "email_id_mongo_id", using: :btree
  add_index "temp_documents", ["fiduceo_retriever_id"], name: "fiduceo_retriever_id", using: :btree
  add_index "temp_documents", ["fiduceo_retriever_id_mongo_id"], name: "fiduceo_retriever_id_mongo_id", using: :btree
  add_index "temp_documents", ["ibizabox_folder_id"], name: "index_temp_documents_on_ibizabox_folder_id", using: :btree
  add_index "temp_documents", ["is_an_original"], name: "index_temp_documents_on_is_an_original", using: :btree
  add_index "temp_documents", ["mongo_id"], name: "index_temp_documents_on_mongo_id", using: :btree
  add_index "temp_documents", ["organization_id"], name: "organization_id", using: :btree
  add_index "temp_documents", ["organization_id_mongo_id"], name: "organization_id_mongo_id", using: :btree
  add_index "temp_documents", ["piece_id"], name: "piece_id", using: :btree
  add_index "temp_documents", ["piece_id_mongo_id"], name: "piece_id_mongo_id", using: :btree
  add_index "temp_documents", ["retriever_id"], name: "index_temp_documents_on_retriever_id", using: :btree
  add_index "temp_documents", ["state"], name: "index_temp_documents_on_state", using: :btree
  add_index "temp_documents", ["temp_pack_id"], name: "temp_pack_id", using: :btree
  add_index "temp_documents", ["temp_pack_id_mongo_id"], name: "temp_pack_id_mongo_id", using: :btree
  add_index "temp_documents", ["user_id"], name: "index_temp_documents_on_user_id", using: :btree
  add_index "temp_documents", ["user_id"], name: "user_id", using: :btree
  add_index "temp_documents", ["user_id_mongo_id"], name: "user_id_mongo_id", using: :btree

  create_table "temp_packs", force: :cascade do |t|
    t.string   "mongo_id",                      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "locked_at"
    t.datetime "locked_until"
    t.string   "name",                          limit: 255
    t.integer  "position_counter",              limit: 4,   default: 0, null: false
    t.integer  "document_not_processed_count",  limit: 4,   default: 0, null: false
    t.integer  "document_bundling_count",       limit: 4,   default: 0, null: false
    t.integer  "document_bundle_needed_count",  limit: 4,   default: 0, null: false
    t.integer  "organization_id",               limit: 4
    t.string   "organization_id_mongo_id",      limit: 255
    t.integer  "user_id",                       limit: 4
    t.string   "user_id_mongo_id",              limit: 255
    t.integer  "document_delivery_id",          limit: 4
    t.string   "document_delivery_id_mongo_id", limit: 255
  end

  add_index "temp_packs", ["document_delivery_id"], name: "document_delivery_id", using: :btree
  add_index "temp_packs", ["document_delivery_id_mongo_id"], name: "document_delivery_id_mongo_id", using: :btree
  add_index "temp_packs", ["mongo_id"], name: "index_temp_packs_on_mongo_id", using: :btree
  add_index "temp_packs", ["organization_id"], name: "organization_id", using: :btree
  add_index "temp_packs", ["organization_id_mongo_id"], name: "organization_id_mongo_id", using: :btree
  add_index "temp_packs", ["user_id"], name: "user_id", using: :btree
  add_index "temp_packs", ["user_id_mongo_id"], name: "user_id_mongo_id", using: :btree

  create_table "user_options", force: :cascade do |t|
    t.string   "mongo_id",                        limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "locked_at"
    t.datetime "locked_until"
    t.boolean  "skip_accounting_plan_finder",                 default: false
  end

  add_index "user_options", ["mongo_id"], name: "index_user_options_on_mongo_id", using: :btree
  add_index "user_options", ["user_id"], name: "user_id", using: :btree
  add_index "user_options", ["user_id_mongo_id"], name: "user_id_mongo_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "mongo_id",                                                       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "email",                                                          limit: 255
    t.string   "encrypted_password",                                             limit: 255,   default: "",                                                 null: false
    t.string   "reset_password_token",                                           limit: 255
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

  create_table "users", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "mongo_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "email"
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                                                  limit: 4,     default: 0,                                                  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",                                             limit: 255
    t.string   "last_sign_in_ip",                                                limit: 255
    t.integer  "failed_attempts",                                                limit: 4,     default: 0,                                                  null: false
    t.string   "unlock_token",                                                   limit: 255
    t.datetime "locked_at"
    t.string   "authentication_token",                                           limit: 255
    t.boolean  "is_admin",                                                                     default: false,                                              null: false
    t.string   "code",                                                           limit: 255
    t.string   "first_name",                                                     limit: 255
    t.string   "last_name",                                                      limit: 255
    t.string   "phone_number",                                                   limit: 255
    t.string   "company",                                                        limit: 255
    t.boolean  "is_prescriber",                                                                default: false,                                              null: false
    t.boolean  "is_fake_prescriber",                                                           default: false,                                              null: false
    t.datetime "inactive_at"
    t.string   "dropbox_delivery_folder",                                        limit: 255,   default: "iDocus_delivery/:code/:year:month/:account_book/", null: false
    t.boolean  "is_dropbox_extended_authorized",                                               default: false,                                              null: false
    t.boolean  "is_centralized",                                                               default: true,                                               null: false
    t.boolean  "is_operator"
    t.string   "knowings_code",                                                  limit: 255
    t.integer  "knowings_visibility",                                            limit: 4,     default: 0,                                                  null: false
    t.boolean  "is_disabled",                                                                  default: false,                                              null: false
    t.string   "stamp_name",                                                     limit: 255,   default: ":code :account_book :period :piece_num",           null: false
    t.boolean  "is_stamp_background_filled",                                                   default: false,                                              null: false
    t.boolean  "is_access_by_token_active",                                                    default: true,                                               null: false
    t.boolean  "is_dematbox_authorized",                                                       default: false,                                              null: false
    t.datetime "return_label_generated_at"
    t.string   "ibiza_id",                                                       limit: 255
    t.boolean  "is_fiduceo_authorized",                                                        default: false,                                              null: false
    t.string   "email_code",                                                     limit: 255
    t.integer  "authd_prev_period",                                              limit: 4,     default: 1,                                                  null: false
    t.integer  "auth_prev_period_until_day",                                     limit: 4,     default: 11,                                                 null: false
    t.integer  "auth_prev_period_until_month",                                   limit: 4,     default: 0,                                                  null: false
    t.string   "current_configuration_step",                                     limit: 255
    t.string   "last_configuration_step",                                        limit: 255
    t.datetime "organization_rights_created_at"
    t.datetime "organization_rights_updated_at"
    t.boolean  "organization_rights_is_groups_management_authorized",                          default: true,                                               null: false
    t.boolean  "organization_rights_is_collaborators_management_authorized",                   default: false,                                              null: false
    t.boolean  "organization_rights_is_customers_management_authorized",                       default: true,                                               null: false
    t.boolean  "organization_rights_is_journals_management_authorized",                        default: true,                                               null: false
    t.boolean  "organization_rights_is_customer_journals_management_authorized",               default: true,                                               null: false
    t.integer  "organization_id",                                                limit: 4
    t.string   "organization_id_mongo_id",                                       limit: 255
    t.integer  "parent_id",                                                      limit: 4
    t.string   "parent_id_mongo_id",                                             limit: 255
    t.integer  "scanning_provider_id",                                           limit: 4
    t.string   "scanning_provider_id_mongo_id",                                  limit: 255
    t.string   "fiduceo_id",                                                     limit: 255
    t.text     "group_ids",                                                      limit: 65535
    t.boolean  "is_guest",                                                                     default: false
    t.datetime "news_read_at"
    t.string   "mcf_storage",                                                    limit: 255
    t.integer  "manager_id",                                                     limit: 4
  end

  add_index "users", ["manager_id"], name: "index_users_on_manager_id", using: :btree
  add_index "users", ["mongo_id"], name: "index_users_on_mongo_id", using: :btree
  add_index "users", ["organization_id"], name: "organization_id", using: :btree
  add_index "users", ["organization_id_mongo_id"], name: "organization_id_mongo_id", using: :btree
  add_index "users", ["parent_id"], name: "parent_id", using: :btree
  add_index "users", ["parent_id_mongo_id"], name: "parent_id_mongo_id", using: :btree
  add_index "users", ["scanning_provider_id"], name: "scanning_provider_id", using: :btree
  add_index "users", ["scanning_provider_id_mongo_id"], name: "scanning_provider_id_mongo_id", using: :btree

  add_foreign_key "budgea_accounts", "users"
  add_foreign_key "debit_mandates", "organizations"
  add_foreign_key "notifications", "users"
  add_foreign_key "retrieved_data", "users"
end
