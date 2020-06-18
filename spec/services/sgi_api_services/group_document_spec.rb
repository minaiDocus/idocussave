# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe SgiApiServices::GroupDocument do
  before(:all) do
      Timecop.freeze(Time.local(2020,06,12,0,1,0))
    end

    after(:all) do
      Timecop.return
    end
  describe '.position' do
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

  describe '.basename' do
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

  describe '.execute' do
    before(:each) do
      DatabaseCleaner.start
      #Timecop.freeze(Time.local(2020,06,12,0,1,0))

      organization = FactoryBot.create :organization, code: 'IDO'
      @user = FactoryBot.create(:user, code: 'IDO%0001', organization_id: organization.id)
      FactoryBot.create(:account_book_type, :journal_with_preassignment, user_id: @user.id, name: 'AC', description: '( Achat )')
      Settings.create(key: nil, is_journals_modification_authorized: "0", notify_errors_to: ["jean@idocus.com", "mina@idocus.com", "paul@idocus.com"])

      @temp_pack = TempPack.find_or_create_by_name 'IDO%0001 AC 202006 all'
    end

    after(:each) do
      @temp_pack.destroy
      #Timecop.return
      DatabaseCleaner.clean
    end

    context 'with errors' do
      it 'has invalid temp pack name', :has_invalid_temp_pack_name do
        has_invalid_temp_pack_name = {
          "packs": [
            {
              "id": 1,
              "name": "IDO0001_AC_2020",
              "pieces": [
                {
                  "id": 1,
                  "file_name": "IDO_0001_AC_2020_001.pdf",
                  "origin": "scan",
                  "piece_url": "https://my.idocus.com/account/documents/pieces/2555008/download/original?token=2tigcmsx1as221a05fyx605arspo3bihz7giei7t7sp4iq8ht9"
                },
                {
                  "id": 2,
                  "file_name": "IDO_0001_AC_2020_002.pdf",
                  "origin": "scan",
                  "piece_url": "https://my.idocus.com/account/documents/pieces/2554873/download/original?token=qchrgvrzi5ws3623da63u9cfa561zc1h6s5df76wx2kh00mt2"
                }
              ]
            }
          ]
        }
        params_content = ActionController::Parameters.new(has_invalid_temp_pack_name)
        group_document = SgiApiServices::GroupDocument.new(params_content)

        response = group_document.execute

        expect(response['pack_name_unknown_with_pack_id_1']).to eq 'Pack name : "IDO0001_AC_2020", unknown.'
      end

      it 'has invalid origin', :has_invalid_origin do
        has_invalid_origin = {
          "packs": [
            {
              "id": 1,
              "name": "IDO%0001_AC_202006",
              "pieces": [
                {
                  "id": 1,
                  "file_name": "IDO_0001_AC_2020_001.pdf",
                  "origin": "fake",
                  "piece_url": "FAKE_PIECE_URL_IDO_0001_AC_2020_001.pdf"
                },
                {
                  "id": 2,
                  "file_name": "IDO_0001_AC_2020_002.pdf",
                  "origin": "scan",
                  "piece_url": "https://my.idocus.com/account/documents/pieces/2555008/download/original?token=2tigcmsx1as221a05fyx605arspo3bihz7giei7t7sp4iq8ht9"
                }
              ]
            }
          ]
        }

        params_content = ActionController::Parameters.new(has_invalid_origin)
        group_document = SgiApiServices::GroupDocument.new(params_content)

        response = group_document.execute

        expect(response['piece_origin_unknown_with_piece_id_1']).to eq 'Piece origin : "fake", unknown.'
      end

      it 'does not match origin "scan"', :doesnot_match_origin_scan do
        doesnot_match_origin_scan = {
          "packs": [
            {
              "id": 1,
              "name": "IDO%0001_AC_202006",
              "pieces": [
                {
                  "id": 1,
                  "file_name": "IDO_0001_AC_2020_002_001.pdf",
                  "origin": "scan",
                  "piece_url": "https://my.idocus.com/account/documents/pieces/2555008/download/original?token=2tigcmsx1as221a05fyx605arspo3bihz7giei7t7sp4iq8ht9"
                }
              ]
            }
          ]
        }
        params_content = ActionController::Parameters.new(doesnot_match_origin_scan)
        group_document = SgiApiServices::GroupDocument.new(params_content)

        response = group_document.execute

        expect(response['file_name_does_not_match_origin_with_piece_id_1']).to eq 'File name : "IDO_0001_AC_2020_002_001.pdf", does not match origin : "scan".'
      end

      it 'does not match origin "upload"', :doesnot_match_origin_upload do
        doesnot_match_origin_upload = {
          "packs": [
            {
              "id": 1,
              "name": "IDO%0001_AC_202006",
              "pieces": [
                {
                  "id": 2,
                  "file_name": "IDO_0001_AC_2020_002.pdf",
                  "origin": "upload",
                  "piece_url": "https://my.idocus.com/account/documents/pieces/2559604/download/original?token=244owwqjv0ifxqmaqfclx85srtafsyth1r1mrzepsep7me2ccm"
                }
              ]
            }
          ]
        }
        params_content = ActionController::Parameters.new(doesnot_match_origin_upload)
        group_document = SgiApiServices::GroupDocument.new(params_content)

        response = group_document.execute

        expect(response['file_name_does_not_match_origin_with_piece_id_2']).to eq 'File name : "IDO_0001_AC_2020_002.pdf", does not match origin : "upload".'
      end

      it 'basename match but position is unknown', :file_names_unknown do
        file_names_unknown = {
          "packs": [
            {
              "id": 1,
              "name": "IDO%0001_AC_202006",
              "pieces": [
                {
                  "id": 1,
                  "file_name": "IDO_0001_AC_2020_001.pdf",
                  "origin": "scan",
                  "piece_url": "https://my.idocus.com/account/documents/pieces/2554873/download/original?token=qchrgvrzi5ws3623da63u9cfa561zc1h6s5df76wx2kh00mt2"
                },
                {
                  "id": 2,
                  "file_name": "IDO_0001_AC_2020_002.pdf",
                  "origin": "scan",
                  "piece_url": "https://my.idocus.com/account/documents/pieces/2555008/download/original?token=2tigcmsx1as221a05fyx605arspo3bihz7giei7t7sp4iq8ht9"
                }
              ]
            }
          ]
        }

        params_content = ActionController::Parameters.new(file_names_unknown)
        group_document = SgiApiServices::GroupDocument.new(params_content)

        response = group_document.execute

        expect(response['file_name_unknown_with_piece_id_1']).to eq 'File name : "IDO_0001_AC_2020_002.pdf", unknown.'
        expect(response['file_name_unknown_with_piece_id_2']).to eq 'File name : "IDO_0001_AC_2020_002.pdf", unknown.'
      end

      it 'basename does not match but position match', :basename_doesnt_match do
        temp_document = TempDocument.new
        temp_document.temp_pack      = @temp_pack
        temp_document.user           = @user
        temp_document.organization   = @user.organization
        temp_document.position       = 1
        temp_document.pages_number   = 2
        temp_document.is_an_original = true
        temp_document.is_a_cover     = false
        temp_document.state          = 'bundling'
        temp_document.save

        temp_document = TempDocument.new
        temp_document.temp_pack      = @temp_pack
        temp_document.user           = @user
        temp_document.organization   = @user.organization
        temp_document.position       = 2
        temp_document.pages_number   = 2
        temp_document.is_an_original = true
        temp_document.is_a_cover     = false
        temp_document.state          = 'bundling'
        temp_document.save

        file_names_unknown = {
          "packs": [
            {
              "id": 1,
              "name": "IDO%0001_AC_202006",
              "pieces": [
                {
                  "id": 1,
                  "file_name": "IDO_0001_AC_2020_001.pdf",
                  "origin": "scan",
                  "piece_url": "https://my.idocus.com/account/documents/pieces/2559604/download/original?token=244owwqjv0ifxqmaqfclx85srtafsyth1r1mrzepsep7me2ccm"
                },
                {
                  "id": 2,
                  "file_name": "IDO_0001_AC_2020_002.pdf",
                  "origin": "scan",
                  "piece_url": "https://my.idocus.com/account/documents/pieces/2554873/download/original?token=qchrgvrzi5ws3623da63u9cfa561zc1h6s5df76wx2kh00mt2"
                }
              ]
            }
          ]
        }

        params_content = ActionController::Parameters.new(file_names_unknown)
        group_document = SgiApiServices::GroupDocument.new(params_content)

        response = group_document.execute

        expect(response['file_name_unknown_with_piece_id_1']).to eq 'File name : "IDO_0001_AC_2020_002.pdf", unknown.'
        expect(response['file_name_unknown_with_piece_id_2']).to eq 'File name : "IDO_0001_AC_2020_002.pdf", unknown.'
      end

      it 'file not found', :file_not_found do
        temp_document = TempDocument.new
        temp_document.temp_pack      = @temp_pack
        temp_document.user           = @user
        temp_document.organization   = @user.organization
        temp_document.position       = 1
        temp_document.pages_number   = 2
        temp_document.delivered_by   = 'test'
        temp_document.delivery_type  = 'scan'
        temp_document.is_an_original = true
        temp_document.is_a_cover     = false
        temp_document.state          = 'bundling'
        temp_document.save

        file_not_found = {
          "packs": [
            {
              "id": 1,
              "name": "IDO%0001_AC_202006",
              "pieces": [
                {
                  "id": 1,
                  "file_name": "IDO_0001_AC_202006_001.pdf",
                  "origin": "scan",
                  "piece_url": "http://localhost:3000/account/documents/pieces/1/download/original?token=arq4s5fy0vsna0kkwv4gmz9jawmoliftgxup5b56hii7jd1pw0"
                }
              ]
            }
          ]
        }
        params_content = ActionController::Parameters.new(file_not_found)
        group_document = SgiApiServices::GroupDocument.new(params_content)

        response = group_document.execute

        expect(response['undownloadable_file_for_piece_id_1']).to eq 'File name : "IDO_0001_AC_202006_001.pdf" and piece_url: "http://localhost:3000/account/documents/pieces/1/download/original?token=arq4s5fy0vsna0kkwv4gmz9jawmoliftgxup5b56hii7jd1pw0", not found.'
      end

      it 'has 1 duplicate', :has_1_duplicate do
        has_1_duplicate = {
          "packs": [
            {
              "id": 1,
              "name": "IDO%0001_AC_202006",
              "pieces": [
                {
                  "id": 1,
                  "file_name": "IDO_0001_AC_2020_001.pdf",
                  "origin": "scan",
                  "piece_url": "https://my.idocus.com/account/documents/pieces/2559604/download/original?token=244owwqjv0ifxqmaqfclx85srtafsyth1r1mrzepsep7me2ccm"
                },
                {
                  "id": 2,
                  "file_name": "IDO_0001_AC_2020_002.pdf",
                  "origin": "scan",
                  "piece_url": "https://my.idocus.com/account/documents/pieces/2559612/download/original?token=h86h38dkd5fy4oup49d9nffvau5jgpuhwynkejupzjjx9ithe6"
                },
                {
                  "id": 3,
                  "file_name": "IDO_0001_AC_2020_002.pdf",
                  "origin": "scan",
                  "piece_url": "https://my.idocus.com/account/documents/pieces/2555008/download/original?token=2tigcmsx1as221a05fyx605arspo3bihz7giei7t7sp4iq8ht9"
                },
                {
                  "id": 4,
                  "file_name": "IDO_0001_AC_2020_003.pdf",
                  "origin": "scan",
                  "piece_url": "https://my.idocus.com/account/documents/pieces/2554873/download/original?token=qchrgvrzi5ws3623da63u9cfa561zc1h6s5df76wx2kh00mt2"
                }
              ]
            }
          ]
        }

        params_content = ActionController::Parameters.new(has_1_duplicate)
        group_document = SgiApiServices::GroupDocument.new(params_content)

        response = group_document.execute
        expect(response['file_name_duplicated_with_pack_id_1']).to eq 'File name : 1 duplicate(s).'
      end

      it 'is already grouped', :temp_document_already_grouped do
        temp_document = TempDocument.new
        temp_document.temp_pack      = @temp_pack
        temp_document.user           = @user
        temp_document.organization   = @user.organization
        temp_document.position       = 2
        temp_document.pages_number   = 2
        temp_document.delivered_by   = 'test'
        temp_document.delivery_type  = 'scan'
        temp_document.is_an_original = true
        temp_document.is_a_cover     = false
        temp_document.state          = 'bundled'
        temp_document.save

        temp_document_already_grouped = {
          "packs": [
            {
              "id": 1,
              "name": "IDO%0001_AC_202006",
              "pieces": [
                {
                  "id": 1,
                  "file_name": "IDO_0001_AC_202006_002.pdf",
                  "origin": "scan",
                  "piece_url": "https://my.idocus.com/account/documents/pieces/2554873/download/original?token=qchrgvrzi5ws3623da63u9cfa561zc1h6s5df76wx2kh00mt2"
                }
              ]
            }
          ]
        }
        params_content = ActionController::Parameters.new(temp_document_already_grouped)
        group_document = SgiApiServices::GroupDocument.new(params_content)

        response = group_document.execute

        expect(response['file_name_already_grouped_with_piece_id_1']).to eq 'File name : "IDO_0001_AC_202006_002.pdf", already grouped.'
      end
    end

    context 'without errors' do
      it 'successfully group scanned documents', :group_scanned_document do
        2.times do |i|
          temp_document = TempDocument.new
          temp_document.temp_pack      = @temp_pack
          temp_document.user           = @user
          temp_document.organization   = @user.organization
          temp_document.position       = 1+i
          temp_document.delivered_by   = 'test'
          temp_document.delivery_type  = 'scan'
          temp_document.pages_number   = i == 0 ? 2 : 1
          temp_document.is_an_original = true
          temp_document.is_a_cover     = false
          temp_document.state          = 'bundling'
          temp_document.save
        end

        @temp_pack.update(position_counter: 2)

        group_scanned_document = {
          "packs": [
            {
              "id": 1,
              "name": "IDO%0001_AC_202006",
              "pieces": [
                {
                  "id": 1,
                  "file_name": "IDO_0001_AC_202006_001.pdf",
                  "origin": "scan",
                  "piece_url": "https://my.idocus.com/account/documents/pieces/2554873/download/original?token=qchrgvrzi5ws3623da63u9cfa561zc1h6s5df76wx2kh00mt2"
                },
                {
                  "id": 2,
                  "file_name": "IDO_0001_AC_202006_002.pdf",
                  "origin": "scan",
                  "piece_url": "https://my.idocus.com/account/documents/pieces/2555008/download/original?token=2tigcmsx1as221a05fyx605arspo3bihz7giei7t7sp4iq8ht9"
                }
              ]
            }
          ]
        }

        params_content = ActionController::Parameters.new(group_scanned_document)
        group_document = SgiApiServices::GroupDocument.new(params_content)

        response = group_document.execute

        new_temp_document1 = @temp_pack.temp_documents.where(content_file_name: "IDO_0001_AC_202006_001").first
        new_temp_document2 = @temp_pack.temp_documents.where(content_file_name: "IDO_0001_AC_202006_002").first
        expect(response[:success]).to be true
        expect(@temp_pack.temp_documents.count).to eq 4
        expect(@temp_pack.temp_documents.bundled.count).to eq 2
        expect(@temp_pack.temp_documents.ready.count).to eq 2
        expect(DocumentTools.pages_number(new_temp_document1.cloud_content_object.path)).to eq 2
        expect(DocumentTools.pages_number(new_temp_document2.cloud_content_object.path)).to eq 1
      end

      it 'successfully group uploaded documents', :group_uploaded_document do
        3.times do |i|
          temp_document = TempDocument.new
          temp_document.temp_pack      = @temp_pack
          temp_document.user           = @user
          temp_document.organization   = @user.organization
          temp_document.position       = 1+i
          temp_document.delivered_by   = 'test'
          temp_document.delivery_type  = 'upload'
          temp_document.pages_number   = i == 0 ? 2 : 1
          temp_document.is_an_original = true
          temp_document.is_a_cover     = false
          temp_document.state          = 'bundling'
          temp_document.save
        end

        @temp_pack.update(position_counter: 2)

        group_uploaded_document = {
          "packs": [
            {
              "id": 1,
              "name": "IDO%0001_AC_202006",
              "pieces": [
                {
                  "id": 1,
                  "file_name": "IDO_0001_AC_202006_001_001.pdf",
                  "origin": "upload",
                  "piece_url": "https://my.idocus.com/account/documents/pieces/2559612/download/original?token=h86h38dkd5fy4oup49d9nffvau5jgpuhwynkejupzjjx9ithe6"
                },
                {
                  "id": 2,
                  "file_name": "IDO_0001_AC_202006_002_002.pdf",
                  "origin": "upload",
                  "piece_url": "https://my.idocus.com/account/documents/pieces/2559604/download/original?token=244owwqjv0ifxqmaqfclx85srtafsyth1r1mrzepsep7me2ccm"
                },
                {
                  "id": 3,
                  "file_name": "IDO_0001_AC_202006_003_003.pdf",
                  "origin": "upload",
                  "piece_url": "https://my.idocus.com/account/documents/pieces/2559605/download/original?token=cnffqr74zhaa89e8hajbengb1m0b6yvr59zetgps3020omfffn"
                }
              ]
            }
          ]
        }

        params_content = ActionController::Parameters.new(group_uploaded_document)
        group_document = SgiApiServices::GroupDocument.new(params_content)

        response = group_document.execute

        new_temp_document_1 = @temp_pack.temp_documents.where(content_file_name: "IDO_0001_AC_202006_001_001").first
        new_temp_document_2 = @temp_pack.temp_documents.where(content_file_name: "IDO_0001_AC_202006_002_002").first
        new_temp_document_3 = @temp_pack.temp_documents.where(content_file_name: "IDO_0001_AC_202006_003_003").first
        expect(response[:success]).to be true
        expect(@temp_pack.temp_documents.count).to eq 6
        expect(@temp_pack.temp_documents.bundled.count).to eq 3
        expect(@temp_pack.temp_documents.ready.count).to eq 3
        expect(DocumentTools.pages_number(new_temp_document_1.cloud_content_object.path)).to eq 2
        expect(DocumentTools.pages_number(new_temp_document_2.cloud_content_object.path)).to eq 1
        expect(DocumentTools.pages_number(new_temp_document_3.cloud_content_object.path)).to eq 1
      end

      it 'successfully group dematbox scanned documents', :group_dematbox_scanned_document do
        5.times do |i|
          temp_document = TempDocument.new
          temp_document.temp_pack      = @temp_pack
          temp_document.user           = @user
          temp_document.organization   = @user.organization
          temp_document.position       = 1+i
          temp_document.delivered_by   = 'test'
          temp_document.delivery_type  = 'dematbox_scan'
          temp_document.pages_number   = 1
          temp_document.is_an_original = true
          temp_document.is_a_cover     = false
          temp_document.state          = 'bundling'
          temp_document.save
        end

        @temp_pack.update(position_counter: 2)

        group_dematbox_scanned_document = {
          "packs": [
            {
              "id": 1,
              "name": "IDO%0001_AC_202006",
              "pieces": [
                {
                  "id": 1,
                  "file_name": "IDO_0001_AC_202006_004_001.pdf",
                  "origin": "dematbox_scan",
                  "piece_url": "https://my.idocus.com/account/documents/pieces/2559611/download/original?token=s2vpt8vi9fmhzq51vkz4rcnenbs6hl7poqk6yuseowp8os9ebu"
                },
                {
                  "id": 2,
                  "file_name": "IDO_0001_AC_202006_004_002.pdf",
                  "origin": "dematbox_scan",
                  "piece_url": "https://my.idocus.com/account/documents/pieces/2559610/download/original?token=f5xru8n9zyh9ug8kvy5kw5o6c4av29cki354e5m33rq2qgevlk"
                },
                {
                  "id": 3,
                  "file_name": "IDO_0001_AC_202006_005_003.pdf",
                  "origin": "dematbox_scan",
                  "piece_url": "https://my.idocus.com/account/documents/pieces/2559608/download/original?token=m9s5kjr4dcrq56pmyvy6rsx0wl2vn2w4u98rcv80d1nrxg7r2t"
                },
                {
                  "id": 4,
                  "file_name": "IDO_0001_AC_202006_005_004.pdf",
                  "origin": "dematbox_scan",
                  "piece_url": "https://my.idocus.com/account/documents/pieces/2559607/download/original?token=hr4ly9pvfz3dysmztdhz7lj598cqzp79ysdpls1jkg2i5iuebb"
                },
                {
                  "id": 5,
                  "file_name": "IDO_0001_AC_202006_004_005.pdf",
                  "origin": "dematbox_scan",
                  "piece_url": "https://my.idocus.com/account/documents/pieces/2559237/download/original?token=7i5kejgidxsxv6ba83kmbabexheetx9ouk0bvql32jrkzqs8em"
                }
              ]
            }
          ]
        }

        params_content = ActionController::Parameters.new(group_dematbox_scanned_document)
        group_document = SgiApiServices::GroupDocument.new(params_content)

        response = group_document.execute

        new_temp_document_1 = @temp_pack.temp_documents.where(content_file_name: "IDO_0001_AC_202006_004_001").first
        new_temp_document_2 = @temp_pack.temp_documents.where(content_file_name: "IDO_0001_AC_202006_004_002").first
        new_temp_document_3 = @temp_pack.temp_documents.where(content_file_name: "IDO_0001_AC_202006_005_003").first
        new_temp_document_4 = @temp_pack.temp_documents.where(content_file_name: "IDO_0001_AC_202006_005_004").first
        new_temp_document_5 = @temp_pack.temp_documents.where(content_file_name: "IDO_0001_AC_202006_004_005").first
        expect(response[:success]).to be true
        expect(@temp_pack.temp_documents.count).to eq 10
        expect(@temp_pack.temp_documents.bundled.count).to eq 2
        expect(@temp_pack.temp_documents.ready.count).to eq 5
        expect(DocumentTools.pages_number(new_temp_document_1.cloud_content_object.path)).to eq 1
        expect(DocumentTools.pages_number(new_temp_document_2.cloud_content_object.path)).to eq 2
        expect(DocumentTools.pages_number(new_temp_document_3.cloud_content_object.path)).to eq 1
        expect(DocumentTools.pages_number(new_temp_document_4.cloud_content_object.path)).to eq 1
        expect(DocumentTools.pages_number(new_temp_document_5.cloud_content_object.path)).to eq 5
      end
    end
  end
end
