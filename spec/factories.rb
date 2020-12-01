# -*- encoding : utf-8 -*-
FactoryBot.define do
  ####################
  # Global factories #
  ####################
    factory :user do
      sequence(:email) { |n| "user#{n}@example.com" }
      password { '1234567' }
      sequence(:first_name) { |n| "User#{n}" }
      last_name { 'Test' }
      company { 'Test' }
      is_prescriber { false }
      sequence(:code) { |n| is_prescriber ? nil : "TS#{'%04d' % n}" }
      sequence(:email_code) { |n| "%08d" % n }
      trait :admin do
        is_admin { true }
        is_prescriber { true }
      end
      trait :prescriber do
        is_prescriber { true }
      end
      trait :fake_prescriber do
        is_prescriber { true }
        is_fake_prescriber { true }
      end
      trait :operator do
        is_operator { true }
      end
      trait :guest do
        is_guest { true }
      end
    end

    factory :organization do
      sequence(:name) { |n| "organization_#{n}" }
      sequence(:code) { |n| "ORG#{n}" }
    end

    factory :account_book_type do
      sequence(:name) { |n| "J#{n}" }
      description { '(description)' }
      trait :journal_with_preassignment do
        entry_type { 2 }
        vat_accounts { '{"0":"123", "8.5":"426", "13": "13256"}' }
        anomaly_account { '123' }
        account_number { '123' }
        charge_account { '123' }
      end
    end

    factory :period do
      start_date { "2018-04-01" }
      end_date { "2018-04-30" }
      duration { 1 }
      subscription_id { 1 }
    end

  #######################
  # Documents factories #
  #######################

    factory :period_document do
      sequence(:name) { |n| "TS0001 T#{n} #{Time.now.strftime('%Y%m')} all" }
      #pack_id { 1 }
      pack
      user_id { 1 }
      organization_id { 1 }
      period_id { 1 }
    end

    factory :temp_pack do
      name { 'AC0000 AC 202001 ALL' }
      position_counter { 1 }
      user_id { 1 }
      organization_id { 1 }
    end

    factory :temp_document do
      sequence(:original_file_name) { |n| "test_document_#{n}" }
      pages_number { 1 }
      sequence(:position) { |n| n }
      is_an_original { true }
      is_a_cover { false }
      delivery_type { 'upload' }
      state { 'ready' }
      original_fingerprint { '---' }
      temp_pack_id { 1 }
      user_id { 1 }
      organization_id { 1 }
      api_name { 'web' }
    end

    factory :pack do
      #name { 'AC0000 AC 201812 ALL' }
      sequence(:name) { |n| "ACC%000 AC 201812 ALL#{n}" }
      original_document_id { "1550058" }
      content_url { "/account/documents/1550058/download/original?15238" }
      pages_count { 2 }
      is_fully_processed { true }
      owner_id { 1 }
      organization_id { 1 }
    end

    factory :report, :class => Pack::Report do
      organization factory: :organization
      user factory: :user
      type { 'FLUX' }
      name { 'AC0000 AC 201812' }
    end

    factory :piece, :class => Pack::Piece  do
      sequence(:name)   { |n| "AC0000 AC 201812 0#{n}" }
      sequence(:number) { |n| "#{'%04d' % n}" }
      is_a_cover { false }
      origin { "upload" }
      sequence(:position) {|n| n + 1 }
      content_file_name { "test.pdf" }
      user_id { 1 }
      pack_id { 1 }
      organization_id { 1 }
    end

    factory :preseizure, :class => Pack::Report::Preseizure do
      piece_id         { 1 }
      user_id          { 1 }
      organization_id  { 1 }
      report_id        { 1 }
      piece_number     { 12345 }
      amount           { 500.25 }
      date             { Time.now }
      position         { 1 }
    end

    factory :account, :class => Pack::Report::Preseizure::Account do
      type { 2 }
      sequence(:number) { |n| "ABCD#{'%04d' % n}" }
      preseizure_id { 1 }
    end

    factory :entry, :class => Pack::Report::Preseizure::Entry do
      type { 1 }
      sequence(:number) { |n| "ABCD#{'%04d' % n}" }
      amount { 500.25 }
      account_id { 1 }
      preseizure_id { 1 }
    end

  ######################
  # Delivery factories #
  ######################

    factory :file_sending_kit do
      sequence(:title) { |n| "Kit #{n}"}
      sequence(:position) { |n| n }
      logo_path { "404.png" }
      left_logo_path { "404.png" }
      right_logo_path { "404.png" }
      organization_id { 1 }
    end

    factory :knowings do
      username { 'test@example.com' }
      password { 'secret' }
      url { 'http://knowings.fr' }
      is_active { true }
      organization_id { 1 }
    end

    factory :ibizabox_folders, class: 'IbizaboxFolder' do
      is_selection_needed { true }
      state { "ready" }
      journal_id { 1 }
      user_id { 1 }
    end

  #####################################
  # Bank operations fetcher factories #
  #####################################

    factory :bank_account do
      sequence(:api_id) { |n| "0#{n}" }
      sequence(:bank_name) { |n| "test_#{n}" }
      sequence(:name) { |n| "test_#{n}" }
      sequence(:number) { |n| "#{'%04d' % n}" }
      type_name { "test" }
      user_id { 1 }
      #retriever_id { 1 }
      retriever
    end

    factory :retriever do
      sequence(:budgea_id) { |n| "#{'%04d' % n}" }
      sequence(:name) { |n| "test_#{n}" }
      sequence(:service_name) { |n| "test_#{n}" }
      sync_at { Time.now }
      state { 'ready' }
      budgea_state { 'successful' }
      journal_name { 'AC' }
      journal factory: :account_book_type
      capabilities { ['bank', 'provider'] }
      budgea_connector_id { 40 }
      user_id { 1 }
    end

    # factory :connector do
    #   name 'Connecteur de test'
    #   capabilities ['document', 'bank']
    #   apis ['budgea']
    #   active_apis ['budgea']
    #   budgea_id 40
    #   fiduceo_ref nil
    #   combined_fields {{
    #     'website' => {
    #       'label'       => 'Type de compte',
    #       'type'        => 'list',
    #       'regex'       => nil,
    #       'budgea_name' => 'website',
    #       'values' => [
    #         { 'value' => 'par', 'label' => 'Particuliers' },
    #         { 'value' => 'pro', 'label' => 'Professionnels' }
    #       ]
    #     },
    #     'login' => {
    #       'label'       => 'Identifiant',
    #       'type'        => 'text',
    #       'regex'       => nil,
    #       'budgea_name' => 'login'
    #     },
    #     'password' => {
    #       'label'       => 'Mot de passe',
    #       'type'        => 'password',
    #       'regex'       => nil,
    #       'budgea_name' => 'password'
    #     }
    #   }}
    # end
end
