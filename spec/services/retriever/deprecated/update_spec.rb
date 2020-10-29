require 'spec_helper'

describe Retriever::Update do
  before(:all) do
    @user = FactoryBot.create :user, code: 'IDO%0001'
    @user.options = UserOptions.create(user_id: @user.id)
    @journal = FactoryBot.create :account_book_type, user_id: @user.id

    VCR.use_cassette('budgea/create_budgea_account') do
      CreateBudgeaAccount.execute(@user)
    end

    @connector = FactoryBot.create :connector
  end

  context 'given a retriever' do
    before(:each) do
      @retriever = Retriever.new
      @retriever.user               = @user
      @retriever.connector          = @connector
      @retriever.journal            = @journal
      @retriever.name               = 'Connecteur de test'
      @retriever.confirm_dyn_params = true
      @retriever.param1 = {
        'name' => 'website',
        'value' => 'par'
      }
      @retriever.param2 = {
        'name' => 'login',
        'value' => 'John Doe'
      }
      @retriever.param3 = {
        'name' => 'password',
        'value' => '1234'
      }
      @retriever.save
      @retriever.success_budgea_connection
      @retriever.reload
    end

    after(:each) do
      @retriever.destroy
    end

    describe 'no changes' do
      it 'should not trigger synchronization' do
        result = Retriever::Update.new(@retriever, name: 'Connecteur de test').execute

        expect(result).to eq true
        expect(@retriever).to be_ready
      end

      it 'should not trigger synchronization' do
        result = Retriever::Update.new(@retriever, 'param1' => { 'name' => 'website', 'value' => 'par' }).execute

        expect(result).to eq true
        expect(@retriever).to be_ready
      end

      it 'should not trigger synchronization' do
        result = Retriever::Update.new(@retriever, name: 'Connecteur de test', 'param1' => { 'name' => 'website', 'value' => 'par' }).execute

        expect(result).to eq true
        expect(@retriever).to be_ready
      end
    end

    describe 'changes name' do
      it 'should not trigger synchronization' do
        result = Retriever::Update.new(@retriever, name: 'Test').execute

        expect(result).to eq true
        expect(@retriever).to be_ready
      end

      it 'should not trigger synchronization' do
        result = Retriever::Update.new(@retriever, name: 'Test', 'param1' => { 'name' => 'website', 'value' => 'par' }).execute

        expect(result).to eq true
        expect(@retriever).to be_ready
      end
    end

    describe 'changes params' do
      it 'should trigger synchronization' do
        result = Retriever::Update.new(@retriever, 'param1' => { 'name' => 'website', 'value' => 'pro' }).execute

        expect(result).to eq true
        expect(@retriever).to be_configuring
      end

      it 'should trigger synchronization' do
        result = Retriever::Update.new(@retriever, name: 'Connecteur de test', 'param1' => { 'name' => 'website', 'value' => 'pro' }).execute

        expect(result).to eq true
        expect(@retriever).to be_configuring
      end
    end

    describe 'changes both name and params' do
      it 'should trigger synchronization' do
        result = Retriever::Update.new(@retriever, name: 'Test', 'param1' => { 'name' => 'website', 'value' => 'pro' }).execute

        expect(result).to eq true
        expect(@retriever).to be_configuring
      end
    end
  end
end
