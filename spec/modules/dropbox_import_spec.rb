# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe DropboxImport do
  before(:all) do
    Timecop.freeze(Time.local(2015,2,15))
  end

  after(:all) do
    Timecop.return
  end

  describe '#check' do
    context 'as customer' do
      before(:all) do
        @user = FactoryGirl.create(:user, code: 'TS%0001')
        @user.options = UserOptions.create(user_id: @user.id)

        AccountBookType.create(user_id: @user.id, name: 'AC', description: '( Achat )')
        AccountBookType.create(user_id: @user.id, name: 'VT', description: '( Vente )')

        efs = @user.find_or_create_external_file_storage
        efs.use ExternalFileStorage::F_DROPBOX
        @dropbox = efs.dropbox_basic
        @dropbox.access_token = '65XiB3QDfDUAAAAAAAAGzhf645c8M07MSCFxz4il6O72MfyHrPUT0W0jP0nmIfZN'
        @dropbox.save

        @user.reload

        @headers = {
          'Accept'        => '*/*',
          'Authorization' => 'Bearer 65XiB3QDfDUAAAAAAAAGzhf645c8M07MSCFxz4il6O72MfyHrPUT0W0jP0nmIfZN',
          'User-Agent'    => 'OfficialDropboxRubySDK/1.6.5'
        }

        @headers_2 = @headers.merge({
          'Content-Type'  => 'application/x-www-form-urlencoded',
        })
      end

      after(:all) do
        DatabaseCleaner.clean
      end

      after(:each) do
        TempPack.delete_all
        TempDocument.delete_all
      end

      it 'creates initial folders' do
        VCR.use_cassette('dropbox_import/customer/creates_initial_folders') do
          DropboxImport.new(@dropbox).check
        end

        folder_paths = [
          '/exportation vers iDocus/TS%0001 - TeSt/période actuelle/AC',
          '/exportation vers iDocus/TS%0001 - TeSt/période actuelle/VT',
          '/exportation vers iDocus/TS%0001 - TeSt/période précédente/AC',
          '/exportation vers iDocus/TS%0001 - TeSt/période précédente/VT'
        ]

        # delta
        expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/delta').
          with(headers: @headers_2).
          with(body: "path_prefix=#{CGI::escape('/exportation vers iDocus/TS%0001 - TeSt')}")
        # creates folder '/exportation vers iDocus/TS%0001 - TeSt/période actuelle/AC'
        expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder').
          with(headers: @headers_2).with(body: "root=sandbox&path=#{CGI::escape(folder_paths[0])}")
        # creates folder '/exportation vers iDocus/TS%0001 - TeSt/période actuelle/VT'
        expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder').
          with(headers: @headers_2).with(body: "root=sandbox&path=#{CGI::escape(folder_paths[1])}")
        # creates folder '/exportation vers iDocus/TS%0001 - TeSt/période précédente/AC'
        expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder').
          with(headers: @headers_2).with(body: "root=sandbox&path=#{CGI::escape(folder_paths[2])}")
        # creates folder '/exportation vers iDocus/TS%0001 - TeSt/période précédente/VT'
        expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder').
          with(headers: @headers_2).with(body: "root=sandbox&path=#{CGI::escape(folder_paths[3])}")

        expect(WebMock).to have_requested(:any, /.*/).times(5)

        expect(@dropbox.checked_at).to be_present
        expect(@dropbox.delta_cursor).to be_present
        expect(@dropbox.delta_path_prefix).to eq('/exportation vers iDocus/TS%0001 - TeSt')
        expect(@dropbox.import_folder_paths).to eq(folder_paths)
      end

      context 'given initial folders have been created' do
        before(:each) do
          @dropbox.delta_path_prefix = '/exportation vers iDocus/TS%0001 - TeSt'
          @dropbox.import_folder_paths = [
            '/exportation vers iDocus/TS%0001 - TeSt/période actuelle/AC',
            '/exportation vers iDocus/TS%0001 - TeSt/période actuelle/VT',
            '/exportation vers iDocus/TS%0001 - TeSt/période précédente/AC',
            '/exportation vers iDocus/TS%0001 - TeSt/période précédente/VT'
          ]
        end

        context 'given a valid file at : /exportation vers iDocus/TS%0001 - TeSt/période actuelle/AC/test.pdf' do
          it 'fetches one valid file' do
            delta_cursor = @dropbox.delta_cursor = 'AAHUYFz8b09BNdQnXbWzcMx1onR8cUW1DO4QsuuDTvXQAaXaT-aaOD_oeztZp1WrR52g2avgtXRjrw5k2fWTnKdojCoGxnV4VkuN334RireEhKOiPaEL9RwCgPd2q7uEiXIRrVv5oEmIf_1XrXqtLtlUtHek9Da3ZMkEi8fXLaIOpqUWOjO1ipjLOzYigMYMbp4'
            @dropbox.save

            VCR.use_cassette('dropbox_import/customer/fetches_one_valid_file') do
              DropboxImport.new(@dropbox).check
            end

            # delta
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/delta').
              with(headers: @headers_2).
              with(body: "cursor=#{delta_cursor}&path_prefix=#{CGI::escape('/exportation vers iDocus/TS%0001 - TeSt')}")
            # get file
            expect(WebMock).to have_requested(:get, 'https://api-content.dropbox.com/1/files/sandbox/exportation%20vers%20idocus/ts%250001%20-%20test/p%C3%A9riode%20actuelle/ac/test.pdf').
              with(headers: @headers)
            # delete file
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/delete').
              with(headers: @headers_2).
              with(body: "root=sandbox&path=#{CGI::escape('/exportation vers iDocus/TS%0001 - TeSt/période actuelle/AC/test.pdf'.downcase)}")

            expect(WebMock).to have_requested(:any, /.*/).times(3)

            temp_pack = TempPack.where(name: 'TS%0001 AC 201502 all').first
            temp_document = temp_pack.temp_documents.first
            signature = `md5sum #{temp_document.content.path}`.split.first
            expect(temp_pack.temp_documents.count).to eq 1
            expect(temp_document.original_file_name).to eq 'test.pdf'
            expect(signature).to eq '19738ae94972dbcb343df344a1cfa775'
          end
        end

        context 'given an invalid file at : /exportation vers iDocus/TS%0001 - TeSt/période actuelle/AC/corrupted.pdf' do
          it 'marks one invalid file' do
            delta_cursor = @dropbox.delta_cursor = 'AAHvNtByv6vt4jX-RTfuwQ473Lk7IfzEsEKKcuALOWX5WqWNI313siq-aYS7_UCiK0742nh64Ic0skeE7z7goiyhL9I1O0I8Tq5UcA7WJnVlGYct7TPgVtvDPAOFdnNmZx5E-v1M8-dgXcMvdri4Q4EdGFgtg3elKaYPsSXcGqHJq9NHQpfNMeOKuLcBnzpAOqY'
            @dropbox.save

            VCR.use_cassette('dropbox_import/customer/marks_one_invalid_file') do
              DropboxImport.new(@dropbox).check
            end

            # delta
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/delta').
              with(headers: @headers_2).
              with(body: "cursor=#{delta_cursor}&path_prefix=#{CGI::escape('/exportation vers iDocus/TS%0001 - TeSt')}")
            # get file
            expect(WebMock).to have_requested(:get, 'https://api-content.dropbox.com/1/files/sandbox/exportation%20vers%20idocus/ts%250001%20-%20test/p%C3%A9riode%20actuelle/ac/corrupted.pdf').
              with(headers: @headers)
            # rename file
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/move').
              with(headers: @headers_2).
              with(body: 'root=sandbox&from_path=%2Fexportation%C2%A0vers+idocus%2Fts%250001+-+test%2Fp%C3%A9riode+actuelle%2Fac%2Fcorrupted.pdf&to_path=%2Fexportation%C2%A0vers+idocus%2Fts%250001+-+test%2Fp%C3%A9riode+actuelle%2Fac%2Fcorrupted+%28erreur+fichier+non+valide+pour+iDocus%29.pdf')

            expect(WebMock).to have_requested(:any, /.*/).times(3)

            temp_pack = TempPack.where(name: 'TS%0001 AC 201502 all').first
            expect(temp_pack).to be_nil
          end
        end

        context 'given an invalid file already marked at : /exportation vers iDocus/TS%0001 - TeSt/période actuelle/AC/corrupted (erreur fichier non valide pour idocus).pdf' do
          it 'ignores one file marked invalid' do
            delta_cursor = @dropbox.delta_cursor = 'AAH-omVMlxwDei1x3DtMP1YFpKwLR_XGT939FfQ-GFXD5R8Ab_OkffQGZa8CsrCqZvnSaIobgc8FdqcuJXCTIdT799MMwjA9v_jhWdbzjlk4eX-y7dtaIw11olDPEUZNHK6X0zrkYzuvOm292adzrF2mFFWbuj9HDzkOju91gvRgJokoSWDuwgyVD786FohhrXk'
            @dropbox.save

            VCR.use_cassette('dropbox_import/customer/ignores_one_file_marked_invalid') do
              DropboxImport.new(@dropbox).check
            end

            # delta
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/delta').
              with(headers: @headers_2).
              with(body: "cursor=#{delta_cursor}&path_prefix=#{CGI::escape('/exportation vers iDocus/TS%0001 - TeSt')}")

            expect(WebMock).to have_requested(:any, /.*/).once

            temp_pack = TempPack.where(name: 'TS%0001 AC 201502 all').first
            expect(temp_pack).to be_nil
          end
        end

        context 'given a file already exist' do
          before(:all) do
            @temp_pack = TempPack.find_or_create_by_name 'TS%0001 AC 201502 all'
            @temp_pack.user = @user
            @temp_pack.save

            temp_document = TempDocument.new
            temp_document.user                = @user
            temp_document.content             = File.open(File.join(Rails.root, 'spec/support/files/2pages.pdf'))
            temp_document.position            = 1
            temp_document.temp_pack           = @temp_pack
            temp_document.original_file_name  = '2pages.pdf'
            temp_document.delivered_by        = 'Tester'
            temp_document.delivery_type       = 'upload'
            temp_document.save
          end

          it 'marks one file as already exist' do
            delta_cursor = @dropbox.delta_cursor = 'AAHvNtByv6vt4jX-RTfuwQ473Lk7IfzEsEKKcuALOWX5WqWNI313siq-aYS7_UCiK0742nh64Ic0skeE7z7goiyhL9I1O0I8Tq5UcA7WJnVlGYct7TPgVtvDPAOFdnNmZx5E-v1M8-dgXcMvdri4Q4EdGFgtg3elKaYPsSXcGqHJq9NHQpfNMeOKuLcBnzpAOqY'
            @dropbox.save

            VCR.use_cassette('dropbox_import/customer/marks_one_file_as_already_exist') do
              DropboxImport.new(@dropbox).check
            end

            # delta
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/delta').
              with(headers: @headers_2).
              with(body: "cursor=#{delta_cursor}&path_prefix=#{CGI::escape('/exportation vers iDocus/TS%0001 - TeSt')}")
            # get file
            expect(WebMock).to have_requested(:get, 'https://api-content.dropbox.com/1/files/sandbox/exportation%20vers%20idocus/ts%250001%20-%20test/p%C3%A9riode%20actuelle/ac/2pages.pdf').
              with(headers: @headers)
            # rename file
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/move').
              with(headers: @headers_2).
              with(body: 'root=sandbox&from_path=%2Fexportation%C2%A0vers+idocus%2Fts%250001+-+test%2Fp%C3%A9riode+actuelle%2Fac%2F2pages.pdf&to_path=%2Fexportation%C2%A0vers+idocus%2Fts%250001+-+test%2Fp%C3%A9riode+actuelle%2Fac%2F2pages+%28fichier+d%C3%A9j%C3%A0+import%C3%A9+sur+iDocus%29.pdf')

            expect(WebMock).to have_requested(:any, /.*/).times(3)

            expect(@temp_pack.temp_documents.count).to eq 1
          end
        end

        context 'given a file marked as already exist' do
          it 'ignores one file marked as already exist' do
            delta_cursor = @dropbox.delta_cursor = 'AAH-omVMlxwDei1x3DtMP1YFpKwLR_XGT939FfQ-GFXD5R8Ab_OkffQGZa8CsrCqZvnSaIobgc8FdqcuJXCTIdT799MMwjA9v_jhWdbzjlk4eX-y7dtaIw11olDPEUZNHK6X0zrkYzuvOm292adzrF2mFFWbuj9HDzkOju91gvRgJokoSWDuwgyVD786FohhrXk'
            @dropbox.save

            VCR.use_cassette('dropbox_import/customer/ignores_one_file_marked_as_already_exist') do
              DropboxImport.new(@dropbox).check
            end

            # delta
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/delta').
              with(headers: @headers_2).
              with(body: "cursor=#{delta_cursor}&path_prefix=#{CGI::escape('/exportation vers iDocus/TS%0001 - TeSt')}")

            expect(WebMock).to have_requested(:any, /.*/).once

            temp_pack = TempPack.where(name: 'TS%0001 AC 201502 all').first
            expect(temp_pack).to be_nil
          end
        end

        context 'given folder "/exportation vers iDocus/TS%0001 - TeSt/période précédente" is removed' do
          it 'recreates deleted folders' do
            delta_cursor = @dropbox.delta_cursor = 'AAGkvb1ZwDBvVxkgLshA58LfkBJ79YBnK-tTXKGrI-07o-s9r_QkNDDlYDwABZrXWNHT0W3tt0b2kzqMP9rT6Jugqe9fWb-OxY5A-1BZ66IHNtMOJ7EYx9vpUuBFS5fi6XKTdPzXAu5RXni5XVyghq_KSHjAQ-XHjA0T-ldbWaTr1lHdQP8byFQaFkklbqyPo1Q'
            @dropbox.save

            VCR.use_cassette('dropbox_import/customer/recreates_deleted_folders') do
              DropboxImport.new(@dropbox).check
            end

            # delta
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/delta').
              with(headers: @headers_2).
              with(body: "cursor=#{delta_cursor}&path_prefix=#{CGI::escape('/exportation vers iDocus/TS%0001 - TeSt')}")
            # create folder AC
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder').
              with(headers: @headers_2).with(body: 'root=sandbox&path=%2Fexportation%C2%A0vers+iDocus%2FTS%250001+-+TeSt%2Fp%C3%A9riode+pr%C3%A9c%C3%A9dente%2FAC')
            # create folder VT
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder').
              with(headers: @headers_2).with(body: 'root=sandbox&path=%2Fexportation%C2%A0vers+iDocus%2FTS%250001+-+TeSt%2Fp%C3%A9riode+pr%C3%A9c%C3%A9dente%2FVT')

            expect(WebMock).to have_requested(:any, /.*/).times(3)
          end
        end

        context 'given folder at "/exportation vers iDocus/TS%0001 - TeSt/période actuelle" renamed or moved to "PERIODE"' do
          it 'recreates renamed or moved folders' do
            delta_cursor = @dropbox.delta_cursor = 'AAHNv9G4Ed85Mih1-_YCl1X85MoV4KAizO1vvg06uvHavrLkBZSikJMOn8Kszf59SMQb_746_Z5LPYlhXGs-lsO6L-BRsyFrTdxy10CjbW3WLfljJ3HCnxOGJmUfEMETwkg-9Nr8Bzbr8Pmj40tc0KvqBUgWBBFYNgn31xx7wGGcnociVfxgMdF6nPlR3QPvDfU'
            @dropbox.save

            VCR.use_cassette('dropbox_import/customer/recreates_renamed_or_moved_folders') do
              DropboxImport.new(@dropbox).check
            end

            # delta
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/delta').
              with(headers: @headers_2).
              with(body: "cursor=#{delta_cursor}&path_prefix=#{CGI::escape('/exportation vers iDocus/TS%0001 - TeSt')}")
            # create folder AC
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder').
              with(headers: @headers_2).with(body: "root=sandbox&path=#{CGI::escape('/exportation vers iDocus/TS%0001 - TeSt/période actuelle/AC')}")
            # create folder VT
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder').
              with(headers: @headers_2).with(body: "root=sandbox&path=#{CGI::escape('/exportation vers iDocus/TS%0001 - TeSt/période actuelle/VT')}")

            expect(WebMock).to have_requested(:any, /.*/).times(3)
          end
        end

        context 'given journal BQ is added' do
          before(:all) do
            @journal = AccountBookType.create(user_id: @user.id, name: 'BQ', description: '( Banque )')
          end

          after(:all) do
            @journal.destroy
          end

          it 'creates 2 folders BQ' do
            delta_cursor = @dropbox.delta_cursor = 'AAGciVi-0S27vUnG74p8d4eyih-QamQRxfb5A9pmbxS6Rtlh_L4q2Mx7NCf9gEPqiXHw-KSM4mxfOPR55WwhDqTJffXz6rjVjEUDg0KVsoZN8w4OTCHPpm2mjdxteRNm2Pbi5a9Jis1Bcsc5rbrW_fVUvvVfJZ-__vjMePgWcIzaKa42DJN3yOhmlT8c_g3BqsU'
            @dropbox.save

            VCR.use_cassette('dropbox_import/customer/creates_2_folders_bq') do
              DropboxImport.new(@dropbox).check
            end

            # delta
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/delta').
              with(headers: @headers_2).
              with(body: "cursor=#{delta_cursor}&path_prefix=#{CGI::escape('/exportation vers iDocus/TS%0001 - TeSt')}")
            # create folder 'BQ' into folder 'période actuelle'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder').
              with(headers: @headers_2).with(body: "root=sandbox&path=#{CGI::escape('/exportation vers iDocus/TS%0001 - TeSt/période actuelle/BQ')}")
            # create folder 'BQ' into folder 'période précédente'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder').
              with(headers: @headers_2).with(body: "root=sandbox&path=#{CGI::escape('/exportation vers iDocus/TS%0001 - TeSt/période précédente/BQ')}")

            expect(WebMock).to have_requested(:any, /.*/).times(3)
          end
        end

        context 'given journal BQ is renamed BQ1' do
          before(:all) do
            @journal = AccountBookType.create(user_id: @user.id, name: 'BQ1', description: '( Banque )')
          end

          after(:all) do
            @journal.destroy
          end

          it 'deletes 2 folders BQ and creates 2 folders BQ1' do
            delta_cursor = @dropbox.delta_cursor = 'AAEQ6oaXeiGb3TG3jZSI4rX8zk8tq_hdWHDvzk_0D3a3wIvWxPG4ccWFO8hanJZLa2-UUuhk7drYKUPI_RA9tE46CNemdO0ThG7IfiChN2JY9A3LVUS43o-zsCpCINnTLWRLfX1yBnBLZLwGVaVlgCqoXKw0azydkrgTRDngGTUOos3_j0m8iLbANXpWLV0maFs'
            @dropbox.import_folder_paths = [
              '/exportation vers iDocus/TS%0001 - TeSt/période actuelle/AC',
              '/exportation vers iDocus/TS%0001 - TeSt/période actuelle/VT',
              '/exportation vers iDocus/TS%0001 - TeSt/période actuelle/BQ',
              '/exportation vers iDocus/TS%0001 - TeSt/période précédente/AC',
              '/exportation vers iDocus/TS%0001 - TeSt/période précédente/VT',
              '/exportation vers iDocus/TS%0001 - TeSt/période précédente/BQ'
            ]
            @dropbox.save

            VCR.use_cassette('dropbox_import/customer/deletes_2_folders_BQ_and_creates_2_folders_bq1') do
              DropboxImport.new(@dropbox).check
            end

            # delta
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/delta').
              with(headers: @headers_2).
              with(body: "cursor=#{delta_cursor}&path_prefix=#{CGI::escape('/exportation vers iDocus/TS%0001 - TeSt')}")
            # create folder 'BQ1' into folder 'période actuelle'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder').
              with(headers: @headers_2).with(body: "root=sandbox&path=#{CGI::escape('/exportation vers iDocus/TS%0001 - TeSt/période actuelle/BQ1')}")
            # create folder 'BQ1' into folder 'période précédente'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder').
              with(headers: @headers_2).with(body: "root=sandbox&path=#{CGI::escape('/exportation vers iDocus/TS%0001 - TeSt/période précédente/BQ1')}")
            # delete folder 'BQ' into folder 'période actuelle'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/delete').
              with(headers: @headers_2).with(body: "root=sandbox&path=#{CGI::escape('/exportation vers iDocus/TS%0001 - TeSt/période actuelle/BQ')}")
            # delete folder 'BQ' into folder 'période précédente'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/delete').
              with(headers: @headers_2).with(body: "root=sandbox&path=#{CGI::escape('/exportation vers iDocus/TS%0001 - TeSt/période précédente/BQ')}")

            expect(WebMock).to have_requested(:any, /.*/).times(5)
          end
        end

        context 'given journal VT is removed' do
          before(:all) do
            @user.account_book_types.where(name: 'VT').first.destroy
          end

          after(:all) do
            AccountBookType.create(user_id: @user.id, name: 'VT', description: '( Vente )')
          end

          it 'deletes 2 folders VT' do
            delta_cursor = @dropbox.delta_cursor = 'AAFXd1wVC74Y2lAlTsCfiYbXlJ-eTmmCe0mwCiJy6WVBiNuw7rSm_DUyOgOJt9_IONcUg2hEuWITupNangBXN_qhYBQMkdiY6HtstK-UwF4_JXJ2fsW423u_qPFoE5BUbR_g2OW1nsZdLaNssKnTGfuhziTfdT04c4js5BVsjNlTHXut0iSW_mxuJluM3f04H94'
            @dropbox.save

            VCR.use_cassette('dropbox_import/customer/deletes_2_folders_VT') do
              DropboxImport.new(@dropbox).check
            end

            # delta
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/delta').
              with(headers: @headers_2).
              with(body: "cursor=#{delta_cursor}&path_prefix=#{CGI::escape('/exportation vers iDocus/TS%0001 - TeSt')}")
            # delete folder 'VT' into folder 'période actuelle'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/delete').
              with(headers: @headers_2).with(body: "root=sandbox&path=#{CGI::escape('/exportation vers iDocus/TS%0001 - TeSt/période actuelle/VT')}")
            # delete folder 'VT' into folder 'période précédente'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/delete').
              with(headers: @headers_2).with(body: "root=sandbox&path=#{CGI::escape('/exportation vers iDocus/TS%0001 - TeSt/période actuelle/VT')}")

            expect(WebMock).to have_requested(:any, /.*/).times(3)
          end
        end

        context 'given journal AC is removed' do
          context 'given journal OD is created' do
            context 'given folder test is created' do
              context 'given folder période précédente is removed' do
                context 'given 2 files are present inside période actuelle/VT' do
                  it 'executes multiple jobs' do
                    @user.account_book_types.where(name: 'AC').first.destroy
                    AccountBookType.create(user_id: @user.id, name: 'OD', description: '( Opération diverse )')
                    delta_cursor = @dropbox.delta_cursor = 'AAHwJLrKrkXuhWX--5dtipzNeMDyP6uF7__k2DFEc05ugF5HpsiDHLVX2-IwLMN2-7YlsSQtodssf3vobtMUP68R26olrEJhNDirMiirohLhA6-_Tg7mzm9jfzoygBU6kzTa-2BW2B8bB51f3kjWqlrZZGmD26QPx9iGICHteQtAzJQ0VvehARaBrexA98XCUWo'
                    @dropbox.save

                    VCR.use_cassette('dropbox_import/customer/executes_multiple_jobs') do
                      DropboxImport.new(@dropbox).check
                    end

                    # delta
                    expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/delta').
                      with(headers: @headers_2).
                      with(body: "cursor=#{delta_cursor}&path_prefix=#{CGI::escape('/exportation vers iDocus/TS%0001 - TeSt')}")
                    # get corrupted file
                    expect(WebMock).to have_requested(:get, 'https://api-content.dropbox.com/1/files/sandbox/exportation%20vers%20idocus/ts%250001%20-%20test/p%C3%A9riode%20actuelle/vt/corrupted.pdf').
                      with(headers: @headers)
                    # mark corrupted file as invalid
                    expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/move').
                      with(headers: @headers_2).
                      with(body: 'root=sandbox&from_path=%2Fexportation%C2%A0vers+idocus%2Fts%250001+-+test%2Fp%C3%A9riode+actuelle%2Fvt%2Fcorrupted.pdf&to_path=%2Fexportation%C2%A0vers+idocus%2Fts%250001+-+test%2Fp%C3%A9riode+actuelle%2Fvt%2Fcorrupted+%28erreur+fichier+non+valide+pour+iDocus%29.pdf')
                    # get file
                    expect(WebMock).to have_requested(:get, 'https://api-content.dropbox.com/1/files/sandbox/exportation%20vers%20idocus/ts%250001%20-%20test/p%C3%A9riode%20actuelle/vt/test.pdf').
                      with(headers: @headers)
                    # delete file
                    expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/delete').
                      with(headers: @headers_2).
                      with(body: "root=sandbox&path=#{CGI::escape('/exportation vers iDocus/TS%0001 - TeSt/période actuelle/VT/test.pdf'.downcase)}")
                    # remove journal AC from folder période actuelle
                    expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/delete').
                      with(headers: @headers_2).with(body: "root=sandbox&path=#{CGI::escape('/exportation vers iDocus/TS%0001 - TeSt/période actuelle/AC')}")
                    # create journal OD into folder période actuelle
                    expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder').
                      with(headers: @headers_2).with(body: "root=sandbox&path=#{CGI::escape('/exportation vers iDocus/TS%0001 - TeSt/période actuelle/OD')}")
                    # create journal OD into folder période précédente
                    expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder').
                      with(headers: @headers_2).with(body: "root=sandbox&path=#{CGI::escape('/exportation vers iDocus/TS%0001 - TeSt/période précédente/OD')}")
                    # create folder VT into période précédente
                    expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder').
                      with(headers: @headers_2).with(body: "root=sandbox&path=#{CGI::escape('/exportation vers iDocus/TS%0001 - TeSt/période précédente/VT')}")

                    expect(WebMock).to have_requested(:any, /.*/).times(9)

                    expect(TempDocument.count).to eq 1
                  end
                end
              end
            end
          end
        end
      end
    end

    context 'as collaborator' do
      before(:all) do
        @organization = Organization.create(name: 'TEST', code: 'TS')

        @collaborator = FactoryGirl.create(:prescriber, code: 'TS%COL1')
        @collaborator.organization = @organization
        @collaborator.save
        @collaborator.extend_organization_role

        @user = FactoryGirl.create(:user, code: 'TS%0001', company: 'ABC')
        @user.options = UserOptions.create(user_id: @user.id)
        @user.organization = @organization
        @user.save

        AccountBookType.create(user_id: @user.id, name: 'AC', description: '( Achat )')
        AccountBookType.create(user_id: @user.id, name: 'VT', description: '( Vente )')

        @user2 = FactoryGirl.create(:user, code: 'TS%0002', company: 'DEF')
        @user2.options = UserOptions.create(user_id: @user2.id)
        @user2.organization = @organization
        @user2.save

        AccountBookType.create(user_id: @user2.id, name: 'AC', description: '( Achat )')
        AccountBookType.create(user_id: @user2.id, name: 'BQ', description: '( Banque )')

        @group = Group.new
        @group.name = 'Customers'
        @group.organization = @organization
        @group.members << @collaborator
        @group.members << @user
        @group.members << @user2
        @group.save

        efs = @collaborator.find_or_create_external_file_storage
        efs.use ExternalFileStorage::F_DROPBOX
        @dropbox = efs.dropbox_basic
        @dropbox.access_token = '65XiB3QDfDUAAAAAAAAGzhf645c8M07MSCFxz4il6O72MfyHrPUT0W0jP0nmIfZN'
        @dropbox.save

        @collaborator.reload

        @headers = {
          'Accept'        => '*/*',
          'Authorization' => 'Bearer 65XiB3QDfDUAAAAAAAAGzhf645c8M07MSCFxz4il6O72MfyHrPUT0W0jP0nmIfZN',
          'User-Agent'    => 'OfficialDropboxRubySDK/1.6.5'
        }

        @headers_2 = @headers.merge({
          'Content-Type'  => 'application/x-www-form-urlencoded',
        })
      end

      after(:all) do
        DatabaseCleaner.clean
      end

      after(:each) do
        TempPack.delete_all
        TempDocument.delete_all
      end

      it 'creates initial folders' do
        VCR.use_cassette('dropbox_import/collaborator/creates_initial_folders') do
          DropboxImport.new(@dropbox).check
        end

        folder_paths = [
          '/exportation vers iDocus/TS%COL1/TS%0001 - ABC/période actuelle/AC',
          '/exportation vers iDocus/TS%COL1/TS%0001 - ABC/période actuelle/VT',
          '/exportation vers iDocus/TS%COL1/TS%0001 - ABC/période précédente/AC',
          '/exportation vers iDocus/TS%COL1/TS%0001 - ABC/période précédente/VT',
          '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période actuelle/AC',
          '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période actuelle/BQ',
          '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période précédente/AC',
          '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période précédente/BQ'
        ]

        # delta
        expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/delta').
          with(headers: @headers_2).
          with(body: "path_prefix=#{CGI::escape('/exportation vers iDocus/TS%COL1')}")

        # creates folder '/exportation vers iDocus/TS%COL1/TS%0001 - ABC/période actuelle/AC'
        expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder').
          with(headers: @headers_2).with(body: "root=sandbox&path=#{CGI::escape(folder_paths[0])}")
        # creates folder '/exportation vers iDocus/TS%COL1/TS%0001 - ABC/période actuelle/VT'
        expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder').
          with(headers: @headers_2).with(body: "root=sandbox&path=#{CGI::escape(folder_paths[1])}")
        # creates folder '/exportation vers iDocus/TS%COL1/TS%0001 - ABC/période précédente/AC'
        expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder').
          with(headers: @headers_2).with(body: "root=sandbox&path=#{CGI::escape(folder_paths[2])}")
        # creates folder '/exportation vers iDocus/TS%COL1/TS%0001 - ABC/période précédente/VT'
        expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder').
          with(headers: @headers_2).with(body: "root=sandbox&path=#{CGI::escape(folder_paths[3])}")

        # creates folder '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période actuelle/AC'
        expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder').
          with(headers: @headers_2).with(body: "root=sandbox&path=#{CGI::escape(folder_paths[4])}")
        # creates folder '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période actuelle/BQ'
        expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder').
          with(headers: @headers_2).with(body: "root=sandbox&path=#{CGI::escape(folder_paths[5])}")
        # creates folder '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période précédente/AC'
        expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder').
          with(headers: @headers_2).with(body: "root=sandbox&path=#{CGI::escape(folder_paths[6])}")
        # creates folder '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période précédente/BQ'
        expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder').
          with(headers: @headers_2).with(body: "root=sandbox&path=#{CGI::escape(folder_paths[7])}")

        expect(WebMock).to have_requested(:any, /.*/).times(9)

        expect(@dropbox.checked_at).to be_present
        expect(@dropbox.delta_cursor).to be_present
        expect(@dropbox.delta_path_prefix).to eq('/exportation vers iDocus/TS%COL1')
        expect(@dropbox.import_folder_paths).to eq(folder_paths)
      end

      context 'given initial folders have been created' do
        before(:each) do
          @dropbox.delta_path_prefix = '/exportation vers iDocus/TS%COL1'
          @dropbox.import_folder_paths = [
            '/exportation vers iDocus/TS%COL1/TS%0001 - ABC/période actuelle/AC',
            '/exportation vers iDocus/TS%COL1/TS%0001 - ABC/période actuelle/VT',
            '/exportation vers iDocus/TS%COL1/TS%0001 - ABC/période précédente/AC',
            '/exportation vers iDocus/TS%COL1/TS%0001 - ABC/période précédente/VT',
            '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période actuelle/AC',
            '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période actuelle/BQ',
            '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période précédente/AC',
            '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période précédente/BQ'
          ]
        end

        context 'given a valid file at : /exportation vers iDocus/TS%COL1/TS%0002 - DEF/période actuelle/AC/test.pdf' do
          it 'fetches one valid file' do
            delta_cursor = @dropbox.delta_cursor = 'AAEYqODXf58U-SteDlRC3j-xD4ncrMh1d8diaw-iLFo2jJyqJ8h0KhQWz7SuyRnTU1LkGe79FEDut4WiyYx1zKLrlWdGFq67kXngH_tLznncVLy2ptCuSN3ok9LZmF0VIVoT4YCVDUzX1OU2h1TQ8PEfT_NHWGpFEIwZoeO_fAif_A'
            @dropbox.save

            VCR.use_cassette('dropbox_import/collaborator/fetches_one_valid_file') do
              DropboxImport.new(@dropbox).check
            end

            # delta
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/delta').
              with(headers: @headers_2).
              with(body: "cursor=#{delta_cursor}&path_prefix=#{CGI::escape('/exportation vers iDocus/TS%COL1')}")
            # get file
            expect(WebMock).to have_requested(:get, 'https://api-content.dropbox.com/1/files/sandbox/exportation%20vers%20idocus/ts%25col1/ts%250002%20-%20def/p%C3%A9riode%20actuelle/ac/test.pdf').
              with(headers: @headers)
            # delete file
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/delete').
              with(headers: @headers_2).
              with(body: "root=sandbox&path=#{CGI::escape('/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période actuelle/AC/test.pdf'.downcase)}")

            expect(WebMock).to have_requested(:any, /.*/).times(3)

            temp_pack = TempPack.where(name: 'TS%0002 AC 201502 all').first
            temp_document = temp_pack.temp_documents.first
            signature = `md5sum #{temp_document.content.path}`.split.first
            expect(temp_pack.temp_documents.count).to eq 1
            expect(temp_document.original_file_name).to eq 'test.pdf'
            expect(signature).to eq '19738ae94972dbcb343df344a1cfa775'
          end
        end

        context 'given an invalid file at : /exportation vers iDocus/TS%COL1/TS%0001 - ABC/période actuelle/AC/corrupted.pdf' do
          it 'marks one invalid file' do
            delta_cursor = @dropbox.delta_cursor = 'AAFXJ4MsSG-zlrMbG8pYPyDLVTiLQL1bHrWT8Cak1RMi3CgFa1jaIwN7kAnKiVNJOqcgayS9pDyovPZwSxMJPtFHq1n8uKXYDZhgXQQbOFEkhnVC2cd2UCHawYImpb_DSC9JGkjia5qMOteZvMMpbHxFrVyxoO3W5ku_A8_PtcJbDQ'
            @dropbox.save

            VCR.use_cassette('dropbox_import/collaborator/marks_one_invalid_file') do
              DropboxImport.new(@dropbox).check
            end

            # delta
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/delta').
              with(headers: @headers_2).
              with(body: "cursor=#{delta_cursor}&path_prefix=#{CGI::escape('/exportation vers iDocus/TS%COL1')}")
            # get file
            expect(WebMock).to have_requested(:get, 'https://api-content.dropbox.com/1/files/sandbox/exportation%20vers%20idocus/ts%25col1/ts%250001%20-%20abc/p%C3%A9riode%20actuelle/ac/corrupted.pdf').
              with(headers: @headers)
            # rename file
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/move').
              with(headers: @headers_2).
              with(body: 'root=sandbox&from_path=%2Fexportation%C2%A0vers+idocus%2Fts%25col1%2Fts%250001+-+abc%2Fp%C3%A9riode+actuelle%2Fac%2Fcorrupted.pdf&to_path=%2Fexportation%C2%A0vers+idocus%2Fts%25col1%2Fts%250001+-+abc%2Fp%C3%A9riode+actuelle%2Fac%2Fcorrupted+%28erreur+fichier+non+valide+pour+iDocus%29.pdf')

            expect(WebMock).to have_requested(:any, /.*/).times(3)

            temp_pack = TempPack.where(name: 'TS%0001 AC 201502 all').first
            expect(temp_pack).to be_nil
          end
        end

        context 'given an invalid file already marked at : /exportation vers iDocus/TS%COL1/TS%0001 - ABC/période actuelle/AC/corrupted (erreur fichier non valide pour idocus).pdf' do
          it 'ignores one file marked invalid' do
            delta_cursor = @dropbox.delta_cursor = 'AAGZ2f4nTuNezjIJ7SbaToHSCdtrd6BFQmAZI1s0V3xzwyXXcPxepqYyAbiXaO8034W2oW_8uCSInbCiZwFgJ5OSsMOzgEuMs-3QxQm_fqyfiXQWa5l6HwSVkyFivDeGZWPAw-_gaJLNHquGJd35NW-AVn0FWVEy-dnEBsulrE4M7w'
            @dropbox.save

            VCR.use_cassette('dropbox_import/collaborator/ignores_one_file_marked_invalid') do
              DropboxImport.new(@dropbox).check
            end

            # delta
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/delta').
              with(headers: @headers_2).
              with(body: "cursor=#{delta_cursor}&path_prefix=#{CGI::escape('/exportation vers iDocus/TS%COL1')}")

            expect(WebMock).to have_requested(:any, /.*/).once

            temp_pack = TempPack.where(name: 'TS%0001 AC 201502 all').first
            expect(temp_pack).to be_nil
          end
        end

        context 'given folder "/exportation vers iDocus/TS%COL1/TS%0002 - DEF" is removed' do
          it 'recreates deleted folders' do
            delta_cursor = @dropbox.delta_cursor = 'AAHVB1HPH6ovrzxlkydqq4vZKNO8Gx4geZ-5BcRI3A82_vNB8gv_MJ7l4gnsEuI6QXn1jwcOnrEyYYQWoyFVBzVuDzgZAKw4e6yKu-6kqornG0QqIWSU-vTHC-pYBxSMLE05enxUaUoROHL1JSN3il0jnKSpdLdcOKBdrAy8VpJTwQ'
            @dropbox.save

            VCR.use_cassette('dropbox_import/collaborator/recreates_deleted_folders') do
              DropboxImport.new(@dropbox).check
            end

            # delta
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/delta').
              with(headers: @headers_2).
              with(body: "cursor=#{delta_cursor}&path_prefix=#{CGI::escape('/exportation vers iDocus/TS%COL1')}")
            # creates folder '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période actuelle/AC'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder').
              with(headers: @headers_2).with(body: "root=sandbox&path=#{CGI::escape('/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période actuelle/AC')}")
            # creates folder '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période actuelle/BQ'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder').
              with(headers: @headers_2).with(body: "root=sandbox&path=#{CGI::escape('/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période actuelle/BQ')}")
            # creates folder '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période précédente/AC'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder').
              with(headers: @headers_2).with(body: "root=sandbox&path=#{CGI::escape('/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période précédente/AC')}")
            # creates folder '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période précédente/BQ'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder').
              with(headers: @headers_2).with(body: "root=sandbox&path=#{CGI::escape('/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période précédente/BQ')}")

            expect(WebMock).to have_requested(:any, /.*/).times(5)
          end
        end

        context 'given folder at "/exportation vers iDocus/TS%COL1/TS%0001 - ABC" renamed or moved to "OLD"' do
          it 'recreates renamed or moved folders' do
            delta_cursor = @dropbox.delta_cursor = 'AAEWDmDqZQmdH7Kbicsm0hi6Pcs0pUUcZgYNleHKYfSngzFmXmZxkaorbQ0AeDtSga8I58QmBgSh92332V6PyK_OZ6qNG9QhkoX_F_ZU3qEr70WQgADGHe5n52Hg9yJB_cN_ivEXa_O_y6FcQsQCOu3fg_RZ_qWuvmWSwIqJyFIeoA'
            @dropbox.save

            VCR.use_cassette('dropbox_import/collaborator/recreates_renamed_or_moved_folders') do
              DropboxImport.new(@dropbox).check
            end

            # delta
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/delta').
              with(headers: @headers_2).
              with(body: "cursor=#{delta_cursor}&path_prefix=#{CGI::escape('/exportation vers iDocus/TS%COL1')}")
            # creates folder '/exportation vers iDocus/TS%COL1/TS%0001 - ABC/période actuelle/AC'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder').
              with(headers: @headers_2).with(body: "root=sandbox&path=#{CGI::escape('/exportation vers iDocus/TS%COL1/TS%0001 - ABC/période actuelle/AC')}")
            # creates folder '/exportation vers iDocus/TS%COL1/TS%0001 - ABC/période actuelle/BQ'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder').
              with(headers: @headers_2).with(body: "root=sandbox&path=#{CGI::escape('/exportation vers iDocus/TS%COL1/TS%0001 - ABC/période actuelle/VT')}")
            # creates folder '/exportation vers iDocus/TS%COL1/TS%0001 - ABC/période précédente/AC'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder').
              with(headers: @headers_2).with(body: "root=sandbox&path=#{CGI::escape('/exportation vers iDocus/TS%COL1/TS%0001 - ABC/période précédente/AC')}")
            # creates folder '/exportation vers iDocus/TS%COL1/TS%0001 - ABC/période précédente/BQ'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder').
              with(headers: @headers_2).with(body: "root=sandbox&path=#{CGI::escape('/exportation vers iDocus/TS%COL1/TS%0001 - ABC/période précédente/VT')}")

            expect(WebMock).to have_requested(:any, /.*/).times(5)
          end
        end

        context 'given journal VT is added to user TS%0002' do
          before(:all) do
            @journal = AccountBookType.create(user_id: @user2.id, name: 'VT', description: '( Vente )')
          end

          after(:all) do
            @journal.destroy
          end

          it 'creates 2 folders VT' do
            delta_cursor = @dropbox.delta_cursor = 'AAE-wwU07MFokYbCkVxWM9oZ1LL3aiMMkVpwoeXhRiqBUvdahVv9KslE8Pnwp6217hA9nX78raNAJL1Vc_GwX2E74yCEEQlI6_YtPj0Y_dCS20zLNGUQ0NxaJWHvo_8L1mm02nSao1UBSOaxQz1Gv7VrdFHAUJyvPpyH73I9kBsDow'
            @dropbox.save

            VCR.use_cassette('dropbox_import/collaborator/creates_2_folders_vt') do
              DropboxImport.new(@dropbox).check
            end

            # delta
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/delta').
              with(headers: @headers_2).
              with(body: "cursor=#{delta_cursor}&path_prefix=#{CGI::escape('/exportation vers iDocus/TS%COL1')}")
            # create folder '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période actuelle/VT'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder').
              with(headers: @headers_2).with(body: "root=sandbox&path=#{CGI::escape('/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période actuelle/VT')}")
            # create folder '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période précédente/VT'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder').
              with(headers: @headers_2).with(body: "root=sandbox&path=#{CGI::escape('/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période précédente/VT')}")

            expect(WebMock).to have_requested(:any, /.*/).times(3)
          end
        end

        context 'given journal BQ is renamed BQ1' do
          before(:all) do
            @user2.account_book_types.where(name: 'BQ').each do |journal|
              journal.update(name: 'BQ1')
            end
          end

          after(:all) do
            @user2.account_book_types.where(name: 'BQ1').each do |journal|
              journal.update(name: 'BQ')
            end
          end

          it 'deletes 2 folders BQ and creates 2 folders BQ1' do
            delta_cursor = @dropbox.delta_cursor = 'AAFqwYsvGNEvUtFnv75jI_uvcAbJh4FDMfbQOlspQGQ4M_-UuKSwdjnaJlOdEq3zQ162r_LFnHhnu87tWA6fN9pL6wv6fLG1TguWGDExqR3QQn1LctZEgrxlKSMu62c1q8NCI8SyhL9NMhgmhWd7u7M_XiWdkOqXaQDF2RmRre77Xw'
            @dropbox.save

            VCR.use_cassette('dropbox_import/collaborator/deletes_2_folders_BQ_and_creates_2_folders_bq1') do
              DropboxImport.new(@dropbox).check
            end

            # delta
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/delta').
              with(headers: @headers_2).
              with(body: "cursor=#{delta_cursor}&path_prefix=#{CGI::escape('/exportation vers iDocus/TS%COL1')}")
            # create folder 'BQ1' into folder 'période actuelle'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder').
              with(headers: @headers_2).with(body: "root=sandbox&path=#{CGI::escape('/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période actuelle/BQ1')}")
            # create folder 'BQ1' into folder 'période précédente'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder').
              with(headers: @headers_2).with(body: "root=sandbox&path=#{CGI::escape('/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période précédente/BQ1')}")
            # delete folder 'BQ' into folder 'période actuelle'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/delete').
              with(headers: @headers_2).with(body: "root=sandbox&path=#{CGI::escape('/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période actuelle/BQ')}")
            # delete folder 'BQ' into folder 'période précédente'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/delete').
              with(headers: @headers_2).with(body: "root=sandbox&path=#{CGI::escape('/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période précédente/BQ')}")

            expect(WebMock).to have_requested(:any, /.*/).times(5)
          end
        end

        context 'given journal VT is removed' do
          before(:all) do
            @user2.account_book_types.where(name: 'BQ').each do |journal|
              journal.update(name: 'BQ1')
            end
          end

          after(:all) do
            @user2.account_book_types.where(name: 'BQ1').each do |journal|
              journal.update(name: 'BQ')
            end
          end

          it 'deletes 2 folders VT' do
            delta_cursor = @dropbox.delta_cursor = 'AAE4gRCiNu0uIxU4U-sbrwgw34Mfj59372ycZelcbiKCIj6cLgTrg-rwxR75SB5_LGWhD9CjmEVHoiA7sK0BrLfdl-xRHRkcqcIvRBeYklFyc0sbhU5-5K7FaBYcpNp1TJZ-GUlDrlhQIN3rIaeHKQ7waJPrTAiUdugkrO131kQ1Mw'
            @dropbox.import_folder_paths = [
              '/exportation vers iDocus/TS%COL1/TS%0001 - ABC/période actuelle/AC',
              '/exportation vers iDocus/TS%COL1/TS%0001 - ABC/période actuelle/VT',
              '/exportation vers iDocus/TS%COL1/TS%0001 - ABC/période précédente/AC',
              '/exportation vers iDocus/TS%COL1/TS%0001 - ABC/période précédente/VT',
              '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période actuelle/AC',
              '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période actuelle/BQ1',
              '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période actuelle/VT',
              '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période précédente/AC',
              '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période précédente/BQ1',
              '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période précédente/VT'
            ]
            @dropbox.save

            VCR.use_cassette('dropbox_import/collaborator/deletes_2_folders_VT') do
              DropboxImport.new(@dropbox).check
            end

            # delta
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/delta').
              with(headers: @headers_2).
              with(body: "cursor=#{delta_cursor}&path_prefix=#{CGI::escape('/exportation vers iDocus/TS%COL1')}")
            # delete folder 'VT' into folder 'période actuelle'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/delete').
              with(headers: @headers_2).with(body: "root=sandbox&path=#{CGI::escape('/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période actuelle/VT')}")
            # delete folder 'VT' into folder 'période précédente'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/delete').
              with(headers: @headers_2).with(body: "root=sandbox&path=#{CGI::escape('/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période précédente/VT')}")

            expect(WebMock).to have_requested(:any, /.*/).times(3)
          end
        end

        context 'given TS%0001 is removed from group' do
          before(:all) do
            @user.groups.clear
          end

          after(:all) do
            @group.members << @user
            @group.save

            @user.groups << @group
            @user.save
          end

          it 'removes folder TS%0001 - ABC' do
            delta_cursor = @dropbox.delta_cursor = 'AAFP3ZgpBI8HvTyPKBey0nr2BXfqRhmbRjbixs86HeLy1U51sJN5EktuA8Vga2kjbdkPRXdGfQZrn0d686DpTkJrJRThFWznD6U7zN22n3NOhxQPkPbJT2_KKHyEWrT2i8TovqMoE7NK1HtNdcIXNU778tudxPIvzH9gjst89Rt0CA'
            @dropbox.save

            VCR.use_cassette('dropbox_import/collaborator/removes_folder_ts%0001_-_abc') do
              DropboxImport.new(@dropbox).check
            end

            # delta
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/delta').
              with(headers: @headers_2).
              with(body: "cursor=#{delta_cursor}&path_prefix=#{CGI::escape('/exportation vers iDocus/TS%COL1')}")
            # deletes folder TS%0001 - ABC
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/delete').
              with(headers: @headers_2).with(body: "root=sandbox&path=#{CGI::escape('/exportation vers iDocus/TS%COL1/TS%0001 - ABC')}")

            expect(WebMock).to have_requested(:any, /.*/).times(2)
          end
        end

        context 'given TS%0003 is added' do
          before(:all) do
            @user3 = FactoryGirl.create(:user, code: 'TS%0003', company: 'GHI')
            @user3.options = UserOptions.create(user_id: @user3.id)
            @user3.organization = @organization
            @user3.save

            AccountBookType.create(user_id: @user3.id, name: 'AC', description: '( Achat )')
            AccountBookType.create(user_id: @user3.id, name: 'BQ', description: '( Banque )')

            @group.members << @user3
            @group.save

            @user3.groups << @group
            @user3.save
          end

          after(:all) do
            @user3.groups.clear
          end

          it 'creates TS%0003\'s folders' do
            delta_cursor = @dropbox.delta_cursor = 'AAFpUGtY65bkw3p8BUksAJ20DidN5mc1k2S0cdOvEEwOwtHl93svFe--pAn7kARELvTslPSmhhzC9Ao_85nJlr0i5uwHEFqnJjgF36Q9Yno-DKRsxJASM7YhVcDu2N7XzfcsxLit0Y7KZvBe6rf4d72gOAy0By08ceekAPVu9Q40Fg'
            @dropbox.save

            VCR.use_cassette('dropbox_import/collaborator/creates_ts%0003s_folders') do
              DropboxImport.new(@dropbox).check
            end

            # delta
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/delta').
              with(headers: @headers_2).
              with(body: "cursor=#{delta_cursor}&path_prefix=#{CGI::escape('/exportation vers iDocus/TS%COL1')}")
            # creates folder '/exportation vers iDocus/TS%COL1/TS%0003 - GHI/période actuelle/AC'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder').
              with(headers: @headers_2).with(body: "root=sandbox&path=#{CGI::escape('/exportation vers iDocus/TS%COL1/TS%0003 - GHI/période actuelle/AC')}")
            # creates folder '/exportation vers iDocus/TS%COL1/TS%0003 - GHI/période actuelle/BQ'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder').
              with(headers: @headers_2).with(body: "root=sandbox&path=#{CGI::escape('/exportation vers iDocus/TS%COL1/TS%0003 - GHI/période actuelle/BQ')}")
            # creates folder '/exportation vers iDocus/TS%COL1/TS%0003 - GHI/période précédente/AC'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder').
              with(headers: @headers_2).with(body: "root=sandbox&path=#{CGI::escape('/exportation vers iDocus/TS%COL1/TS%0003 - GHI/période précédente/AC')}")
            # creates folder '/exportation vers iDocus/TS%COL1/TS%0003 - GHI/période précédente/BQ'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder').
              with(headers: @headers_2).with(body: "root=sandbox&path=#{CGI::escape('/exportation vers iDocus/TS%COL1/TS%0003 - GHI/période précédente/BQ')}")

            expect(WebMock).to have_requested(:any, /.*/).times(5)
          end
        end

        context 'given TS%0002 company is modified' do
          before(:all) do
            @user2.company = 'DDD'
            @user2.save
          end

          after(:all) do
            @user2.company = 'DEF'
            @user2.save
          end

          it 'removes folder "TS%0002 - DEF" and creates folder "TS%0002 - DDD" and subfolders' do
            delta_cursor = @dropbox.delta_cursor = 'AAFaPkSZoRPGcHi2bW_Zmi5q0wE-Rzibv_q-tsq0EcUvYF1q4_QXfBUP20urPfDvBJAi6wZ3vlpbGEqa8G8VM9X813MRzaPtpp0Hvu8JXSlKVxP1cDpQr1_xHFhUvce-6I395zjXQAjtavBXG9y8gyHk2RQZmXq8MK3F3oxgt-qtqw'
            @dropbox.save

            VCR.use_cassette('dropbox_import/collaborator/renames_folder_ts%0002_-_def') do
              DropboxImport.new(@dropbox).check
            end

            # delta
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/delta').
              with(headers: @headers_2).
              with(body: "cursor=#{delta_cursor}&path_prefix=#{CGI::escape('/exportation vers iDocus/TS%COL1')}")
            # deletes folder '/exportation vers iDocus/TS%0002 - DEF'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/delete').
              with(headers: @headers_2).with(body: "root=sandbox&path=#{CGI::escape('/exportation vers iDocus/TS%COL1/TS%0002 - DEF')}")
            # creates folder '/exportation vers iDocus/TS%COL1/TS%0002 - DDD/période actuelle/AC'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder').
              with(headers: @headers_2).with(body: "root=sandbox&path=#{CGI::escape('/exportation vers iDocus/TS%COL1/TS%0002 - DDD/période actuelle/AC')}")
            # creates folder '/exportation vers iDocus/TS%COL1/TS%0002 - DDD/période actuelle/BQ'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder').
              with(headers: @headers_2).with(body: "root=sandbox&path=#{CGI::escape('/exportation vers iDocus/TS%COL1/TS%0002 - DDD/période actuelle/BQ')}")
            # creates folder '/exportation vers iDocus/TS%COL1/TS%0002 - DDD/période précédente/AC'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder').
              with(headers: @headers_2).with(body: "root=sandbox&path=#{CGI::escape('/exportation vers iDocus/TS%COL1/TS%0002 - DDD/période précédente/AC')}")
            # creates folder '/exportation vers iDocus/TS%COL1/TS%0002 - DDD/période précédente/BQ'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder').
              with(headers: @headers_2).with(body: "root=sandbox&path=#{CGI::escape('/exportation vers iDocus/TS%COL1/TS%0002 - DDD/période précédente/BQ')}")

            expect(WebMock).to have_requested(:any, /.*/).times(6)
          end
        end
      end
    end
  end
end
