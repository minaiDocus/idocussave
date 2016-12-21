# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe SyncFiduceoConnection do
  before(:all) do
    @user = FactoryGirl.create :user, code: 'IDO%0001'
    @user.options = UserOptions.create(user_id: @user.id)
    @journal = FactoryGirl.create :account_book_type, user_id: @user.id

    @connector = Connector.new
    @connector.name            = 'OVH'
    @connector.capabilities    = ['document']
    @connector.apis            = ['fiduceo']
    @connector.active_apis     = ['fiduceo']
    @connector.fiduceo_ref     = '4d98668c287db3fb58b3f6e9'
    @connector.combined_fields = {
      login: {
        label:        'Identifiant',
        type:         'text',
        regex:        nil,
        fiduceo_name: 'login'
      },
      password: {
        label:        'Mot de passe',
        type:         'password',
        regex:        nil,
        fiduceo_name: 'pass'
      }
    }
    @connector.save

    @retriever = Retriever.new
    @retriever.user      = @user
    @retriever.connector = @connector
    @retriever.journal   = @journal
    @retriever.name      = 'OVH'
    @retriever.param1 = {
      name: 'login',
      type: 'text',
      value: 'John Doe'
    }
    @retriever.param2 = {
      name: 'password',
      type: 'password',
      value: '12345'
    }
    @retriever.save
    @retriever.reload

    VCR.use_cassette('fiduceo/create_user') do
      FiduceoUser.new(@user).create
    end
  end

  it 'creates a connection successfully' do
    expect(@retriever.state).to eq 'configuring'
    VCR.use_cassette('fiduceo/create_fiduceo_connection') do
      SyncFiduceoConnection.execute(@retriever, false)
    end
    expect(@retriever.param1).to be_present
    expect(@retriever.param2).to be_nil
    expect(@retriever.fiduceo_id).to be_present
    expect(@retriever.state).to eq 'ready'
    expect(@retriever.fiduceo_state).to eq 'successful'
  end

  it 'updates a connection successfully' do
    @retriever.param1 = {
      name: 'login',
      type: 'text',
      value: 'John Doe 2'
    }
    @retriever.save
    @retriever.reload
    @retriever.configure_connection

    expect(@retriever.state).to eq 'configuring'
    VCR.use_cassette('fiduceo/update_fiduceo_connection') do
      SyncFiduceoConnection.execute(@retriever, false)
    end
    expect(@retriever.param1).to be_present
    expect(@retriever.param2).to be_nil
    expect(@retriever.state).to eq 'ready'
    expect(@retriever.fiduceo_state).to eq 'successful'
  end

  it 'forces a synchronization successfully' do
    @retriever.run

    expect(@retriever.state).to eq 'running'
    VCR.use_cassette('fiduceo/synchronize_fiduceo_connection') do
      SyncFiduceoConnection.execute(@retriever, false)
    end
    expect(@retriever.param1).to be_present
    expect(@retriever.param2).to be_nil
    expect(@retriever.state).to eq 'ready'
    expect(@retriever.fiduceo_state).to eq 'successful'
  end

  it 'destroys a connection successfully' do
    @retriever.destroy_connection

    VCR.use_cassette('fiduceo/destroy_fiduceo_connection') do
      SyncFiduceoConnection.execute(@retriever)
    end
    expect(@retriever).to be_destroyed
  end
end
