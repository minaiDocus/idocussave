require 'spec_helper'

describe Page::Image do

  # validation
  it { should validate_presence_of( :name)}
 
  # fields
  it { should have_field( :is_invisible).of_type(Boolean).with_default_value_of(false) }
  it { should have_field( :position).of_type(Integer).with_default_value_of(f1) }
  
  # association
  it { should be_embedded_in( :page).of_type(Page).inverse_of(images) }

end