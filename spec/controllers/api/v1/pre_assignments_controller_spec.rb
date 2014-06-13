# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe Api::V1::PreAssignmentsController do
  render_views

  before(:all) do
    DatabaseCleaner.start

    @admin = FactoryGirl.create :admin, code: 'AD%0001'
    @user  = FactoryGirl.create :user,  code: 'TS%0001'

    @admin.update_authentication_token
    @user.update_authentication_token

    Timecop.freeze(Time.local(2014,1,1,8,0,0))

    @pack = Pack.create(name: 'TS%0001 AC 201401 all', owner_id: @user.id)
    @piece1 = Pack::Piece.create(name: 'TS%0001 AC 201401 001', pack_id: @pack.id, origin: 'scan', is_awaiting_pre_assignment: true)
    @piece2 = Pack::Piece.create(name: 'TS%0001 AC 201401 002', pack_id: @pack.id, origin: 'scan', is_awaiting_pre_assignment: true)

    Timecop.freeze(Time.local(2014,2,1,8,0,0))

    @pack2 = Pack.create(name: 'TS%0001 AC 201402 all', owner_id: @user.id)
    @piece3 = Pack::Piece.create(name: 'TS%0001 AC 201402 001', pack_id: @pack2.id, origin: 'scan', is_awaiting_pre_assignment: true)

    Timecop.return
  end

  after(:all) do
    DatabaseCleaner.clean
  end

  describe 'Visiting index' do
    before(:all) do
      @piece3.update_attribute(:pre_assignment_comment, 'A test comment.')
    end

    after(:all) do
      @piece3.update_attribute(:pre_assignment_comment, nil)
    end

    context 'as json' do
      it 'should have 2 packs' do
        get :index, format: 'json', access_token: @admin.authentication_token
        response.should be_successful
        response.code.should eq('200')
        packs = JSON.parse(response.body)

        packs.size.should eq(2)

        pack = packs.first
        pack['date'].should eq('2014-01-01 08:00:00')
        pack['pack_name'].should eq(@pack.name.sub(' all', ''))
        pack['piece_counts'].should eq(2)
        pack['comment'].should be_nil

        pack2 = packs.last
        pack2['date'].should eq('2014-02-01 08:00:00')
        pack2['pack_name'].should eq(@pack2.name.sub(' all', ''))
        pack2['piece_counts'].should eq(1)
        pack2['comment'].should eq('A test comment.')
      end
    end

    context 'as xml' do
      it 'should have 2 packs' do
        get :index, format: 'xml', access_token: @admin.authentication_token
        response.should be_successful
        response.code.should eq('200')
        packs = Nokogiri::XML(response.body).xpath('//pre_assignment')
        packs.size.should eq(2)

        pack = packs.first
        pack.xpath('date').text.should eq('2014-01-01 08:00:00')
        pack.xpath('pack_name').text.should eq(@pack.name.sub(' all', ''))
        pack.xpath('piece_counts').text.to_i.should eq(2)
        pack.xpath('comment').text.should be_blank

        pack2 = packs.last
        pack2.xpath('date').text.should eq('2014-02-01 08:00:00')
        pack2.xpath('pack_name').text.should eq(@pack2.name.sub(' all', ''))
        pack2.xpath('piece_counts').text.to_i.should eq(1)
        pack2.xpath('comment').text.should eq('A test comment.')
      end
    end
  end

  describe 'Updating comment' do
    context 'without params' do
      it 'should be invalid' do
        post :update_comment, format: 'json', access_token: @admin.authentication_token
        response.should_not be_successful
        response.code.should eq('400')
      end
    end

    context 'with params' do
      it 'should be invalid' do
        post :update_comment, format: 'json', access_token: @admin.authentication_token, pack_name: @pack.name.sub(' all', '')
        response.should_not be_successful
        response.code.should eq('400')
      end

      context 'with invalid byte sequence in UTF-8' do
        context 'as json' do
          it 'should be invalid' do
            pack_name = 'TS%AAA%20AC%20201401'
            page.driver.post "/api/v1/pre_assignments/update_comment.json?access_token=#{@admin.authentication_token}&pack_name=#{pack_name}&comment="

            page.status_code.should eq(400)
            result = JSON.parse(page.body)
            result['message'].should eq('Invalid Request : ArgumentError')
            result['description'].should eq('invalid byte sequence in UTF-8')
          end
        end

        context 'as xml' do
          it 'should be invalid' do
            pack_name = 'TS%AAA%20AC%20201401'
            page.driver.post "/api/v1/pre_assignments/update_comment.xml?access_token=#{@admin.authentication_token}&pack_name=#{pack_name}&comment="

            page.status_code.should eq(400)
            doc = Nokogiri::XML(page.body)
            doc.xpath('//title').first.text.should eq('Invalid Request : ArgumentError')
            doc.xpath('//description').first.text.should eq('invalid byte sequence in UTF-8')
          end
        end
      end

      it 'should be not found' do
        params = {
          format:       'json',
          access_token: @admin.authentication_token,
          pack_name:    'TS%0002 AC 201401',
          comment:      ''
        }

        post :update_comment, params
        response.should_not be_successful
        response.code.should eq('404')
      end

      context 'with nil comment' do
        it 'should be invalid' do
          params = {
            format:       'json',
            access_token: @admin.authentication_token,
            pack_name:    @pack.name.sub(' all', ''),
            comment:      nil
          }

          post :update_comment, params
          response.should_not be_successful
          response.code.should eq('400')
        end
      end

      context 'with blank comment' do
        before(:each) do
          @piece1.update_attribute(:pre_assignment_comment, nil)
          @piece2.update_attribute(:pre_assignment_comment, nil)
        end

        context 'as json' do
          it 'should be successful' do
            params = {
              format:       'json',
              access_token: @admin.authentication_token,
              pack_name:    @pack.name.sub(' all', ''),
              comment:      ''
            }

            post :update_comment, params
            response.should be_successful
            response.code.should eq('200')
            result = JSON.parse(response.body)
            result['message'].should eq('Updated successfully.')

            @piece1.reload
            @piece1.pre_assignment_comment.should eq('')

            @piece2.reload
            @piece2.pre_assignment_comment.should eq('')
          end
        end

        context 'as xml' do
          it 'should be successful' do
            params = {
              format:       'xml',
              access_token: @admin.authentication_token,
              pack_name:    @pack.name.sub(' all', ''),
              comment:      ''
            }

            post :update_comment, params
            response.should be_successful
            response.code.should eq('200')
            message = Nokogiri::XML(response.body).xpath('//message').first
            message.text.should eq('Updated successfully.')

            @piece1.reload
            @piece1.pre_assignment_comment.should eq('')

            @piece2.reload
            @piece2.pre_assignment_comment.should eq('')
          end
        end
      end

      context 'with filled comment' do
        before(:each) do
          @piece1.update_attribute(:pre_assignment_comment, '')
          @piece2.update_attribute(:pre_assignment_comment, '')
        end

        after(:each) do
          @piece1.update_attribute(:pre_assignment_comment, '')
          @piece2.update_attribute(:pre_assignment_comment, '')
        end

        context 'as json' do
          it 'should be successful' do
            params = {
              format:       'json',
              access_token: @admin.authentication_token,
              pack_name:    @pack.name.sub(' all', ''),
              comment:      'Unprocessable entity.'
            }

            post :update_comment, params
            response.should be_successful
            response.code.should eq('200')
            result = JSON.parse(response.body)
            result['message'].should eq('Updated successfully.')

            @piece1.reload
            @piece1.pre_assignment_comment.should eq('Unprocessable entity.')

            @piece2.reload
            @piece2.pre_assignment_comment.should eq('Unprocessable entity.')
          end
        end

        context 'as xml' do
          it 'with invalid pack_name should be not found' do
            @pack3 = Pack.create(name: 'TS%0001 BQ 201401 all', owner_id: @user.id)

            params = {
              format:       'xml',
              access_token: @admin.authentication_token,
              pack_name:    'TS%0001 BQ 201401',
              comment:      'Test comment.'
            }

            post :update_comment, params
            response.should_not be_successful
            response.code.should eq('404')
          end

          it 'should be successful' do
            params = {
              format:       'xml',
              access_token: @admin.authentication_token,
              pack_name:    @pack.name.sub(' all', ''),
              comment:      'Unprocessable entity.'
            }

            post :update_comment, params
            response.should be_successful
            response.code.should eq('200')
            message = Nokogiri::XML(response.body).xpath('//message').first
            message.text.should eq('Updated successfully.')

            @piece1.reload
            @piece1.pre_assignment_comment.should eq('Unprocessable entity.')

            @piece2.reload
            @piece2.pre_assignment_comment.should eq('Unprocessable entity.')
          end
        end
      end
    end
  end
end
