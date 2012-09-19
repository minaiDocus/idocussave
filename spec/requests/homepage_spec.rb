require 'spec_helper'

describe 'Homepage' do
  before(:each) do
    visit '/'
  end

  it 'should visit / successfully' do
    current_path.should eq(root_path)
  end
end
