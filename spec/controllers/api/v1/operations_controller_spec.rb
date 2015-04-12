# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe Api::V1::OperationsController do
  render_views

  before(:all) do
    DatabaseCleaner.start
  end

  after(:all) do
    DatabaseCleaner.clean
  end

  describe 'Visiting index' do
    before(:all) do
      @admin = FactoryGirl.create :admin, code: 'AD%0001'
      @collaborator = FactoryGirl.create :prescriber, code: 'COL%0001'
      @user = FactoryGirl.create :user, code: 'TS%0001'
      @admin.update_authentication_token
      @collaborator.update_authentication_token
      @user.update_authentication_token

      @organization = FactoryGirl.create :organization, leader_id: @collaborator.id
      @organization.members << @user

      @bank_account = BankAccount.new
      @bank_account.user       = @user
      @bank_account.fiduceo_id = ':fiduceo_id'
      @bank_account.bank_name  = 'BANK'
      @bank_account.name       = 'Bank'
      @bank_account.number     = '123456789'
      @bank_account.journal    = 'BQ'
      @bank_account.save

      @bank_account2 = BankAccount.new
      @bank_account2.user       = @user
      @bank_account2.fiduceo_id = ':fiduceo_id'
      @bank_account2.bank_name  = 'BANK2'
      @bank_account2.name       = 'Bank2'
      @bank_account2.number     = '987654321'
      @bank_account2.journal    = 'CB'
      @bank_account2.save

      3.times.each do |i|
        operation = Operation.new
        operation.user         = @user
        operation.bank_account = @bank_account
        operation.date         = Date.new(2014,1,15+i)
        operation.label        = "PRLV n°#{i}"
        operation.amount       = -10.2*i
        operation.save
      end

      2.times.each do |i|
        operation = Operation.new
        operation.bank_account = @bank_account2
        operation.user         = @user
        operation.date         = Date.new(2014,1,5+i)
        operation.label        = "VIR n°#{i}"
        operation.amount       = 30.5
        operation.save
      end
    end

    after(:all) do
      DatabaseCleaner.clean
    end

    it 'should be successful' do
      get :index, format: 'json', access_token: @user.authentication_token
      expect(response).to be_successful
      operations = JSON.parse(response.body)
      expect(operations.size).to eq(5)
      op = Operation.desc(:date).first
      operation = operations.first
      expect(operation['date']).to eq(op.date.to_s)
      expect(operation['label']).to eq(op.label)
      expect(operation['journal']).to eq(op.bank_account.journal)
      expect(operation['amount']).to eq(op.amount)

      get :index, format: 'xml', access_token: @user.authentication_token
      expect(response).to be_successful
      operations = Nokogiri::XML(response.body).xpath('//operation')
      expect(operations.size).to eq(5)
      op = Operation.desc(:date).first
      operation = operations.first
      expect(operation.xpath('date').text).to eq(op.date.to_s)
      expect(operation.xpath('label').text).to eq(op.label)
      expect(operation.xpath('journal').text).to eq(op.bank_account.journal)
      expect(operation.xpath('amount').text.to_f).to eq(op.amount)
    end

    it 'should be ordered by date' do
      get :index, format: 'json', access_token: @user.authentication_token
      expect(response).to be_successful
      operations = JSON.parse(response.body)
      expect(operations.size).to eq(5)
      expect(operations.first['date']).to eq(Date.new(2014,1,17).to_s)
      expect(operations.last['date']).to eq(Date.new(2014,1,5).to_s)

      get :index, format: 'xml', access_token: @user.authentication_token
      expect(response).to be_successful
      operations = Nokogiri::XML(response.body).xpath('//operation')
      expect(operations.size).to eq(5)
      expect(operations.first.xpath('date').text).to eq(Date.new(2014,1,17).to_s)
      expect(operations.last.xpath('date').text).to eq(Date.new(2014,1,5).to_s)
    end

    context 'with user_code' do
      it 'should be unauthorized' do
        get :index, format: 'json', access_token: @user.authentication_token, user_code: 'CODE'
        expect(response).not_to be_successful
        expect(response.code).to eq('401')
      end

      context 'as admin' do
        it 'should be not found' do
          get :index, format: 'json', access_token: @admin.authentication_token, user_code: 'CODE'
          expect(response).not_to be_successful
          expect(response.code).to eq('404')
        end

        it 'should change user successfully' do
          expect(@admin.operations.count).to eq(0)

          get :index, format: 'json', access_token: @admin.authentication_token, user_code: @user.code
          expect(response).to be_successful
          operations = JSON.parse(response.body)
          expect(operations.size).to eq(5)

          get :index, format: 'xml', access_token: @admin.authentication_token, user_code: @user.code
          expect(response).to be_successful
          operations = Nokogiri::XML(response.body).xpath('//operation')
          expect(operations.size).to eq(5)
        end
      end

      context 'as collaborator' do
        it 'should be not found' do
          get :index, format: 'json', access_token: @collaborator.authentication_token, user_code: 'CODE'
          expect(response).not_to be_successful
          expect(response.code).to eq('404')
        end

        it 'should change user successfully' do
          get :index, format: 'json', access_token: @collaborator.authentication_token, user_code: @user.code
          expect(response).to be_successful
          operations = JSON.parse(response.body)
          expect(operations.size).to eq(5)

          get :index, format: 'xml', access_token: @collaborator.authentication_token, user_code: @user.code
          expect(response).to be_successful
          operations = Nokogiri::XML(response.body).xpath('//operation')
          expect(operations.size).to eq(5)
        end
      end
    end

    context 'with page and per_page' do
      it 'should return 2 operations' do
        expect(@user.operations.count).to eq(5)

        get :index, format: 'json', access_token: @user.authentication_token, page: 1, per_page: 2
        expect(response).to be_successful
        operations = JSON.parse(response.body)
        expect(operations.size).to eq(2)

        get :index, format: 'xml', access_token: @user.authentication_token, page: 1, per_page: 2
        expect(response).to be_successful
        operations = Nokogiri::XML(response.body).xpath('//operation')
        expect(operations.size).to eq(2)
      end

      it 'should return 1 operation' do
        expect(@user.operations.count).to eq(5)

        get :index, format: 'json', access_token: @user.authentication_token, page: 3, per_page: 2
        expect(response).to be_successful
        operations = JSON.parse(response.body)
        expect(operations.size).to eq(1)

        get :index, format: 'xml', access_token: @user.authentication_token, page: 3, per_page: 2
        expect(response).to be_successful
        operations = Nokogiri::XML(response.body).xpath('//operation')
        expect(operations.size).to eq(1)
      end

      it 'should return 0 operation' do
        expect(@user.operations.count).to eq(5)

        get :index, format: 'json', access_token: @user.authentication_token, page: 4, per_page: 2
        expect(response).to be_successful
        operations = JSON.parse(response.body)
        expect(operations.size).to eq(0)

        get :index, format: 'xml', access_token: @user.authentication_token, page: 4, per_page: 2
        expect(response).to be_successful
        operations = Nokogiri::XML(response.body).xpath('//operation')
        expect(operations.size).to eq(0)
      end
    end

    context 'with bank_account_id' do
      it 'should be invalid' do
        get :index, format: 'json', access_token: @user.authentication_token, bank_account_id: '12345'
        expect(response).not_to be_successful
        expect(response.code).to eq('400')
      end

      it 'should be not found' do
        get :index, format: 'json', access_token: @user.authentication_token, bank_account_id: BSON::ObjectId.new
        expect(response).not_to be_successful
        expect(response.code).to eq('404')
      end

      it 'should be successful' do
        get :index, format: 'json', access_token: @user.authentication_token, bank_account_id: @bank_account.id
        expect(response).to be_successful
        operations = JSON.parse(response.body)
        expect(operations.size).to eq(3)

        get :index, format: 'xml', access_token: @user.authentication_token, bank_account_id: @bank_account.id
        expect(response).to be_successful
        operations = Nokogiri::XML(response.body).xpath('//operation')
        expect(operations.size).to eq(3)
      end
    end

    context 'with not_accessed' do
      context 'as json' do
        it 'should have 5 operations then empty' do
          @user.operations.update_all(accessed_at: nil)

          params = {
            format: 'json',
            access_token: @user.authentication_token,
            not_accessed: '1'
          }

          get :index, params
          expect(response).to be_successful
          operations = JSON.parse(response.body)
          expect(operations.size).to eq(5)

          get :index, params
          expect(response).to be_successful
          operations = JSON.parse(response.body)
          expect(operations.size).to eq(0)
        end
      end

      context 'as xml' do
        it 'should have 5 operations then empty' do
          @user.operations.update_all(accessed_at: nil)

          params = {
            format: 'xml',
            access_token: @user.authentication_token,
            not_accessed: '1'
          }

          get :index, params
          expect(response).to be_successful
          operations = Nokogiri::XML(response.body).xpath('//operation')
          expect(operations.size).to eq(5)

          get :index, params
          expect(response).to be_successful
          operations = Nokogiri::XML(response.body).xpath('//operation')
          expect(operations.size).to eq(0)
        end
      end
    end

    context 'with page, per_page and not_accessed' do
      context 'as json' do
        it 'should have 3 operations then 2 operations and then empty' do
          @user.operations.update_all(accessed_at: nil)

          params = {
            format:       'json',
            access_token:        @user.authentication_token,
            not_accessed: '1',
            page:         1,
            per_page:     3
          }

          get :index, params
          expect(response).to be_successful
          operations = JSON.parse(response.body)
          expect(operations.size).to eq(3)

          get :index, params
          expect(response).to be_successful
          operations = JSON.parse(response.body)
          expect(operations.size).to eq(2)

          get :index, params
          expect(response).to be_successful
          operations = JSON.parse(response.body)
          expect(operations.size).to eq(0)
        end
      end

      context 'as xml' do
        it 'should have 3 operations then 2 operations and then empty' do
          @user.operations.update_all(accessed_at: nil)

          params = {
            format:       'xml',
            access_token:        @user.authentication_token,
            not_accessed: '1',
            page:         1,
            per_page:     3
          }

          get :index, params
          expect(response).to be_successful
          operations = Nokogiri::XML(response.body).xpath('//operation')
          expect(operations.size).to eq(3)

          get :index, params
          expect(response).to be_successful
          operations = Nokogiri::XML(response.body).xpath('//operation')
          expect(operations.size).to eq(2)

          get :index, params
          expect(response).to be_successful
          operations = Nokogiri::XML(response.body).xpath('//operation')
          expect(operations.size).to eq(0)
        end
      end
    end

    context 'with start_date' do
      context 'as json' do
        it 'return 3 operations' do
          params = {
            format:       'json',
            access_token: @user.authentication_token,
            start_date:   '2014-01-15'
          }

          get :index, params
          expect(response).to be_successful
          operations = JSON.parse response.body
          expect(@user.operations.count).to eq 5
          expect(operations.size).to eq 3

          expect(operations[0]['date']).to eq '2014-01-17'
          expect(operations[1]['date']).to eq '2014-01-16'
          expect(operations[2]['date']).to eq '2014-01-15'
        end
      end

      context 'as xml' do
        it 'return 3 operations' do
          params = {
            format:       'xml',
            access_token: @user.authentication_token,
            start_date:   '2014-01-15'
          }

          get :index, params
          expect(response).to be_successful
          operations = Nokogiri::XML(response.body).xpath('//operation')
          expect(@user.operations.count).to eq 5
          expect(operations.size).to eq 3

          expect(operations[0].css('date').first.content).to eq '2014-01-17'
          expect(operations[1].css('date').first.content).to eq '2014-01-16'
          expect(operations[2].css('date').first.content).to eq '2014-01-15'
        end
      end
    end

    context 'with end_date' do
      context 'as json' do
        it 'return 2 operations' do
          params = {
            format:       'json',
            access_token: @user.authentication_token,
            end_date:     '2014-01-06'
          }

          get :index, params
          expect(response).to be_successful
          operations = JSON.parse response.body
          expect(@user.operations.count).to eq 5
          expect(operations.size).to eq 2

          expect(operations[0]['date']).to eq '2014-01-06'
          expect(operations[1]['date']).to eq '2014-01-05'
        end
      end

      context 'as xml' do
        it 'return 2 operations' do
          params = {
            format:       'xml',
            access_token: @user.authentication_token,
            end_date:     '2014-01-06'
          }

          get :index, params
          expect(response).to be_successful
          operations = Nokogiri::XML(response.body).xpath('//operation')
          expect(@user.operations.count).to eq 5
          expect(operations.size).to eq 2

          expect(operations[0].css('date').first.content).to eq '2014-01-06'
          expect(operations[1].css('date').first.content).to eq '2014-01-05'
        end
      end
    end

    context 'with start_date and end_date' do
      context 'as json' do
        it 'return 3 operations' do
          params = {
            format:       'json',
            access_token: @user.authentication_token,
            start_date:   '2014-01-06',
            end_date:     '2014-01-16'
          }

          get :index, params
          expect(response).to be_successful
          operations = JSON.parse response.body
          expect(@user.operations.count).to eq 5
          expect(operations.size).to eq 3

          expect(operations[0]['date']).to eq '2014-01-16'
          expect(operations[1]['date']).to eq '2014-01-15'
          expect(operations[2]['date']).to eq '2014-01-06'
        end
      end

      context 'as xml' do
        it 'return 3 operations' do
          params = {
            format:       'xml',
            access_token: @user.authentication_token,
            start_date:   '2014-01-06',
            end_date:     '2014-01-16'
          }

          get :index, params
          expect(response).to be_successful
          operations = Nokogiri::XML(response.body).xpath('//operation')
          expect(@user.operations.count).to eq 5
          expect(operations.size).to eq 3

          expect(operations[0].css('date').first.content).to eq '2014-01-16'
          expect(operations[1].css('date').first.content).to eq '2014-01-15'
          expect(operations[2].css('date').first.content).to eq '2014-01-06'
        end
      end
    end
  end

  describe 'Posting a file to import' do
    before(:all) do
      DatabaseCleaner.start

      @admin    = FactoryGirl.create :admin, code: 'AD%0001'
      @operator = FactoryGirl.create :user,  code: 'OP%0001', is_operator: true
      @user     = FactoryGirl.create :user,  code: 'TS%0001'
      @admin.update_authentication_token
      @operator.update_authentication_token
      @user.update_authentication_token

      @pack = Pack.new
      @pack.name  = "#{@user.code} BQ 201401 all"
      @pack.owner = @user
      @pack.save

      @piece = Pack::Piece.new
      @piece.pack     = @pack
      @piece.name     = "#{@user.code} BQ 201401 001"
      @piece.position = 1
      @piece.origin   = 'scan'
      @piece.save

      @empty_file = File.new(Rails.root.join('spec/support/files/empty_operations.xml'))
      @file       = File.new(Rails.root.join('spec/support/files/operations.xml'))
    end

    after(:all) do
      @empty_file.close
      @file.close
      DatabaseCleaner.clean
    end

    after(:each) do
      Operation.delete_all
    end

    context 'as xml' do
      it 'should unauthorize an user' do
        temp_file = ActionDispatch::Http::UploadedFile.new(tempfile: @empty_file, filename: File.basename(@empty_file))
        post :import, format: 'xml', access_token: @user.authentication_token, file: temp_file
        expect(response).not_to be_successful
        expect(response.code.to_i).to eq(401)
        message = Nokogiri::XML(response.body).xpath('//message').first
        expect(message.content).to eq('Unauthorized')
      end

      it 'should authorize an operator' do
        temp_file = ActionDispatch::Http::UploadedFile.new(tempfile: @empty_file, filename: File.basename(@empty_file))
        post :import, format: 'xml', access_token: @operator.authentication_token, file: temp_file
        expect(response).to be_successful
        error = Nokogiri::XML(response.body).xpath('//error').first
        expect(error.content).to eq('No data to process')
        expect(@user.operations.count).to eq(0)
      end

      it 'should authorize an admin' do
        temp_file = ActionDispatch::Http::UploadedFile.new(tempfile: @empty_file, filename: File.basename(@empty_file))
        post :import, format: 'xml', access_token: @admin.authentication_token, file: temp_file
        expect(response).to be_successful
        error = Nokogiri::XML(response.body).xpath('//error').first
        expect(error.content).to eq('No data to process')
        expect(@user.operations.count).to eq(0)
      end

      it 'create one operation' do
        temp_file = ActionDispatch::Http::UploadedFile.new(tempfile: @file, filename: File.basename(@file))
        post :import, format: 'xml', access_token: @operator.authentication_token, file: temp_file
        expect(response).to be_successful
        message = Nokogiri::XML(response.body).xpath('//message').first
        expect(message.content).to eq('1 operation(s) added.')
        expect(@user.operations.count).to eq(1)
      end
    end

    context 'as json' do
      it "return 'Not supported yet.'" do
        temp_file = ActionDispatch::Http::UploadedFile.new(tempfile: @empty_file, filename: File.basename(@empty_file))
        post :import, format: 'json', access_token: @operator.authentication_token, file: temp_file
        expect(response).to be_successful
        data = JSON.parse(response.body)
        expect(data['message']).to eq('Not supported yet.')
        expect(@user.operations.count).to eq(0)
      end
    end
  end
end
