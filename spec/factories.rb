FactoryGirl.define do
  factory :page do
    sequence(:position) { |n| n }
    title { |page| "Title #{page.position}" }
    label { |page| page.title }
    tag { |page| page.title }
  end

  factory Page::Image do
    sequence(:name) { |n| "image#{n}" }
  end

  factory Page::Content do
    sequence(:title) { |n| "Title #{n}" }
    tag { |content| content.title }
    sequence(:text) { |n| "Content #{n}" }
  end
end
