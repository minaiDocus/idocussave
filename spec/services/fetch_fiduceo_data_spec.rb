# -*- encoding : UTF-8 -*-
require 'spec_helper'

# TODO : check if it is still needed
describe FetchFiduceoData do
  # context 'document' do
  #   before(:all) do
  #     @user = FactoryBot.create :user, code: 'IDO%0001'
  #     @user.options = UserOptions.create(user_id: @user.id)
  #     @journal = FactoryBot.create :account_book_type, user_id: @user.id

  #     @connector = Connector.new
  #     @connector.name            = 'OVH'
  #     @connector.capabilities    = ['document']
  #     @connector.apis            = ['fiduceo']
  #     @connector.active_apis     = ['fiduceo']
  #     @connector.fiduceo_ref     = '4d98668c287db3fb58b3f6e9'
  #     @connector.combined_fields = {
  #       login: {
  #         label:        'Identifiant',
  #         type:         'text',
  #         regex:        nil,
  #         fiduceo_name: 'login'
  #       },
  #       password: {
  #         label:        'Mot de passe',
  #         type:         'password',
  #         regex:        nil,
  #         fiduceo_name: 'pass'
  #       }
  #     }
  #     @connector.save

  #     @retriever = Retriever.new
  #     @retriever.user      = @user
  #     @retriever.connector = @connector
  #     @retriever.journal   = @journal
  #     @retriever.name      = 'OVH'
  #     @retriever.param1 = {
  #       name: 'login',
  #       type: 'text',
  #       value: 'John Doe'
  #     }
  #     @retriever.param2 = {
  #       name: 'password',
  #       type: 'password',
  #       value: '12345'
  #     }
  #     @retriever.save
  #     @retriever.reload

  #     VCR.use_cassette('fiduceo/create_user') do
  #       FiduceoUser.new(@user).create
  #     end

  #     VCR.use_cassette('fiduceo/create_fiduceo_connection') do
  #       SyncFiduceoConnection.execute(@retriever, false)
  #     end
  #   end

  #   after(:each) do
  #     TempDocument.destroy_all
  #   end

  #   context 'no preexisting document' do
  #     it 'creates a document' do
  #       expect(@user.temp_documents.count).to eq 0

  #       VCR.use_cassette('fiduceo/fetch_documents') do
  #         FetchFiduceoData.execute(@retriever)
  #       end

  #       expect(@user.temp_documents.count).to eq 1
  #     end
  #   end

  #   context 'a document already exist' do
  #     it 'does not create a document' do
  #       pack = TempPack.find_or_create_by_name "#{@user.code} #{@journal.name} #{Time.now.strftime('%Y%M')}"
  #       options = {
  #         user_id:               @user.id,
  #         delivery_type:         'retriever',
  #         api_id:                '585a9f59498ea472a02d7dcc',
  #         api_name:              'fiduceo',
  #         metadata:              { date: Date.parse('18-09-2014') },
  #         is_content_file_valid: true
  #       }
  #       file = File.open(Rails.root.join('spec', 'support', 'files', '2pages.pdf'), 'r')
  #       temp_document = pack.add file, options
  #       @retriever.temp_documents << temp_document
  #       file.close

  #       expect(@user.temp_documents.count).to eq 1

  #       VCR.use_cassette('fiduceo/fetch_documents') do
  #         FetchFiduceoData.execute(@retriever)
  #       end

  #       expect(@user.temp_documents.count).to eq 1
  #     end
  #   end
  # end

  # TODO add test for bank account and operations
end
