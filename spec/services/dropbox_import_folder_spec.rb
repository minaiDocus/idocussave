# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe DropboxImportFolder do
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
        @dropbox.session = "---\n- 2dqp6mmtv6r0u6i\n- 59dfvae34ievygaw\n- Ef7bavtM3EGgW84G\n- A0evPNPJ9OAQrhlQ\n- x201tvs8q2eicni\n- bcdhzr36fnu5fpn\n"
        @dropbox.save

        @user.reload

        @headers = {
          'Accept'        => '*/*',
          'Authorization' => 'OAuth oauth_version="1.0", oauth_signature_method="PLAINTEXT", oauth_consumer_key="bcdhzr36fnu5fpn", oauth_token="59dfvae34ievygaw", oauth_signature="x201tvs8q2eicni&2dqp6mmtv6r0u6i"',
          'User-Agent'    => 'OfficialDropboxRubySDK/1.1'
        }
      end

      after(:all) do
        DatabaseCleaner.clean
      end

      after(:each) do
        TempPack.delete_all
        TempDocument.delete_all
      end

      it 'creates initial folders' do
        VCR.use_cassette('dropbox_import_folder/customer/creates_initial_folders') do
          DropboxImportFolder.new(@dropbox).check
        end

        # delta
        expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/delta?path_prefix=/exportation%20vers%20iDocus/TS%250001%20-%20TeSt').with(headers: @headers)

        # creates folder '/exportation vers iDocus/TS%0001 - TeSt/période actuelle/AC'
        expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder?path=/exportation%20vers%20iDocus/TS%250001%20-%20TeSt/p%C3%A9riode%20actuelle/AC&root=sandbox').with(headers: @headers)
        # creates folder '/exportation vers iDocus/TS%0001 - TeSt/période actuelle/VT'
        expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder?path=/exportation%20vers%20iDocus/TS%250001%20-%20TeSt/p%C3%A9riode%20actuelle/VT&root=sandbox').with(headers: @headers)
        # creates folder '/exportation vers iDocus/TS%0001 - TeSt/période précédente/AC'
        expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder?path=/exportation%20vers%20iDocus/TS%250001%20-%20TeSt/p%C3%A9riode%20pr%C3%A9c%C3%A9dente/AC&root=sandbox').with(headers: @headers)
        # creates folder '/exportation vers iDocus/TS%0001 - TeSt/période précédente/VT'
        expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder?path=/exportation%20vers%20iDocus/TS%250001%20-%20TeSt/p%C3%A9riode%20pr%C3%A9c%C3%A9dente/VT&root=sandbox').with(headers: @headers)

        expect(WebMock).to have_requested(:any, /.*/).times(5)

        expect(@dropbox.checked_at).to be_present
        expect(@dropbox.delta_cursor).to be_present
        expect(@dropbox.delta_path_prefix).to eq('/exportation vers iDocus/TS%0001 - TeSt')
        expect(@dropbox.import_folder_paths).to eq([
          '/exportation vers iDocus/TS%0001 - TeSt/période actuelle/AC',
          '/exportation vers iDocus/TS%0001 - TeSt/période actuelle/VT',
          '/exportation vers iDocus/TS%0001 - TeSt/période précédente/AC',
          '/exportation vers iDocus/TS%0001 - TeSt/période précédente/VT'
        ])
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
            delta_cursor = @dropbox.delta_cursor = 'AAHv8awX-MkrLKupZtbUIEIpDRa8ARiDFDSLVnpLxKBnZPmrXxeuxF1kYtkXqOk5SbcO3hoEoTcPNDZFszHtCg4xdMFz167WZrmL7TV3B9vtq1Rpmx8ZBWfgtnsJj0B6_zUml-6D65RWAUJMM7_a7_cozm0SbRDhE2rX6y0pCZ5l59A5vH9HDvqsiFIgSYf5oDo'
            @dropbox.save

            VCR.use_cassette('dropbox_import_folder/customer/fetches_one_valid_file') do
              DropboxImportFolder.new(@dropbox).check
            end

            # delta
            expect(WebMock).to have_requested(:post, "https://api.dropbox.com/1/delta?cursor=#{delta_cursor}&path_prefix=/exportation%20vers%20iDocus/TS%250001%20-%20TeSt").with(headers: @headers)
            # get file
            expect(WebMock).to have_requested(:get, 'https://api-content.dropbox.com/1/files/sandbox/exportation%20vers%20idocus/ts%250001%20-%20test/p%C3%A9riode%20actuelle/ac/test.pdf').with(headers: @headers)
            # delete file
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/delete?path=/exportation%20vers%20idocus/ts%250001%20-%20test/p%C3%A9riode%20actuelle/ac/test.pdf&root=sandbox').with(headers: @headers)

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
            delta_cursor = @dropbox.delta_cursor = 'AAFT8pB18BeBFBmgMJnIij1oalkQaI86DItmZF2gOtvj2KT-qdxLwRqNVek4KIyafXUQiIjMdH0toxfY-WtjDHDD4esnbBudO0rxau4WnOpzUeW1OVol7EmY_rXOL_r5gkuqgcbbA5Pr5ovDAWwRs2cKG05PhM6XJWBxrlCgUJ1UlVXrmmn7wTikUQMVVvpkIUE'
            @dropbox.save

            VCR.use_cassette('dropbox_import_folder/customer/marks_one_invalid_file') do
              DropboxImportFolder.new(@dropbox).check
            end

            # delta
            expect(WebMock).to have_requested(:post, "https://api.dropbox.com/1/delta?cursor=#{delta_cursor}&path_prefix=/exportation%20vers%20iDocus/TS%250001%20-%20TeSt").with(headers: @headers)
            # get file
            expect(WebMock).to have_requested(:get, 'https://api-content.dropbox.com/1/files/sandbox/exportation%20vers%20idocus/ts%250001%20-%20test/p%C3%A9riode%20actuelle/ac/corrupted.pdf').with(headers: @headers)
            # rename file
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/move?from_path=/exportation%20vers%20idocus/ts%250001%20-%20test/p%C3%A9riode%20actuelle/ac/corrupted.pdf&root=sandbox&to_path=/exportation%20vers%20idocus/ts%250001%20-%20test/p%C3%A9riode%20actuelle/ac/corrupted%20(erreur%20fichier%20non%20valide%20pour%20iDocus).pdf').with(headers: @headers)

            expect(WebMock).to have_requested(:any, /.*/).times(3)

            temp_pack = TempPack.where(name: 'TS%0001 AC 201502 all').first
            expect(temp_pack).to be_nil
          end
        end

        context 'given an invalid file already marked at : /exportation vers iDocus/TS%0001 - TeSt/période actuelle/AC/corrupted (erreur fichier non valide pour idocus).pdf' do
          it 'ignores one file marked invalid' do
            delta_cursor = @dropbox.delta_cursor = 'AAGhHsG9BlDjdqkKJcMLfvLsqzdvLjJTPApmP8wmri38SbyLxPRYJNURdxWWO7z8moNn0FNzU-14QEwcEC-Iam7N7fVPIY8I82u9Ulw39E1UFBLfO4yth56qliWTZr5ZPOVEibKa_retswglhwnFZ4l2s0Ggv1CTy9IkMkkZtlmOCcuSH9xaGgeWaop5f0qwAWY'
            @dropbox.save

            VCR.use_cassette('dropbox_import_folder/customer/ignores_one_file_marked_invalid') do
              DropboxImportFolder.new(@dropbox).check
            end

            # delta
            expect(WebMock).to have_requested(:post, "https://api.dropbox.com/1/delta?cursor=#{delta_cursor}&path_prefix=/exportation%20vers%20iDocus/TS%250001%20-%20TeSt").with(headers: @headers)

            expect(WebMock).to have_requested(:any, /.*/).once

            temp_pack = TempPack.where(name: 'TS%0001 AC 201502 all').first
            expect(temp_pack).to be_nil
          end
        end

        context 'given folder "/exportation vers iDocus/TS%0001 - TeSt/période précédente" is removed' do
          it 'recreates deleted folders' do
            delta_cursor = @dropbox.delta_cursor = 'AAGtycDeEP4Vgiw0FAoz9kVk5mc_Gpthr3V8c0W8yn769-Yq-pIHr3OMxcuMJOLn9UXWpHx5DnlIkpSWT73VZnu2ouzqHp1Kd2AO2tdUL9D0MtFghxXBuNxICl4kmOpfILsj3jy_rvqQD25edU1AV_xwvMnTxtoQC09-Gubdt9ogdtm8MGMDkBHKv0Nl0HdSKzM'
            @dropbox.save

            VCR.use_cassette('dropbox_import_folder/customer/recreates_deleted_folders') do
              DropboxImportFolder.new(@dropbox).check
            end

            # delta
            expect(WebMock).to have_requested(:post, "https://api.dropbox.com/1/delta?cursor=#{delta_cursor}&path_prefix=/exportation%20vers%20iDocus/TS%250001%20-%20TeSt").with(headers: @headers)
            # create folder AC
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder?path=/exportation%20vers%20iDocus/TS%250001%20-%20TeSt/p%C3%A9riode%20pr%C3%A9c%C3%A9dente/AC&root=sandbox').with(headers: @headers)
            # create folder VT
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder?path=/exportation%20vers%20iDocus/TS%250001%20-%20TeSt/p%C3%A9riode%20pr%C3%A9c%C3%A9dente/VT&root=sandbox').with(headers: @headers)

            expect(WebMock).to have_requested(:any, /.*/).times(3)
          end
        end

        context 'given folder at "/exportation vers iDocus/TS%0001 - TeSt/période actuelle" renamed or moved to "PERIODE"' do
          it 'recreates renamed or moved folders' do
            delta_cursor = @dropbox.delta_cursor = 'AAF8WWOASwvuQN7x3kOpyhAM6l1qvvty_Y1nF7D7wmsnzldRc-spypxbDT1bKKUcaIEjNZwuvvKdG0dO3RGfPW-jGZkJpmlfI0lFYJ8a3JSKD8Dp6pxqV1rcZDVU-etsXPFC2yKGmrh_ogfXGa1IjfyEDpC4U203xBK9bIYkyPvUgaU4CBH5dzqugzYh7OX4uNo'
            @dropbox.save

            VCR.use_cassette('dropbox_import_folder/customer/recreates_renamed_or_moved_folders') do
              DropboxImportFolder.new(@dropbox).check
            end

            # delta
            expect(WebMock).to have_requested(:post, "https://api.dropbox.com/1/delta?cursor=#{delta_cursor}&path_prefix=/exportation%20vers%20iDocus/TS%250001%20-%20TeSt").with(headers: @headers)
            # create folder AC
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder?path=/exportation%20vers%20iDocus/TS%250001%20-%20TeSt/p%C3%A9riode%20actuelle/AC&root=sandbox').with(headers: @headers)
            # create folder VT
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder?path=/exportation%20vers%20iDocus/TS%250001%20-%20TeSt/p%C3%A9riode%20actuelle/VT&root=sandbox').with(headers: @headers)

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
            delta_cursor = @dropbox.delta_cursor = 'AAHQ44-hxlVDBbNvEkri4zt3TXhWQ0j26EMDJbPl5qZ3rLh0ED3mczMfxyxDtIj_fBeznwGENXuLRMrIBLa1yXQVPt2wXbpdaDoK6aoJZCkVRJnRsLmlzWUGWLJyt7fUo2gWHOTa0ROb3xKLtSrzR975dRqocXEMHZIBff_jfqyg1Zv7LiPw6qIgYBTOtA92aWs'
            @dropbox.save

            VCR.use_cassette('dropbox_import_folder/customer/creates_2_folders_bq') do
              DropboxImportFolder.new(@dropbox).check
            end

            # delta
            expect(WebMock).to have_requested(:post, "https://api.dropbox.com/1/delta?cursor=#{delta_cursor}&path_prefix=/exportation%20vers%20iDocus/TS%250001%20-%20TeSt").with(headers: @headers)
            # create folder 'BQ' into folder 'période actuelle'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder?path=/exportation%20vers%20iDocus/TS%250001%20-%20TeSt/p%C3%A9riode%20actuelle/BQ&root=sandbox').with(headers: @headers)
            # create folder 'BQ' into folder 'période précédente'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder?path=/exportation%20vers%20iDocus/TS%250001%20-%20TeSt/p%C3%A9riode%20pr%C3%A9c%C3%A9dente/BQ&root=sandbox').with(headers: @headers)

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
            delta_cursor = @dropbox.delta_cursor = 'AAGzIe8i0TwKe6y5SwY_Mu2QXEbeofy7TQHJuf7hCU7uOZCLSraFla7IzhElEL7aoMhfgXSLTLF5LVstA0dnGVkSr8Eg1a6IN6bQGWZWs8m1JNknqARPpUd_VgeiFaSEDP_wuBeVrcPJCa0AgodzOAlpmbSuPcsq8-xZcc7I1qKRYzyEh3qCHchcv5GuMieaZIg'
            @dropbox.import_folder_paths = [
              '/exportation vers iDocus/TS%0001 - TeSt/période actuelle/AC',
              '/exportation vers iDocus/TS%0001 - TeSt/période actuelle/VT',
              '/exportation vers iDocus/TS%0001 - TeSt/période actuelle/BQ',
              '/exportation vers iDocus/TS%0001 - TeSt/période précédente/AC',
              '/exportation vers iDocus/TS%0001 - TeSt/période précédente/VT',
              '/exportation vers iDocus/TS%0001 - TeSt/période précédente/BQ'
            ]
            @dropbox.save

            VCR.use_cassette('dropbox_import_folder/customer/deletes_2_folders_BQ_and_creates_2_folders_bq1') do
              DropboxImportFolder.new(@dropbox).check
            end

            # delta
            expect(WebMock).to have_requested(:post, "https://api.dropbox.com/1/delta?cursor=#{delta_cursor}&path_prefix=/exportation%20vers%20iDocus/TS%250001%20-%20TeSt").with(headers: @headers)
            # create folder 'BQ1' into folder 'période actuelle'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder?path=/exportation%20vers%20iDocus/TS%250001%20-%20TeSt/p%C3%A9riode%20actuelle/BQ1&root=sandbox').with(headers: @headers)
            # create folder 'BQ1' into folder 'période précédente'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder?path=/exportation%20vers%20iDocus/TS%250001%20-%20TeSt/p%C3%A9riode%20pr%C3%A9c%C3%A9dente/BQ1&root=sandbox').with(headers: @headers)
            # delete folder 'BQ' into folder 'période actuelle'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/delete?path=/exportation%20vers%20iDocus/TS%250001%20-%20TeSt/p%C3%A9riode%20actuelle/BQ&root=sandbox').with(headers: @headers)
            # delete folder 'BQ' into folder 'période précédente'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/delete?path=/exportation%20vers%20iDocus/TS%250001%20-%20TeSt/p%C3%A9riode%20pr%C3%A9c%C3%A9dente/BQ&root=sandbox').with(headers: @headers)

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
            delta_cursor = @dropbox.delta_cursor = 'AAFq_rI5by6mNwnS6XJJQywuAH3BmSFaUrFaQWdSsprkNxjcKp4878rh_gQm9r0EGL3p2E5_g_Izhm7A34wO8EGoLrA4CqbJrbqYACKtQy7dwz9onli8yGsCod91i9zAhGp5xVwOPSmPApkFRCBsAVypoYKb2dUYcFBaEfjA9qHB1OSGJTWOD1xaz_sb9tuD3nM'
            @dropbox.save

            VCR.use_cassette('dropbox_import_folder/customer/deletes_2_folders_VT') do
              DropboxImportFolder.new(@dropbox).check
            end

            # delta
            expect(WebMock).to have_requested(:post, "https://api.dropbox.com/1/delta?cursor=#{delta_cursor}&path_prefix=/exportation%20vers%20iDocus/TS%250001%20-%20TeSt").with(headers: @headers)
            # delete folder 'VT' into folder 'période actuelle'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/delete?path=/exportation%20vers%20iDocus/TS%250001%20-%20TeSt/p%C3%A9riode%20actuelle/VT&root=sandbox').with(headers: @headers)
            # delete folder 'VT' into folder 'période précédente'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/delete?path=/exportation%20vers%20iDocus/TS%250001%20-%20TeSt/p%C3%A9riode%20pr%C3%A9c%C3%A9dente/VT&root=sandbox').with(headers: @headers)

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
                    delta_cursor = @dropbox.delta_cursor = 'AAForDKHWmGFe5QFgnkpRdvQTVZtI2aSUBnLIGL578Iq5x-8RsBajq4sfPCr34F5y-U4A5vy63SUjZ0i_A_0XSboN2qOStcrgx82yI-fSqdhWWn5GWRDwoXHLHdxZHFRd-M'
                    @dropbox.save

                    VCR.use_cassette('dropbox_import_folder/customer/executes_multiple_jobs') do
                      DropboxImportFolder.new(@dropbox).check
                    end

                    # delta
                    expect(WebMock).to have_requested(:post, "https://api.dropbox.com/1/delta?cursor=#{delta_cursor}&path_prefix=/exportation%20vers%20iDocus/TS%250001%20-%20TeSt").with(headers: @headers)
                    # get corrupted file
                    expect(WebMock).to have_requested(:get, 'https://api-content.dropbox.com/1/files/sandbox/exportation%20vers%20idocus/ts%250001%20-%20test/p%C3%A9riode%20actuelle/vt/corrupted.pdf').with(headers: @headers)
                    # mark corrupted file as invalid
                    expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/move?from_path=/exportation%20vers%20idocus/ts%250001%20-%20test/p%C3%A9riode%20actuelle/vt/corrupted.pdf&root=sandbox&to_path=/exportation%20vers%20idocus/ts%250001%20-%20test/p%C3%A9riode%20actuelle/vt/corrupted%20(erreur%20fichier%20non%20valide%20pour%20iDocus).pdf').with(headers: @headers)
                    # get file
                    expect(WebMock).to have_requested(:get, 'https://api-content.dropbox.com/1/files/sandbox/exportation%20vers%20idocus/ts%250001%20-%20test/p%C3%A9riode%20actuelle/vt/test.pdf').with(headers: @headers)
                    # delete file
                    expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/delete?path=/exportation%20vers%20idocus/ts%250001%20-%20test/p%C3%A9riode%20actuelle/vt/test.pdf&root=sandbox').with(headers: @headers)
                    # remove journal AC from folder période actuelle
                    expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/delete?path=/exportation%20vers%20iDocus/TS%250001%20-%20TeSt/p%C3%A9riode%20actuelle/AC&root=sandbox').with(headers: @headers)
                    # create journal OD into folder période actuelle
                    expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder?path=/exportation%20vers%20iDocus/TS%250001%20-%20TeSt/p%C3%A9riode%20actuelle/OD&root=sandbox').with(headers: @headers)
                    # create journal OD into folder période précédente
                    expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder?path=/exportation%20vers%20iDocus/TS%250001%20-%20TeSt/p%C3%A9riode%20pr%C3%A9c%C3%A9dente/OD&root=sandbox').with(headers: @headers)
                    # create folder VT into période précédente
                    expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder?path=/exportation%20vers%20iDocus/TS%250001%20-%20TeSt/p%C3%A9riode%20pr%C3%A9c%C3%A9dente/VT&root=sandbox').with(headers: @headers)

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

        @collaborator.groups << @group
        @collaborator.save
        @user.groups << @group
        @user.save
        @user2.groups << @group
        @user2.save

        efs = @collaborator.find_or_create_external_file_storage
        efs.use ExternalFileStorage::F_DROPBOX
        @dropbox = efs.dropbox_basic
        @dropbox.session = "---\n- 2dqp6mmtv6r0u6i\n- 59dfvae34ievygaw\n- Ef7bavtM3EGgW84G\n- A0evPNPJ9OAQrhlQ\n- x201tvs8q2eicni\n- bcdhzr36fnu5fpn\n"
        @dropbox.save

        @collaborator.reload

        @headers = {
          'Accept'        => '*/*',
          'Authorization' => 'OAuth oauth_version="1.0", oauth_signature_method="PLAINTEXT", oauth_consumer_key="bcdhzr36fnu5fpn", oauth_token="59dfvae34ievygaw", oauth_signature="x201tvs8q2eicni&2dqp6mmtv6r0u6i"',
          'User-Agent'    => 'OfficialDropboxRubySDK/1.1'
        }
      end

      after(:all) do
        DatabaseCleaner.clean
      end

      after(:each) do
        TempPack.delete_all
        TempDocument.delete_all
      end

      it 'creates initial folders' do
        VCR.use_cassette('dropbox_import_folder/collaborator/creates_initial_folders') do
          DropboxImportFolder.new(@dropbox).check
        end

        # delta
        expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/delta?path_prefix=/exportation%20vers%20iDocus/TS%25COL1').with(headers: @headers)

        # creates folder '/exportation vers iDocus/TS%COL1/TS%0001 - ABC/période actuelle/AC'
        expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder?path=/exportation%20vers%20iDocus/TS%25COL1/TS%250001%20-%20ABC/p%C3%A9riode%20actuelle/AC&root=sandbox').with(headers: @headers)
        # creates folder '/exportation vers iDocus/TS%COL1/TS%0001 - ABC/période actuelle/VT'
        expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder?path=/exportation%20vers%20iDocus/TS%25COL1/TS%250001%20-%20ABC/p%C3%A9riode%20actuelle/VT&root=sandbox').with(headers: @headers)
        # creates folder '/exportation vers iDocus/TS%COL1/TS%0001 - ABC/période précédente/AC'
        expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder?path=/exportation%20vers%20iDocus/TS%25COL1/TS%250001%20-%20ABC/p%C3%A9riode%20pr%C3%A9c%C3%A9dente/AC&root=sandbox').with(headers: @headers)
        # creates folder '/exportation vers iDocus/TS%COL1/TS%0001 - ABC/période précédente/VT'
        expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder?path=/exportation%20vers%20iDocus/TS%25COL1/TS%250001%20-%20ABC/p%C3%A9riode%20pr%C3%A9c%C3%A9dente/VT&root=sandbox').with(headers: @headers)

        # creates folder '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période actuelle/AC'
        expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder?path=/exportation%20vers%20iDocus/TS%25COL1/TS%250002%20-%20DEF/p%C3%A9riode%20actuelle/AC&root=sandbox').with(headers: @headers)
        # creates folder '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période actuelle/BQ'
        expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder?path=/exportation%20vers%20iDocus/TS%25COL1/TS%250002%20-%20DEF/p%C3%A9riode%20actuelle/BQ&root=sandbox').with(headers: @headers)
        # creates folder '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période précédente/AC'
        expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder?path=/exportation%20vers%20iDocus/TS%25COL1/TS%250002%20-%20DEF/p%C3%A9riode%20pr%C3%A9c%C3%A9dente/AC&root=sandbox').with(headers: @headers)
        # creates folder '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période précédente/BQ'
        expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder?path=/exportation%20vers%20iDocus/TS%25COL1/TS%250002%20-%20DEF/p%C3%A9riode%20pr%C3%A9c%C3%A9dente/BQ&root=sandbox').with(headers: @headers)

        expect(WebMock).to have_requested(:any, /.*/).times(9)

        expect(@dropbox.checked_at).to be_present
        expect(@dropbox.delta_cursor).to be_present
        expect(@dropbox.delta_path_prefix).to eq('/exportation vers iDocus/TS%COL1')
        expect(@dropbox.import_folder_paths).to eq([
          '/exportation vers iDocus/TS%COL1/TS%0001 - ABC/période actuelle/AC',
          '/exportation vers iDocus/TS%COL1/TS%0001 - ABC/période actuelle/VT',
          '/exportation vers iDocus/TS%COL1/TS%0001 - ABC/période précédente/AC',
          '/exportation vers iDocus/TS%COL1/TS%0001 - ABC/période précédente/VT',
          '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période actuelle/AC',
          '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période actuelle/BQ',
          '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période précédente/AC',
          '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période précédente/BQ'
        ])
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
            delta_cursor = @dropbox.delta_cursor = 'AAEEqgyGzAYewkCYFws6QGewrmYXLNsaO9qZAXDA99ltWaooHoSzNBWn3dFu8Ub19BIsMO6yz2XIzTSm-NAih8C-tcXZG-JJfdDaHUFZ8EJtXcLEYzgY1n6mlM540-LxYZ1W0LBa9jS4WMRlVuKvZQqrs8crqlutLtw7KANesGCyDQ'
            @dropbox.save

            VCR.use_cassette('dropbox_import_folder/collaborator/fetches_one_valid_file') do
              DropboxImportFolder.new(@dropbox).check
            end

            # delta
            expect(WebMock).to have_requested(:post, "https://api.dropbox.com/1/delta?cursor=#{delta_cursor}&path_prefix=/exportation%20vers%20iDocus/TS%25COL1").with(headers: @headers)
            # get file
            expect(WebMock).to have_requested(:get, 'https://api-content.dropbox.com/1/files/sandbox/exportation%20vers%20idocus/ts%25col1/ts%250002%20-%20def/p%C3%A9riode%20actuelle/ac/test.pdf').with(headers: @headers)
            # delete file
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/delete?path=/exportation%20vers%20idocus/ts%25col1/ts%250002%20-%20def/p%C3%A9riode%20actuelle/ac/test.pdf&root=sandbox').with(headers: @headers)

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
            delta_cursor = @dropbox.delta_cursor = 'AAEK3C9X0YOrLgbLiMg8U00t4KgHMRoONDHQyo9IjYy9f4zWGSVBiN9xKnaASiqvAEE5A-ka1Aj5MHP-kChc5nPIqOuvu22dQNfqmC08UItT_mN2JZOCOvJ_8N9jAHquagXjvIKxzevZsT8UPlZkAXFwtkS-TWyr4-dfdtlXH7NLXA'
            @dropbox.save

            VCR.use_cassette('dropbox_import_folder/collaborator/marks_one_invalid_file') do
              DropboxImportFolder.new(@dropbox).check
            end

            # delta
            expect(WebMock).to have_requested(:post, "https://api.dropbox.com/1/delta?cursor=#{delta_cursor}&path_prefix=/exportation%20vers%20iDocus/TS%25COL1").with(headers: @headers)
            # get file
            expect(WebMock).to have_requested(:get, 'https://api-content.dropbox.com/1/files/sandbox/exportation%20vers%20idocus/ts%25col1/ts%250001%20-%20abc/p%C3%A9riode%20actuelle/ac/corrupted.pdf').with(headers: @headers)
            # rename file
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/move?from_path=/exportation%20vers%20idocus/ts%25col1/ts%250001%20-%20abc/p%C3%A9riode%20actuelle/ac/corrupted.pdf&root=sandbox&to_path=/exportation%20vers%20idocus/ts%25col1/ts%250001%20-%20abc/p%C3%A9riode%20actuelle/ac/corrupted%20(erreur%20fichier%20non%20valide%20pour%20iDocus).pdf').with(headers: @headers)

            expect(WebMock).to have_requested(:any, /.*/).times(3)

            temp_pack = TempPack.where(name: 'TS%0001 AC 201502 all').first
            expect(temp_pack).to be_nil
          end
        end

        context 'given an invalid file already marked at : /exportation vers iDocus/TS%COL1/TS%0001 - ABC/période actuelle/AC/corrupted (erreur fichier non valide pour idocus).pdf' do
          it 'ignores one file marked invalid' do
            delta_cursor = @dropbox.delta_cursor = 'AAG2JqUOLV_173LQAf6tJMKGMbDfuhBN9RfaUT7ShWoIhHQdWMU8QfgR2PAwFavUXOt8ej36yQDbkmRyh-kP8h1j_PklEVzNKG6HBclc5Fwirn-MHnL9dxYReqopWJfD1U82YMlAGDiFzvZfVyn7EviqOXfNpin_5KHHt3z9Et-u5g'
            @dropbox.save

            VCR.use_cassette('dropbox_import_folder/collaborator/ignores_one_file_marked_invalid') do
              DropboxImportFolder.new(@dropbox).check
            end

            # delta
            expect(WebMock).to have_requested(:post, "https://api.dropbox.com/1/delta?cursor=#{delta_cursor}&path_prefix=/exportation%20vers%20iDocus/TS%25COL1").with(headers: @headers)

            expect(WebMock).to have_requested(:any, /.*/).once

            temp_pack = TempPack.where(name: 'TS%0001 AC 201502 all').first
            expect(temp_pack).to be_nil
          end
        end

        context 'given folder "/exportation vers iDocus/TS%COL1/TS%0002 - BEF" is removed' do
          it 'recreates deleted folders' do
            delta_cursor = @dropbox.delta_cursor = 'AAFTQsbKiqFgM0AiRuQ4PA07KluNBgRehry6_d5aMlcRCRWh-SM_j5DAax1xfQiHfHGE7rwo9gdRqRFI4OUSipqjdGS3N5wZYWVekRFdLrUyEK9rdxqhRdCNednnIy_iuEPBYr8abbtOOto63_lOP3UH7c16BB0FXSdoEGW4H6MPag'
            @dropbox.save

            VCR.use_cassette('dropbox_import_folder/collaborator/recreates_deleted_folders') do
              DropboxImportFolder.new(@dropbox).check
            end

            # delta
            expect(WebMock).to have_requested(:post, "https://api.dropbox.com/1/delta?cursor=#{delta_cursor}&path_prefix=/exportation%20vers%20iDocus/TS%25COL1").with(headers: @headers)
            # creates folder '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période actuelle/AC'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder?path=/exportation%20vers%20iDocus/TS%25COL1/TS%250002%20-%20DEF/p%C3%A9riode%20actuelle/AC&root=sandbox').with(headers: @headers)
            # creates folder '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période actuelle/BQ'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder?path=/exportation%20vers%20iDocus/TS%25COL1/TS%250002%20-%20DEF/p%C3%A9riode%20actuelle/BQ&root=sandbox').with(headers: @headers)
            # creates folder '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période précédente/AC'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder?path=/exportation%20vers%20iDocus/TS%25COL1/TS%250002%20-%20DEF/p%C3%A9riode%20pr%C3%A9c%C3%A9dente/AC&root=sandbox').with(headers: @headers)
            # creates folder '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période précédente/BQ'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder?path=/exportation%20vers%20iDocus/TS%25COL1/TS%250002%20-%20DEF/p%C3%A9riode%20pr%C3%A9c%C3%A9dente/BQ&root=sandbox').with(headers: @headers)

            expect(WebMock).to have_requested(:any, /.*/).times(5)
          end
        end

        context 'given folder at "/exportation vers iDocus/TS%COL1/TS%0001 - ABC" renamed or moved to "OLD"' do
          it 'recreates renamed or moved folders' do
            delta_cursor = @dropbox.delta_cursor = 'AAE4uvq0UnA5udRVwaNwhFy2qXP0JNbyKsgcXZdZ6F1UqXKE3I-Stv4_MlF6GAA045GWbM4iLj42Sh3YpEeM1ruK97r0DwXXaYnao6VQgB7_Mm_xaWj4g49b_hpmKhzWT82FW9lDtgQxuLwgjhLjYcsAOgjR1qIZ-IDjTsuAvMyYZA'
            @dropbox.save

            VCR.use_cassette('dropbox_import_folder/collaborator/recreates_renamed_or_moved_folders') do
              DropboxImportFolder.new(@dropbox).check
            end

            # delta
            expect(WebMock).to have_requested(:post, "https://api.dropbox.com/1/delta?cursor=#{delta_cursor}&path_prefix=/exportation%20vers%20iDocus/TS%25COL1").with(headers: @headers)
            # creates folder '/exportation vers iDocus/TS%COL1/TS%0001 - ABC/période actuelle/AC'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder?path=/exportation%20vers%20iDocus/TS%25COL1/TS%250001%20-%20ABC/p%C3%A9riode%20actuelle/AC&root=sandbox').with(headers: @headers)
            # creates folder '/exportation vers iDocus/TS%COL1/TS%0001 - ABC/période actuelle/VT'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder?path=/exportation%20vers%20iDocus/TS%25COL1/TS%250001%20-%20ABC/p%C3%A9riode%20actuelle/VT&root=sandbox').with(headers: @headers)
            # creates folder '/exportation vers iDocus/TS%COL1/TS%0001 - ABC/période précédente/AC'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder?path=/exportation%20vers%20iDocus/TS%25COL1/TS%250001%20-%20ABC/p%C3%A9riode%20pr%C3%A9c%C3%A9dente/AC&root=sandbox').with(headers: @headers)
            # creates folder '/exportation vers iDocus/TS%COL1/TS%0001 - ABC/période précédente/VT'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder?path=/exportation%20vers%20iDocus/TS%25COL1/TS%250001%20-%20ABC/p%C3%A9riode%20pr%C3%A9c%C3%A9dente/VT&root=sandbox').with(headers: @headers)

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
            delta_cursor = @dropbox.delta_cursor = 'AAG-wLmKCIa4wEISQcCQAio9DFoQ8xytlMG6S3qiJRuqSy8pTidLx_D3sEG1UE1zo9mjapUlWml0cOqSvuzFKkfJjTMjy8eVQi-hSsc4G_W2IJ9kWPp2d49W2FNjfdyDIzdHWNZ4nWO5vT6LamdsYnxsNKxMBAA3nHdaXP39GWmYZQ'
            @dropbox.save

            VCR.use_cassette('dropbox_import_folder/collaborator/creates_2_folders_vt') do
              DropboxImportFolder.new(@dropbox).check
            end

            # delta
            expect(WebMock).to have_requested(:post, "https://api.dropbox.com/1/delta?cursor=#{delta_cursor}&path_prefix=/exportation%20vers%20iDocus/TS%25COL1").with(headers: @headers)
            # create folder '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période actuelle/VT'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder?path=/exportation%20vers%20iDocus/TS%25COL1/TS%250002%20-%20DEF/p%C3%A9riode%20actuelle/VT&root=sandbox').with(headers: @headers)
            # create folder '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période précédente/VT'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder?path=/exportation%20vers%20iDocus/TS%25COL1/TS%250002%20-%20DEF/p%C3%A9riode%20pr%C3%A9c%C3%A9dente/VT&root=sandbox').with(headers: @headers)

            expect(WebMock).to have_requested(:any, /.*/).times(3)
          end
        end

        context 'given journal BQ is renamed BQ1' do
          before(:all) do
            @user2.account_book_types.where(name: 'BQ').update(name: 'BQ1')
          end

          after(:all) do
            @user2.account_book_types.where(name: 'BQ1').update(name: 'BQ')
          end

          it 'deletes 2 folders BQ and creates 2 folders BQ1' do
            delta_cursor = @dropbox.delta_cursor = 'AAHFIuSQJFLWWWBxk0SuUGdC7NnHzUUugEokgzPU4ws5yATzyytmzd2cX_SwORSqS797p6whZVczhHHnWrbsU7cHArR4xH7_GuZp9f3uOS-wskJ_mKlWDBou_fQ_cHC9xXhV-J4gmEri_lUhEG5kCL2yg6QA1zU-OnFPnB2W9GBgbg'
            @dropbox.save

            VCR.use_cassette('dropbox_import_folder/collaborator/deletes_2_folders_BQ_and_creates_2_folders_bq1') do
              DropboxImportFolder.new(@dropbox).check
            end

            # delta
            expect(WebMock).to have_requested(:post, "https://api.dropbox.com/1/delta?cursor=#{delta_cursor}&path_prefix=/exportation%20vers%20iDocus/TS%25COL1").with(headers: @headers)
            # create folder 'BQ1' into folder 'période actuelle'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder?path=/exportation%20vers%20iDocus/TS%25COL1/TS%250002%20-%20DEF/p%C3%A9riode%20actuelle/BQ1&root=sandbox').with(headers: @headers)
            # create folder 'BQ1' into folder 'période précédente'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder?path=/exportation%20vers%20iDocus/TS%25COL1/TS%250002%20-%20DEF/p%C3%A9riode%20pr%C3%A9c%C3%A9dente/BQ1&root=sandbox').with(headers: @headers)
            # delete folder 'BQ' into folder 'période actuelle'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/delete?path=/exportation%20vers%20iDocus/TS%25COL1/TS%250002%20-%20DEF/p%C3%A9riode%20actuelle/BQ&root=sandbox').with(headers: @headers)
            # delete folder 'BQ' into folder 'période précédente'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/delete?path=/exportation%20vers%20iDocus/TS%25COL1/TS%250002%20-%20DEF/p%C3%A9riode%20pr%C3%A9c%C3%A9dente/BQ&root=sandbox').with(headers: @headers)

            expect(WebMock).to have_requested(:any, /.*/).times(5)
          end
        end

        context 'given journal VT is removed' do
          before(:all) do
            @user2.account_book_types.where(name: 'BQ').update(name: 'BQ1')
          end

          after(:all) do
            @user2.account_book_types.where(name: 'BQ1').update(name: 'BQ')
          end

          it 'deletes 2 folders VT' do
            delta_cursor = @dropbox.delta_cursor = 'AAH0y7qHzlsm42XuS3VsLCF3QmrvyGVp7FZmxNq_RcAJWorMEf6lEHDbsGquwJJeOEbWLAG4RJkszUf1NMtxzCJvmtl0sM1zsuMnS-pzWrWhousiWxRJX8645sDxJCxEqs1V3PTvnfOA4DHBWC47Iz_agZhxxhcmNm0IiOavaQ4aMg'
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

            VCR.use_cassette('dropbox_import_folder/collaborator/deletes_2_folders_VT') do
              DropboxImportFolder.new(@dropbox).check
            end

            # delta
            expect(WebMock).to have_requested(:post, "https://api.dropbox.com/1/delta?cursor=#{delta_cursor}&path_prefix=/exportation%20vers%20iDocus/TS%25COL1").with(headers: @headers)
            # delete folder 'VT' into folder 'période actuelle'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/delete?path=/exportation%20vers%20iDocus/TS%25COL1/TS%250002%20-%20DEF/p%C3%A9riode%20actuelle/VT&root=sandbox').with(headers: @headers)
            # delete folder 'VT' into folder 'période précédente'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/delete?path=/exportation%20vers%20iDocus/TS%25COL1/TS%250002%20-%20DEF/p%C3%A9riode%20pr%C3%A9c%C3%A9dente/VT&root=sandbox').with(headers: @headers)

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
            delta_cursor = @dropbox.delta_cursor = 'AAHMXgzzm-HWVn2gu7ZRfoKxW90zSNa6-7whYtzhhDh2qNopbjOdrWC-sfPCaxv7ohi2rm0mLQ1GUWT5z0x_u5Lq4gtQp-YlQW5IyEf2V5GVLJWN7E4Ytuww_fXPTSyl0ZdUIc5rlrAGIe5inY1SKGwGkAf5Dqsy50G7onECq6s1Eg'
            @dropbox.save

            VCR.use_cassette('dropbox_import_folder/collaborator/removes_folder_ts%0001_-_abc') do
              DropboxImportFolder.new(@dropbox).check
            end

            # delta
            expect(WebMock).to have_requested(:post, "https://api.dropbox.com/1/delta?cursor=#{delta_cursor}&path_prefix=/exportation%20vers%20iDocus/TS%25COL1").with(headers: @headers)
            # deletes folder TS%0001 - ABC
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/delete?path=/exportation%20vers%20iDocus/TS%25COL1/TS%250001%20-%20ABC&root=sandbox').with(headers: @headers)

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
            delta_cursor = @dropbox.delta_cursor = 'AAGCHcV1jdcMV3psRBxXHISYoIOApIQqbltOlSQjv07H5sVa0nSzdg33Rh6pb3TLV-sPnK7OEgQM_GMbFu2aDSlKIzrrfQGhpNsegqIW3wt9bjEXssYQbgvTgz2ElWL8ta3cmxBC7US-ArkXw84KZuHbt4gZwe0cti_ovitErwAhDg'
            @dropbox.save

            VCR.use_cassette('dropbox_import_folder/collaborator/creates_ts%0003s_folders') do
              DropboxImportFolder.new(@dropbox).check
            end

            # delta
            expect(WebMock).to have_requested(:post, "https://api.dropbox.com/1/delta?cursor=#{delta_cursor}&path_prefix=/exportation%20vers%20iDocus/TS%25COL1").with(headers: @headers)
            # creates folder '/exportation vers iDocus/TS%COL1/TS%0003 - GHI/période actuelle/AC'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder?path=/exportation%20vers%20iDocus/TS%25COL1/TS%250003%20-%20GHI/p%C3%A9riode%20actuelle/AC&root=sandbox').with(headers: @headers)
            # creates folder '/exportation vers iDocus/TS%COL1/TS%0003 - GHI/période actuelle/BQ'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder?path=/exportation%20vers%20iDocus/TS%25COL1/TS%250003%20-%20GHI/p%C3%A9riode%20actuelle/BQ&root=sandbox').with(headers: @headers)
            # creates folder '/exportation vers iDocus/TS%COL1/TS%0003 - GHI/période précédente/AC'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder?path=/exportation%20vers%20iDocus/TS%25COL1/TS%250003%20-%20GHI/p%C3%A9riode%20pr%C3%A9c%C3%A9dente/AC&root=sandbox').with(headers: @headers)
            # creates folder '/exportation vers iDocus/TS%COL1/TS%0003 - GHI/période précédente/BQ'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder?path=/exportation%20vers%20iDocus/TS%25COL1/TS%250003%20-%20GHI/p%C3%A9riode%20pr%C3%A9c%C3%A9dente/BQ&root=sandbox').with(headers: @headers)

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
            delta_cursor = @dropbox.delta_cursor = 'AAF9_atGN6nync9ulo96tCrJu41UT-YYwiLVOSwAIN_uNdJvk4Yu88gg5Sayr7fGi6syiPgjQk7xI1jDI77CUp7JVIO86xEYHIadKS4cGUBGHmsrFVpZOKVmlaqw6F-culSF3lrDBkJuSDZEUXzxoxvV5a7oOJ19XzMOzYpLet0EJg'
            @dropbox.save

            VCR.use_cassette('dropbox_import_folder/collaborator/renames_folder_ts%0002_-_def') do
              DropboxImportFolder.new(@dropbox).check
            end

            # delta
            expect(WebMock).to have_requested(:post, "https://api.dropbox.com/1/delta?cursor=#{delta_cursor}&path_prefix=/exportation%20vers%20iDocus/TS%25COL1").with(headers: @headers)
            # deletes folder '/exportation vers iDocus/TS%0002 - DEF'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/delete?path=/exportation%20vers%20iDocus/TS%25COL1/TS%250002%20-%20DEF&root=sandbox').with(headers: @headers)
            # creates folder '/exportation vers iDocus/TS%COL1/TS%0002 - DDD/période actuelle/AC'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder?path=/exportation%20vers%20iDocus/TS%25COL1/TS%250002%20-%20DDD/p%C3%A9riode%20actuelle/AC&root=sandbox').with(headers: @headers)
            # creates folder '/exportation vers iDocus/TS%COL1/TS%0002 - DDD/période actuelle/BQ'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder?path=/exportation%20vers%20iDocus/TS%25COL1/TS%250002%20-%20DDD/p%C3%A9riode%20actuelle/BQ&root=sandbox').with(headers: @headers)
            # creates folder '/exportation vers iDocus/TS%COL1/TS%0002 - DDD/période précédente/AC'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder?path=/exportation%20vers%20iDocus/TS%25COL1/TS%250002%20-%20DDD/p%C3%A9riode%20pr%C3%A9c%C3%A9dente/AC&root=sandbox').with(headers: @headers)
            # creates folder '/exportation vers iDocus/TS%COL1/TS%0002 - DDD/période précédente/BQ'
            expect(WebMock).to have_requested(:post, 'https://api.dropbox.com/1/fileops/create_folder?path=/exportation%20vers%20iDocus/TS%25COL1/TS%250002%20-%20DDD/p%C3%A9riode%20pr%C3%A9c%C3%A9dente/BQ&root=sandbox').with(headers: @headers)

            expect(WebMock).to have_requested(:any, /.*/).times(6)
          end
        end
      end
    end
  end
end
