# -*- encoding : utf-8 -*-
FactoryGirl.define do
  factory User do
    sequence(:email) { |n| "user#{n}@example.com" }
    password '123456'
    sequence(:first_name) { |n| "User#{n}" }
    last_name 'TEST'
    company 'TeSt'
    sequence(:code) { |n| "TS#{'%04d' % n}" }
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
  end

  factory Product do
    sequence(:title) { |n| "product_title_#{n}" }
    sequence(:position) { |n| n }
  end

   factory ProductGroup do
    sequence(:name) { |n| "product_group_name_#{n}" }
    sequence(:title) { |n| "product_group_title_#{n}" }
    sequence(:position) { |n| n }
  end

  factory ProductOption do
    sequence(:name) { |n| "product_option_name_#{n}" }
    sequence(:title) { |n| "product_option_title_#{n}" }
    sequence(:price_in_cents_wo_vat) { |n| n*100+100 }
    sequence(:position) { |n| n }
  end

  factory PeriodDocument do
    sequence(:name) { |n| "TS0001 T#{n} #{Time.now.strftime('%Y%m')} all" }
  end

  factory FileSendingKit do
    sequence(:title) { |n| "Kit #{n}"}
    sequence(:position) { |n| n }
    logo_path "404.png"
    left_logo_path "404.png"
    right_logo_path "404.png"
  end

  factory Organization do
    sequence(:name) { |n| "organization_#{n}" }
    sequence(:code) { |n| "O#{n}" }
  end

  factory AccountBookType do
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

  factory Knowings do
    username 'test@example.com'
    password 'secret'
    url 'http://knowings.fr'
    is_active true
  end
end
