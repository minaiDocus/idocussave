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
      expect(DbaSequence.current('order')).to be_nil
    end

    it 'should return 1' do
      DbaSequence.next('order')
      expect(DbaSequence.current('order')).to eq(1)
    end

    it 'should return 2' do
      DbaSequence.next('order')
      DbaSequence.next('order')
      expect(DbaSequence.current('order')).to eq(2)
    end
  end
end
