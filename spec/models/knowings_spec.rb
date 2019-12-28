require 'spec_helper'

describe Knowings do

  before :each do
    @knowings = FactoryBot.create(:knowings)
  end

  it 'should be created successfully' do
    expect(@knowings).to be_persisted
  end

  describe 'states' do
    describe ':not_performed' do
      it 'should be an initial state' do
        expect(@knowings.state).to eq('not_performed')
      end

      it 'should change to :verifying on :verify' do
        allow(@knowings).to receive_messages(process_verification: true)
        @knowings.verify_configuration
        expect(@knowings.state).to eq('verifying')
      end

      it 'should change to :invalid on :verify' do
        allow(@knowings.client).to receive_messages(verify: false)
        @knowings.verify_configuration
        expect(@knowings.state).to eq('invalid')
      end

      it 'should change to :valid on :verify' do
        allow(@knowings.client).to receive_messages(verify: true)
        @knowings.verify_configuration
        expect(@knowings.state).to eq('valid')
      end

      it 'should not be configured' do
        expect(@knowings.is_configured?).to be false
      end
    end

    describe ':verifying' do
      before(:each) do
        @knowings.update_attribute(:state, 'verifying')
      end

      it 'should change to :invalid on :invalid' do
        @knowings.invalid_configuration
        expect(@knowings.state).to eq('invalid')
      end

      it 'should change to :valid on :valid' do
        @knowings.valid_configuration
        expect(@knowings.state).to eq('valid')
      end

      it 'should change to :not_performed on :reinit' do
        @knowings.reinit_configuration
        expect(@knowings.state).to eq('not_performed')
      end

      it 'should not be configured' do
        expect(@knowings.is_configured?).to be false
      end
    end

    describe ':valid' do
      before(:each) do
        @knowings.valid_configuration
      end

      it 'should change to :not_performed on :reinit' do
        @knowings.reinit_configuration
        expect(@knowings.state).to eq('not_performed')
      end

      it 'should be configured' do
        expect(@knowings.is_configured?).to be true
      end
    end

    describe ':invalid' do
      before(:each) do
        @knowings.invalid_configuration
      end

      it 'should change to :not_performed on :reinit' do
        @knowings.reinit_configuration
        expect(@knowings.state).to eq('not_performed')
      end

      it 'should not be configured' do
        expect(@knowings.is_configured?).to be false
      end
    end
  end
end
