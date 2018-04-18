# -*- encoding : utf-8 -*-
FactoryGirl.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password '123456'
    sequence(:first_name) { |n| "User#{n}" }
    last_name 'TEST'
    company 'TeSt'
    sequence(:code) { |n| is_prescriber ? nil : "TS#{'%04d' % n}" }
    sequence(:email_code) { |n| "%08d" % n }
    factory :admin do
      is_admin true
      is_prescriber true
    end
    factory :prescriber do
      is_prescriber true
    end
    factory :fake_prescriber do
      is_prescriber true
      is_fake_prescriber true
    end
    factory :operator do
      is_operator true
    end
    factory :guest do
      is_guest true
    end
  end

  factory :period_document do
    sequence(:name) { |n| "TS0001 T#{n} #{Time.now.strftime('%Y%m')} all" }
  end

  factory :file_sending_kit do
    sequence(:title) { |n| "Kit #{n}"}
    sequence(:position) { |n| n }
    logo_path "404.png"
    left_logo_path "404.png"
    right_logo_path "404.png"
  end

  factory :organization do
    sequence(:name) { |n| "organization_#{n}" }
    sequence(:code) { |n| "O#{n}" }
  end

  factory :account_book_type do
    sequence(:name) { |n| "J#{n}" }
    description '(description)'
    factory :journal_with_preassignment do
      entry_type 2
      vat_account '123'
      anomaly_account '123'
      account_number '123'
      charge_account '123'
    end
  end

  factory :knowings do
    username 'test@example.com'
    password 'secret'
    url 'http://knowings.fr'
    is_active true
  end

  factory :connector do
    name 'Connecteur de test'
    capabilities ['document', 'bank']
    apis ['budgea']
    active_apis ['budgea']
    budgea_id 40
    fiduceo_ref nil
    combined_fields {{
      'website' => {
        'label'       => 'Type de compte',
        'type'        => 'list',
        'regex'       => nil,
        'budgea_name' => 'website',
        'values' => [
          { 'value' => 'par', 'label' => 'Particuliers' },
          { 'value' => 'pro', 'label' => 'Professionnels' }
        ]
      },
      'login' => {
        'label'       => 'Identifiant',
        'type'        => 'text',
        'regex'       => nil,
        'budgea_name' => 'login'
      },
      'password' => {
        'label'       => 'Mot de passe',
        'type'        => 'password',
        'regex'       => nil,
        'budgea_name' => 'password'
      }
    }}
  end

  factory :pack do
    name 'AC0000 AC 201804 ALL'
    original_document_id "1550058"
    content_url "/account/documents/1550058/download/original?15238"
    pages_count 2
    is_fully_processed true
  end

  factory :piece, :class => Pack::Piece  do
    sequence(:name) { |n| "AC0000 AC 201804 0#{n}" }
    sequence(:number) { |n| "000#{n}" }
    is_a_cover false
    origin "upload"
    sequence(:position) {|n| n }
    content_file_name "test.pdf"
    content_content_type "application/pdf"
    content_file_size 33928
    content_updated_at Time.now
    content_fingerprint "0ac66f058d5eaddbe233670cf214780b"
  end

  factory :period do
    start_date "2018-04-01"
    end_date "2018-04-30"
    duration 1
    subscription_id 1
  end
end
