# -*- encoding : UTF-8 -*-
require 'spec_helper'
Sidekiq::Testing.inline! #execute jobs immediatly

describe SgiApiServices::GroupDocument do
  before(:all) do
      Timecop.freeze(Time.local(2020,06,12,0,1,0))
    end

    after(:all) do
      Timecop.return
    end
  describe '.position', :position do
    it 'returns 5' do
      result = SgiApiServices::GroupDocument.position('IDO0001_AC_202006_005.pdf')
      expect(result).to eq 5
    end

    it 'returns 5' do
      result = SgiApiServices::GroupDocument.position('IDO_0001_AC_2020_005.pdf')
      expect(result).to eq 5
    end

    it 'returns 3' do
      result = SgiApiServices::GroupDocument.position('IDO0001_AC_2020_003_001.pdf')
      expect(result).to eq 3
    end

    it 'returns 3' do
      result = SgiApiServices::GroupDocument.position('IDO_0001_AC_2020_003_001.pdf')
      expect(result).to eq 3
    end

    it 'returns 1017' do
      result = SgiApiServices::GroupDocument.position('IDO_0001_AC_2020_1017_001.pdf')
      expect(result).to eq 1017
    end

    it 'returns nil' do
      result = SgiApiServices::GroupDocument.position('IDO0001_AC_2020_005_001_001.pdf')
      expect(result).to be_nil
    end
  end

  describe '.basename', :basename do
    it 'returns IDO0001 AC 2020' do
      result = SgiApiServices::GroupDocument.basename('IDO0001_AC_2020_005.pdf')
      expect(result).to eq 'IDO0001 AC 2020'
    end

    it 'returns IDO0001 AC 2020' do
      result = SgiApiServices::GroupDocument.basename('IDO0001_AC_2020_1045.pdf')
      expect(result).to eq 'IDO0001 AC 2020'
    end

    it 'returns IDO%0001 AC 2020' do
      result = SgiApiServices::GroupDocument.basename('IDO_0001_AC_2020_005.pdf')
      expect(result).to eq 'IDO%0001 AC 2020'
    end

    it 'returns IDO%0001 AC 2020' do
      result = SgiApiServices::GroupDocument.basename('IDO_0001_AC_2020_1045.pdf')
      expect(result).to eq 'IDO%0001 AC 2020'
    end

    it 'returns IDO0001 AC 2020' do
      result = SgiApiServices::GroupDocument.basename('IDO0001_AC_2020_003_001.pdf')
      expect(result).to eq 'IDO0001 AC 2020'
    end

    it 'returns IDO0001 AC 2020' do
      result = SgiApiServices::GroupDocument.basename('IDO0001_AC_2020_1045_001.pdf')
      expect(result).to eq 'IDO0001 AC 2020'
    end

    it 'returns IDO%0001 AC 2020' do
      result = SgiApiServices::GroupDocument.basename('IDO_0001_AC_2020_003_001.pdf')
      expect(result).to eq 'IDO%0001 AC 2020'
    end

    it 'returns IDO%0001 AC 2020' do
      result = SgiApiServices::GroupDocument.basename('IDO_0001_AC_2020_1045_001.pdf')
      expect(result).to eq 'IDO%0001 AC 2020'
    end

    it 'returns nil' do
      result = SgiApiServices::GroupDocument.basename('IDO0001_AC_2020_005_001_001.pdf')
      expect(result).to be_nil
    end

    it 'returns nil' do
      result = SgiApiServices::GroupDocument.basename('IDO0001_AC_2020T1_005_001_001.pdf')
      expect(result).to be_nil
    end

    it 'returns nil' do
      result = SgiApiServices::GroupDocument.basename('IDO0001_AC_2020_005_001_001.pdf')
      expect(result).to be_nil
    end

    it 'returns nil' do
      result = SgiApiServices::GroupDocument.basename('IDO0001_AC_2020_1005_001_001.pdf')
      expect(result).to be_nil
    end

    it 'returns nil' do
      result = SgiApiServices::GroupDocument.basename('IDO0001_AC_2020T1_1005_001_001.pdf')
      expect(result).to be_nil
    end

    it 'returns nil' do
      result = SgiApiServices::GroupDocument.basename('IDO0001_AC_2020_1005_001_001.pdf')
      expect(result).to be_nil
    end

    it 'returns nil' do
      result = SgiApiServices::GroupDocument.basename('IDO_0001_AC_2020_005_001_001.pdf')
      expect(result).to be_nil
    end

    it 'returns nil' do
      result = SgiApiServices::GroupDocument.basename('IDO_0001_AC_2020T1_005_001_001.pdf')
      expect(result).to be_nil
    end

    it 'returns nil' do
      result = SgiApiServices::GroupDocument.basename('IDO_0001_AC_2020_005_001_001.pdf')
      expect(result).to be_nil
    end

    it 'returns nil' do
      result = SgiApiServices::GroupDocument.basename('IDO_0001_AC_2020_1005_001_001.pdf')
      expect(result).to be_nil
    end

    it 'returns nil' do
      result = SgiApiServices::GroupDocument.basename('IDO_0001_AC_2020T1_1005_001_001.pdf')
      expect(result).to be_nil
    end

    it 'returns nil' do
      result = SgiApiServices::GroupDocument.basename('IDO_0001_AC_2020_1005_001_001.pdf')
      expect(result).to be_nil
    end
  end

  describe '.execute', :execute do
    # Disable transactionnal database clean, needed for multi-thread
    before(:all) { DatabaseCleaner.clean }
    after(:all)  { DatabaseCleaner.start }
    # And clean with truncation instead
    after(:each) do
      Timecop.return
      DatabaseCleaner.clean_with(:truncation)
    end

    before(:each) do
      Timecop.freeze(Time.local(2020,06,12,0,1,0))

      organization = FactoryBot.create :organization, code: 'IDO'
      @user = FactoryBot.create(:user, code: 'IDO%0001', organization_id: organization.id)
      FactoryBot.create(:account_book_type, :journal_with_preassignment, user_id: @user.id, name: 'AC', description: '( Achat )')
      Settings.create(key: nil, is_journals_modification_authorized: "0", notify_errors_to: ["jean@idocus.com", "mina@idocus.com", "paul@idocus.com"])

      @temp_pack = TempPack.find_or_create_by_name 'IDO%0001 AC 202006 all'
    end

    context 'with errors', :with_errors do
      it 'has invalid temp pack name', :has_invalid_temp_pack_name do
        has_invalid_temp_pack_name = {
          pack_name: 'IDO0001_AC_2020',
          pieces: [ 
           [
             {
               id: 1,
               pages: [2,3]
             },
             {
               id: 2,
               pages: [1]
             }
            ]
          ]
        }
        params_content = ActionController::Parameters.new(has_invalid_temp_pack_name)
        group_document = SgiApiServices::GroupDocument.new(params_content)

        response = group_document.execute

        expect(response['pack_name_unknown']).to eq 'Pack name : IDO0001_AC_2020, unknown.'
      end

      it 'basename match but position is unknown', :parent_temp_document_unknown do
        parent_temp_document_unknown = {
          pack_name: 'IDO%0001_AC_202006',
          pieces: [ 
            [
             { 
               id: 1,
               pages: [1]
             }
            ]
          ]
        }

        params_content = ActionController::Parameters.new(parent_temp_document_unknown)
        group_document = SgiApiServices::GroupDocument.new(params_content)

        response = group_document.execute

        expect(response['parent_temp_document_unknown']).to eq 'Unknown temp document with an id: 1 in pack name: IDO%0001_AC_202006.'
      end

      it 'Piece already bundled', :piece_already_bundled do
        temp_document = TempDocument.new
        temp_document.temp_pack      = @temp_pack
        temp_document.user           = @user
        temp_document.organization   = @user.organization
        temp_document.position       = 2
        temp_document.pages_number   = 5
        temp_document.delivered_by   = 'test'
        temp_document.delivery_type  = 'upload'
        temp_document.is_an_original = true
        temp_document.is_a_cover     = false
        temp_document.state          = 'bundled'
        temp_document.save

        piece_already_bundled = {
          pack_name: 'IDO%0001 AC 202006',
          pieces: [ 
           [
             {
               id: 1,
               pages: [2,3]
             }
            ]
          ]
        }

        params_content = ActionController::Parameters.new(piece_already_bundled)
        group_document = SgiApiServices::GroupDocument.new(params_content)

        response = group_document.execute

        expect(response['piece_already_bundled']).to eq 'Piece already bundled with an id : 1 in pack name: IDO%0001 AC 202006.'
      end
    end

    context 'without errors', :without_errors do
      it 'successfully bundled documents', :bundled_documents do
        5.times do |i|
          temp_document = TempDocument.new
          temp_document.temp_pack      = @temp_pack
          temp_document.user           = @user
          temp_document.organization   = @user.organization
          temp_document.position       = 1+i
          temp_document.delivered_by   = 'test'
          temp_document.delivery_type  = 'scan'
          temp_document.pages_number   = 5
          temp_document.is_an_original = true
          temp_document.is_a_cover     = false
          temp_document.state          = 'bundle_needed'

          file = File.open("#{Rails.root}/spec/support/files/5pages.pdf", "r")

          temp_document.cloud_content_object.attach(file, "IDO_0001_AC_202006_00#{i + 1}.pdf") if temp_document.save
        end

        @temp_pack.update(position_counter: 2)

        bundled_documents = {
          pack_name: 'IDO%0001 AC 202006',
          pieces: [ 
             [
               { 
                 id: 1,
                 pages: [1,4]
               }
             ],
             [
               {
                 id: 3,
                 pages: [2,4]
               },
               {
                 id: 4,
                 pages: [3]
               }
             ],
             [
               {
                 id: 2,
                 pages: [2,3]
               },
               {
                 id: 5,
                 pages: [1, 4, 5]
               }
             ]
          ]
        }

        params_content = ActionController::Parameters.new(bundled_documents)
        group_document = SgiApiServices::GroupDocument.new(params_content)

        response = group_document.execute

        new_temp_documents = @temp_pack.temp_documents.where(content_file_name: "IDO%0001_AC_202006")

        expect(response[:success]).to be true
        expect(@temp_pack.temp_documents.count).to eq 8
        expect(@temp_pack.temp_documents.bundled.count).to eq 5
        expect(@temp_pack.temp_documents.ready.count).to eq 3
        expect(DocumentTools.pages_number(new_temp_documents.first.cloud_content_object.path)).to eq 2
        expect(DocumentTools.pages_number(new_temp_documents.last.cloud_content_object.path)).to eq 5
        expect(new_temp_documents.last.scan_bundling_document_ids).to eq [2, 5]
        expect(new_temp_documents.last.parents_documents_pages).to eq [{ parent_document_id: 2, pages: [2,3] }, { parent_document_id: 5, pages: [1, 4, 5] }]
      end
    end
  end
end
