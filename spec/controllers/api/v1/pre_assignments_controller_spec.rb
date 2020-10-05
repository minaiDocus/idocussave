# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe Api::V1::PreAssignmentsController do
  render_views

  before(:all) do
    @admin = FactoryBot.create :admin, code: 'AD%0001'
    @user  = FactoryBot.create :user,  code: 'TS%0001'

    @admin.update_authentication_token
    @user.update_authentication_token

    Timecop.freeze(Time.local(2014,1,1,8,0,0))

    @pack = Pack.create(name: 'TS%0001 AC 201401 all', owner_id: @user.id)
    @piece1 = Pack::Piece.create(name: 'TS%0001 AC 201401 001', pack_id: @pack.id, origin: 'scan', pre_assignment_state: 'processing')
    @piece2 = Pack::Piece.create(name: 'TS%0001 AC 201401 002', pack_id: @pack.id, origin: 'scan', pre_assignment_state: 'processing')

    Timecop.freeze(Time.local(2014,2,1,8,0,0))

    @pack2 = Pack.create(name: 'TS%0001 AC 201402 all', owner_id: @user.id)
    @piece3 = Pack::Piece.create(name: 'TS%0001 AC 201402 001', pack_id: @pack2.id, origin: 'scan', pre_assignment_state: 'processing')

    Timecop.return
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
        expect(response).to be_successful
        expect(response.code).to eq('200')
        packs = JSON.parse(response.body)

        expect(packs.size).to eq(2)

        pack = packs.first
        expect(pack['date']).to eq('2014-02-01 08:00:00')
        expect(pack['pack_name']).to eq(@pack2.name.sub(' all', ''))
        expect(pack['piece_counts']).to eq(1)
        expect(pack['comment']).to eq('A test comment.')

        pack2 = packs.last
        expect(pack2['date']).to eq('2014-01-01 08:00:00')
        expect(pack2['pack_name']).to eq(@pack.name.sub(' all', ''))
        expect(pack2['piece_counts']).to eq(2)
        expect([nil, '']).to include pack2['comment']
      end
    end

    context 'as xml' do
      it 'should have 2 packs' do
        get :index, format: 'xml', access_token: @admin.authentication_token
        expect(response).to be_successful
        expect(response.code).to eq('200')
        packs = Nokogiri::XML(response.body).xpath('//pre_assignment')
        expect(packs.size).to eq(2)

        pack = packs.first
        expect(pack.xpath('date').text).to eq('2014-02-01 08:00:00')
        expect(pack.xpath('pack_name').text).to eq(@pack2.name.sub(' all', ''))
        expect(pack.xpath('piece_counts').text.to_i).to eq(1)
        expect(pack.xpath('comment').text).to eq('A test comment.')

        pack2 = packs.last
        expect(pack2.xpath('date').text).to eq('2014-01-01 08:00:00')
        expect(pack2.xpath('pack_name').text).to eq(@pack.name.sub(' all', ''))
        expect(pack2.xpath('piece_counts').text.to_i).to eq(2)
        expect(pack2.xpath('comment').text).to be_blank
      end
    end
  end

  describe 'Updating comment' do
    context 'without params' do
      it 'should be invalid' do
        post :update_comment, format: 'json', access_token: @admin.authentication_token
        expect(response).not_to be_successful
        expect(response.code).to eq('400')
      end
    end

    context 'with params' do
      it 'should be invalid' do
        post :update_comment, format: 'json', access_token: @admin.authentication_token, pack_name: @pack.name.sub(' all', '')
        expect(response).not_to be_successful
        expect(response.code).to eq('400')
      end

      it 'should be not found' do
        params = {
          format:       'json',
          access_token: @admin.authentication_token,
          pack_name:    'TS%0002 AC 201401',
          comment:      ''
        }

        post :update_comment, params
        expect(response).not_to be_successful
        expect(response.code).to eq('404')
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
          expect(response).not_to be_successful
          expect(response.code).to eq('400')
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
            expect(response).to be_successful
            expect(response.code).to eq('200')
            result = JSON.parse(response.body)
            expect(result['message']).to eq('Updated successfully.')

            @piece1.reload
            expect(@piece1.pre_assignment_comment).to eq('')

            @piece2.reload
            expect(@piece2.pre_assignment_comment).to eq('')
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
            expect(response).to be_successful
            expect(response.code).to eq('200')
            message = Nokogiri::XML(response.body).xpath('//message').first
            expect(message.text).to eq('Updated successfully.')

            @piece1.reload
            expect(@piece1.pre_assignment_comment).to eq('')

            @piece2.reload
            expect(@piece2.pre_assignment_comment).to eq('')
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
            expect(response).to be_successful
            expect(response.code).to eq('200')
            result = JSON.parse(response.body)
            expect(result['message']).to eq('Updated successfully.')

            @piece1.reload
            expect(@piece1.pre_assignment_comment).to eq('Unprocessable entity.')

            @piece2.reload
            expect(@piece2.pre_assignment_comment).to eq('Unprocessable entity.')
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
            expect(response).not_to be_successful
            expect(response.code).to eq('404')
          end

          it 'should be successful' do
            params = {
              format:       'xml',
              access_token: @admin.authentication_token,
              pack_name:    @pack.name.sub(' all', ''),
              comment:      'Unprocessable entity.'
            }

            post :update_comment, params
            expect(response).to be_successful
            expect(response.code).to eq('200')
            message = Nokogiri::XML(response.body).xpath('//message').first
            expect(message.text).to eq('Updated successfully.')

            @piece1.reload
            expect(@piece1.pre_assignment_comment).to eq('Unprocessable entity.')

            @piece2.reload
            expect(@piece2.pre_assignment_comment).to eq('Unprocessable entity.')
          end
        end
      end
    end
  end
end
