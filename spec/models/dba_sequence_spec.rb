require 'spec_helper'

describe DbaSequence do
  before(:each) do
    DatabaseCleaner.start
  end

  after(:each) do
    DatabaseCleaner.clean
  end

  describe '.current' do
    it 'should return nil' do
      DbaSequence.current('order').should be_nil
    end

    it 'should return 1' do
      DbaSequence.next('order')
      DbaSequence.current('order').should eq(1)
    end

    it 'should return 2' do
      DbaSequence.next('order')
      DbaSequence.next('order')
      DbaSequence.current('order').should eq(2)
    end
  end
end
