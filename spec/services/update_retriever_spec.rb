require 'spec_helper'

describe UpdateRetriever do
  before(:all) do
    @user = FactoryGirl.create :user, code: 'IDO%0001'
    @user.options = UserOptions.create(user_id: @user.id)
    @journal = FactoryGirl.create :account_book_type, user_id: @user.id

    VCR.use_cassette('budgea/create_budgea_account') do
      CreateBudgeaAccount.execute(@user)
    end

    @connector = Connector.new
    @connector.name            = 'Connecteur de test'
    @connector.capabilities    = ['document', 'bank']
    @connector.apis            = ['budgea']
    @connector.active_apis     = ['budgea']
    @connector.budgea_id       = 40
    @connector.fiduceo_ref     = nil
    @connector.combined_fields = {
      'website' => {
        'label'       => 'Type de compte',
        'type'        => 'list',
        'regex'       => nil,
        'budgea_name' => 'website',
        'values' => [
          { 'value' => 'par', 'label' => 'Particuliers' },
          { 'value' => 'pro', 'label' => 'Professionnels' }
        ]
      },
      'login' => {
        'label'       => 'Identifiant',
        'type'        => 'text',
        'regex'       => nil,
        'budgea_name' => 'login'
      },
      'password' => {
        'label'       => 'Mot de passe',
        'type'        => 'password',
        'regex'       => nil,
        'budgea_name' => 'password'
      }
    }
    @connector.save
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
        result = UpdateRetriever.new(@retriever, name: 'Connecteur de test').execute

        expect(result).to eq true
        expect(@retriever).to be_ready
      end

      it 'should not trigger synchronization' do
        result = UpdateRetriever.new(@retriever, 'param1' => { 'name' => 'website', 'value' => 'par' }).execute

        expect(result).to eq true
        expect(@retriever).to be_ready
      end

      it 'should not trigger synchronization' do
        result = UpdateRetriever.new(@retriever, name: 'Connecteur de test', 'param1' => { 'name' => 'website', 'value' => 'par' }).execute

        expect(result).to eq true
        expect(@retriever).to be_ready
      end
    end

    describe 'changes name' do
      it 'should not trigger synchronization' do
        result = UpdateRetriever.new(@retriever, name: 'Test').execute

        expect(result).to eq true
        expect(@retriever).to be_ready
      end

      it 'should not trigger synchronization' do
        result = UpdateRetriever.new(@retriever, name: 'Test', 'param1' => { 'name' => 'website', 'value' => 'par' }).execute

        expect(result).to eq true
        expect(@retriever).to be_ready
      end
    end

    describe 'changes params' do
      it 'should trigger synchronization' do
        result = UpdateRetriever.new(@retriever, 'param1' => { 'name' => 'website', 'value' => 'pro' }).execute

        expect(result).to eq true
        expect(@retriever).to be_configuring
      end

      it 'should trigger synchronization' do
        result = UpdateRetriever.new(@retriever, name: 'Connecteur de test', 'param1' => { 'name' => 'website', 'value' => 'pro' }).execute

        expect(result).to eq true
        expect(@retriever).to be_configuring
      end
    end

    describe 'changes both name and params' do
      it 'should trigger synchronization' do
        result = UpdateRetriever.new(@retriever, name: 'Test', 'param1' => { 'name' => 'website', 'value' => 'pro' }).execute

        expect(result).to eq true
        expect(@retriever).to be_configuring
      end
    end
  end
end
