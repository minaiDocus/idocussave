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
    confirmed_at Time.now
    factory :admin do
      is_admin true
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
    sequence(:position) { |n| n }
  end

   factory ProductGroup do
    sequence(:position) { |n| n+1 }
    title { |group| "group_#{group.position}" }
  end

  factory ProductOption do
    sequence(:price_in_cents_wo_vat) { |n| n*100+100 }
    sequence(:position) { |n| n }
  end

  factory Pack do
    name { "TS0001 TS #{Time.now.strftime('%Y%m')} all" }
    factory :division do
      sequence(:position) { |n| n+1 }
      name { |division| "TS0001_TS_#{Time.now.strftime('%Y%m')}_#{"%03d" % division.position}" }
      sequence(:start) { |n| n+1 }
      sequence(:end) { |n| n+1 }
    end
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
  end

  factory Knowings do
    username 'test@example.com'
    password 'secret'
    url 'http://knowings.fr'
    is_active true
  end
end
