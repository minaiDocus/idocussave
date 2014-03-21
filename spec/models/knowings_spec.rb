require 'spec_helper'

describe Knowings do

  before :each do
    @knowings = FactoryGirl.create(:knowings)
  end

  it 'should be created successfully' do
    @knowings.should be_persisted
  end

  describe 'states' do
    describe ':not_performed' do
      it 'should be an initial state' do
        expect(@knowings.state).to eq('not_performed')
      end

      it 'should change to :verifying on :verify' do
        @knowings.stub(process_verification: true)
        @knowings.verify_configuration
        expect(@knowings.state).to eq('verifying')
      end

      it 'should change to :invalid on :verify' do
        @knowings.client.stub(verify: false)
        @knowings.verify_configuration
        expect(@knowings.state).to eq('invalid')
      end

      it 'should change to :valid on :verify' do
        @knowings.client.stub(verify: true)
        @knowings.verify_configuration
        expect(@knowings.state).to eq('valid')
      end

      it 'should not be configured' do
        expect(@knowings.is_configured?).to be_false
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
        expect(@knowings.is_configured?).to be_false
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
        expect(@knowings.is_configured?).to be_true
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
        expect(@knowings.is_configured?).to be_false
      end
    end
  end

  describe 'sync' do
    before(:each) do
      @remote_file = RemoteFile.new
      @remote_file.stub(local_name: 'file.zip')
      @remote_file.stub(sending!: true)
      @remote_file.stub(synced!: true)
      @remote_file.stub(not_synced!: true)
    end

    it 'should send file successfully' do
      @remote_file.should_receive(:synced!)
      @knowings.client.stub(put: 201)
      @knowings.sync([@remote_file], Rails.logger)
    end

    it 'should failed to upload file' do
      @remote_file.should_receive(:not_synced!)
      @knowings.client.stub(put: 'unauthorized')
      @knowings.sync([@remote_file], Rails.logger)
    end
  end
end
