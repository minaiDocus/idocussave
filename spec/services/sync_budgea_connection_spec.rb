# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe SyncBudgeaConnection do
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
      website: {
        label: 'Type de compte',
        type:  'list',
        regex: nil,
        budgea_name:  'website',
        values: {
          par: { label: 'Particuliers' },
          pro: { label: 'Professionnels' }
        }
      },
      login: {
        label:        'Identifiant',
        type:         'text',
        regex:        nil,
        budgea_name:  'login'
      },
      password: {
        label:        'Mot de passe',
        type:         'password',
        regex:        nil,
        budgea_name:  'password'
      }
    }
    @connector.save

    @retriever = Retriever.new
    @retriever.user      = @user
    @retriever.connector = @connector
    @retriever.journal   = @journal
    @retriever.name      = 'Connecteur de test'
    @retriever.param1 = {
      'name' => 'website',
      'type' => 'list',
      'value' => 'par'
    }
    @retriever.param2 = {
      'name' => 'login',
      'type' => 'text',
      'value' => 'John Doe'
    }
    @retriever.param3 = {
      'name' => 'password',
      'type' => 'password',
      'value' => '1234'
    }
    @retriever.save
    @retriever.reload
  end

  it 'creates a connection successfully' do
    expect(@retriever.state).to eq 'configuring'
    VCR.use_cassette('budgea/create_budgea_connection') do
      SyncBudgeaConnection.execute(@retriever)
    end
    expect(@retriever.param1).to be_present
    expect(@retriever.param2).to be_present
    expect(@retriever.param3).to be_nil
    expect(@retriever.budgea_id).to be_present
    expect(@retriever.state).to eq 'ready'
    expect(@retriever.budgea_state).to eq 'successful'
  end

  it 'updates a connection successfully' do
    @retriever.param2 = {
      'name' => 'login',
      'type' => 'text',
      'value' => 'John Doe 2'
    }
    @retriever.save
    @retriever.reload
    @retriever.configure_connection

    expect(@retriever.state).to eq 'configuring'
    VCR.use_cassette('budgea/update_budgea_connection') do
      SyncBudgeaConnection.execute(@retriever)
    end
    expect(@retriever.param1).to be_present
    expect(@retriever.param2).to be_present
    expect(@retriever.param3).to be_nil
    expect(@retriever.state).to eq 'ready'
    expect(@retriever.budgea_state).to eq 'successful'
  end

  it 'forces a synchronization successfully' do
    @retriever.run

    expect(@retriever.state).to eq 'running'
    VCR.use_cassette('budgea/synchronize_budgea_connection') do
      SyncBudgeaConnection.execute(@retriever)
    end
    expect(@retriever.param1).to be_present
    expect(@retriever.param2).to be_present
    expect(@retriever.param3).to be_nil
    expect(@retriever.state).to eq 'ready'
    expect(@retriever.budgea_state).to eq 'successful'
  end

  it 'destroys a connection successfully' do
    @retriever.destroy_connection

    VCR.use_cassette('budgea/destroy_budgea_connection') do
      SyncBudgeaConnection.execute(@retriever)
    end
    expect(@retriever).to be_destroyed
  end
end
