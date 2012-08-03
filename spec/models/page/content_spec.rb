require 'spec_helper'

describe Page::Content do

  # validations
  it { should validate_presence_of( :title)}
  it { should validate_presence_of( :text) }
  it { should validate_presence_of( :tag) }
  
  # fields
  it { should have_field( :model).of_type(Integer).with_default_value(0) }
  it { should have_field( :position).of_type(Integer).with_default_value(1) }
  it { should have_field( :is_invisible).of_type(Boolean).with_default_value(false) }
  it { should have_field( :tag).of_type(String).with_default_value('infos') }
  
  # association
  it { should be_embedded_in( :page).of_type(Page).inverse_of(contents) }
  
end
