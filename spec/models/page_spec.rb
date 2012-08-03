require 'spec_helper'

describe Page do
  # validations
  it { should validate_presence_of( :title)}
  it { should validate_presence_of( :label) }
  it { should validate_presence_of( :tag) }
  
  # fields
  it { should have_field(:is_footer).of_type(Boolean).with_default_value_of(false) }
  it { should have_field(:is_invisible).of_type(Boolean).with_default_value_of(false) }
  it { should have_field(:is_for_preview).of_type(Boolean).with_default_value_of(false) }
  
  # associations
  it { should embed_many(:images) }
  it { should embed_many(:contents) }
  it { should embed_many(:page_contents) }
  
end
