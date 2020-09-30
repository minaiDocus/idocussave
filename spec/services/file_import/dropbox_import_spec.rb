# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe FileImport::Dropbox do
  before(:each) do
    Timecop.freeze(Time.local(2015,2,15))
  end

  after(:all) do
    Timecop.return
  end

  describe '#check' do
    context 'as a customer' do
      before(:each) do
        DatabaseCleaner.start

        @user = FactoryBot.create(:user, code: 'TS%0001')
        @user.options = UserOptions.create(user_id: @user.id, is_upload_authorized: true)

        AccountBookType.create(user_id: @user.id, name: 'AC', description: '( Achat )')
        AccountBookType.create(user_id: @user.id, name: 'VT', description: '( Vente )')

        efs = @user.find_or_create_external_file_storage
        efs.use ExternalFileStorage::F_DROPBOX
        @dropbox = efs.dropbox_basic
        @dropbox.access_token = 'K4z7I_InsgsAAAAAAAAAkZ76RjGf_qZVQ6y72HOjmCJ1FWGFufHC9ZGbfuqO3fQO'
        @dropbox.save

        @user.reload

        @headers = { 'Authorization' => "Bearer #{@dropbox.access_token}" }
        @headers_2 = @headers.merge({ 'Content-Type' => 'application/json' })
      end

      after(:each) { DatabaseCleaner.clean }

      it 'creates initial folders' do
        dropbox_import = FileImport::Dropbox.new(@dropbox)

        expect(dropbox_import.folders.size).to eq 4
        expect(dropbox_import.folders.select(&:exist?).size).to eq 0
        expect(dropbox_import.folders.select(&:to_be_destroyed?).size).to eq 0
        expect(dropbox_import.folders.select(&:to_be_created?).size).to eq 4

        VCR.use_cassette('dropbox_import/customer/creates_initial_folders') do
          dropbox_import.check
        end

        folder_paths = [
          '/exportation vers iDocus/TS%0001 - TeSt/période actuelle/AC',
          '/exportation vers iDocus/TS%0001 - TeSt/période actuelle/VT',
          '/exportation vers iDocus/TS%0001 - TeSt/période précédente/AC',
          '/exportation vers iDocus/TS%0001 - TeSt/période précédente/VT'
        ]

        # creates 4 folders
        4.times do |i|
          expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/create_folder').
            with(headers: @headers_2).with(body: { path: folder_paths[i] })
        end
        # get latest cursor
        expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/get_latest_cursor').
          with(headers: @headers_2, body: '{"path":"/exportation vers iDocus","recursive":true,"include_media_info":false,"include_deleted":false}')
        # delta
        expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/continue').
          with(headers: @headers_2, body: /\{"cursor":".*"\}/)

        expect(WebMock).to have_requested(:any, /.*/).times(6)

        expect(@dropbox.checked_at).to be_present
        expect(@dropbox.delta_cursor).to be_present
        expect(@dropbox.delta_path_prefix).to eq('/exportation vers iDocus')
        expect(@dropbox.import_folder_paths).to eq(folder_paths)

        expect(dropbox_import.folders.size).to eq 4
        expect(dropbox_import.folders.select(&:exist?).size).to eq 4
      end

      context 'given initial folders have been created' do
        before(:each) do
          @dropbox.delta_path_prefix = '/exportation vers iDocus'
          @dropbox.import_folder_paths = [
            '/exportation vers iDocus/TS%0001 - TeSt/période actuelle/AC',
            '/exportation vers iDocus/TS%0001 - TeSt/période actuelle/VT',
            '/exportation vers iDocus/TS%0001 - TeSt/période précédente/AC',
            '/exportation vers iDocus/TS%0001 - TeSt/période précédente/VT'
          ]
          @dropbox.save
        end

        # NOTE: needs a better implementation of error
        it 'handles folder create failure' do
          delta_cursor = @dropbox.delta_cursor = 'AAGAn2SbSgsDiJEQ7d5xLJOVrJrtdBuq9pXxPFRn2t8MFh3pFpzj6ijub-dywcNHDRoPfp9WPJa_6I9IKJm7faymRQvgjoc8YKXmmJr3KEiU_U01ABnCn4zRxQfix584Sx45KGncYIyw065Z4tqb5lpKjnTVS7US9w7kEYj66q41k1z7iVmtwugJMcIXWhZhVKo'
          @dropbox.import_folder_paths = []
          @dropbox.save

          dropbox_import = FileImport::Dropbox.new(@dropbox)

          expect(dropbox_import.folders.size).to eq 4
          expect(dropbox_import.folders.select(&:exist?).size).to eq 0
          expect(dropbox_import.folders.select(&:to_be_destroyed?).size).to eq 0
          expect(dropbox_import.folders.select(&:to_be_created?).size).to eq 4

          VCR.use_cassette('dropbox_import/customer/handles_folder_create_failure') do
            dropbox_import.check
          end

          folder_paths = [
            '/exportation vers iDocus/TS%0001 - TeSt/période actuelle/AC',
            '/exportation vers iDocus/TS%0001 - TeSt/période actuelle/VT',
            '/exportation vers iDocus/TS%0001 - TeSt/période précédente/AC',
            '/exportation vers iDocus/TS%0001 - TeSt/période précédente/VT'
          ]

          # delta
          expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/continue').
            with(headers: @headers_2, body: /\{"cursor":".*"\}/)
          # fails to create 4 folders
          folder_paths.each do |path|
            expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/create_folder').
              with(headers: @headers_2, body: { path: path })
          end
          expect(WebMock).to have_requested(:any, /.*/).times(5)

          expect(@dropbox.import_folder_paths).to eq(folder_paths)
          expect(dropbox_import.folders.size).to eq 4
          expect(dropbox_import.folders.select(&:exist?).size).to eq 4
        end

        context 'given a valid file at : /exportation vers iDocus/TS%0001 - TeSt/période actuelle/AC/test.pdf' do
          it 'fetches one valid file' do
            delta_cursor = @dropbox.delta_cursor = 'AAHuDBnQ43SLoVF1tHaTZFX-BAP6ehQyXrd7c6fLyz8_zGt2EsGZBHLfEMOWakddGquh1eZLtLF-mgAsWOVLcl3bT_aqRiBTCyWBHMcmWLgvFMHTTn2CIyl8hdOy3PE_x_xhRirH0Y3PsuAOfJhMVJM9iJulqrNR9uC6cBrLUp2pU8r2EO7fXyoYcOFOaz4117I'
            @dropbox.save

            dropbox_import = FileImport::Dropbox.new(@dropbox)
            VCR.use_cassette('dropbox_import/customer/fetches_one_valid_file') do
              dropbox_import.check
            end

            # delta
            expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/continue').
              with(headers: @headers_2, body: { cursor: delta_cursor })
            # get file
            expect(WebMock).to have_requested(:post, 'https://content.dropboxapi.com/2/files/download').
              with(headers: @headers.merge({ 'Dropbox-API-Arg' => { path: '/exportation vers iDocus/TS%0001 - TeSt/période actuelle/AC/test.pdf' }.to_json }))
            # delete file
            expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/delete').
              with(headers: @headers_2, body: { path: "/exportation vers iDocus/TS%0001 - TeSt/période actuelle/AC/test.pdf" })

            expect(WebMock).to have_requested(:any, /.*/).times(3)

            temp_pack = TempPack.where(name: 'TS%0001 AC 201502 all').first
            temp_document = temp_pack.temp_documents.first
            fingerprint = `md5sum #{temp_document.cloud_content_object.path}`.split.first
            expect(temp_pack.temp_documents.count).to eq 1
            expect(temp_document.original_file_name).to eq 'test.pdf'
            expect(fingerprint).to eq '97f90eac0d07fe5ade8f60a0fa54cdfc'
            expect(dropbox_import.folders.map(&:exist?).uniq).to eq [true]
          end
        end

        # NOTE: needs a better implementation of error
        it 'handles failure' do
          delta_cursor = @dropbox.delta_cursor = 'AAHuDBnQ43SLoVF1tHaTZFX-BAP6ehQyXrd7c6fLyz8_zGt2EsGZBHLfEMOWakddGquh1eZLtLF-mgAsWOVLcl3bT_aqRiBTCyWBHMcmWLgvFMHTTn2CIyl8hdOy3PE_x_xhRirH0Y3PsuAOfJhMVJM9iJulqrNR9uC6cBrLUp2pU8r2EO7fXyoYcOFOaz4117I'
          @dropbox.save

          is_error_raised = false
          allow_any_instance_of(DropboxApi::Client).to receive(:download).and_wrap_original do |m, *args, &block|
            if is_error_raised
              m.call(*args, &block)
            else
              is_error_raised = true
              raise DropboxApi::Errors::RateLimitError.new('rate limit', nil)
            end
          end

          dropbox_import = FileImport::Dropbox.new(@dropbox)
          VCR.use_cassette('dropbox_import/customer/fetches_one_valid_file') do
            dropbox_import.check
          end

          # delta
          expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/continue').
            with(headers: @headers_2, body: { cursor: delta_cursor })
          # get file
          expect(WebMock).to have_requested(:post, 'https://content.dropboxapi.com/2/files/download').
            with(headers: @headers.merge({ 'Dropbox-API-Arg' => { path: '/exportation vers iDocus/TS%0001 - TeSt/période actuelle/AC/test.pdf' }.to_json }))
          # delete file
          expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/delete').
            with(headers: @headers_2, body: { path: "/exportation vers iDocus/TS%0001 - TeSt/période actuelle/AC/test.pdf" })

          expect(WebMock).to have_requested(:any, /.*/).times(3)

          temp_pack = TempPack.where(name: 'TS%0001 AC 201502 all').first
          temp_document = temp_pack.temp_documents.first
          fingerprint = `md5sum #{temp_document.cloud_content_object.path}`.split.first
          expect(temp_pack.temp_documents.count).to eq 1
          expect(temp_document.original_file_name).to eq 'test.pdf'
          expect(fingerprint).to eq '97f90eac0d07fe5ade8f60a0fa54cdfc'
          expect(dropbox_import.folders.map(&:exist?).uniq).to eq [true]
        end

        context 'given an invalid file at : /exportation vers iDocus/TS%0001 - TeSt/période actuelle/AC/corrupted.pdf' do
          it 'marks one invalid file' do
            delta_cursor = @dropbox.delta_cursor = 'AAFMxB16PCTlIIMB7-YQ0lef5ZMPYf5AdL_BuVAEWnaEYxyMl4QOUOMZeo09FmTsnw9N69LW0reEqPCxGDMlvRKkC-3LjZI-FLrInuAL_BmVQ59HKIWSG8HNHd9gpHuodrkT8ocFy1ZrCNKv33gjmQz-6GQ3dZzZKQTwAa_UvgCq1Apd8ilPmuhiWGpU5peXAQg'
            @dropbox.save

            dropbox_import = FileImport::Dropbox.new(@dropbox)
            VCR.use_cassette('dropbox_import/customer/marks_one_invalid_file') do
              dropbox_import.check
            end

            # delta
            expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/continue').
              with(headers: @headers_2, body: { cursor: delta_cursor })
            # get file
            expect(WebMock).to have_requested(:post, 'https://content.dropboxapi.com/2/files/download').
              with(headers: @headers.merge({ 'Dropbox-API-Arg' => { path: '/exportation vers iDocus/TS%0001 - TeSt/période actuelle/AC/corrupted.pdf' }.to_json }))
            # rename file
            expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/move').
              with(headers: @headers_2, body: { autorename: true, from_path: '/exportation vers iDocus/TS%0001 - TeSt/période actuelle/AC/corrupted.pdf', to_path: '/exportation vers iDocus/TS%0001 - TeSt/période actuelle/AC/corrupted (fichier corrompu ou protégé par mdp).pdf' })

            expect(WebMock).to have_requested(:any, /.*/).times(3)

            expect(dropbox_import.folders.map(&:exist?).uniq).to eq [true]

            temp_pack = TempPack.where(name: 'TS%0001 AC 201502 all').first
            expect(temp_pack).to be_nil
          end
        end

        context 'given an invalid file already marked at : /exportation vers iDocus/TS%0001 - TeSt/période actuelle/AC/corrupted (erreur fichier non valide pour idocus).pdf' do
          it 'ignores one file marked invalid' do
            delta_cursor = @dropbox.delta_cursor = 'AAEivgBH2vsUaoBM7nR_LRdKE2sYxL0nQHixwSv1-B9E_h0fdbgmy1aT4e7UTvOEshTJVEouMI9TXx-wY4TNhW79OAnTQIaPk3GwYsQ2dgvjf1vdzRmXuGnZvNs_c0J2fMJktmeWdbeOWUz9eVXhpZmEPSKCFXORtSZElG8A14GGYpEQetIiTvLCBDeQ_EyFUTA'
            @dropbox.save

            dropbox_import = FileImport::Dropbox.new(@dropbox)
            VCR.use_cassette('dropbox_import/customer/ignores_one_file_marked_invalid') do
              dropbox_import.check
            end

            # delta
            expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/continue').
              with(headers: @headers_2, body: { cursor: delta_cursor })

            expect(WebMock).to have_requested(:any, /.*/).once

            expect(dropbox_import.folders.map(&:exist?).uniq).to eq [true]

            temp_pack = TempPack.where(name: 'TS%0001 AC 201502 all').first
            expect(temp_pack).to be_nil
          end

          context 'given another invalid file with the same name at : /exportation vers iDocus/TS%0001 - TeSt/période actuelle/AC/corrupted.pdf' do
            it 'marks the file as invalid but with number : corrupted (fichier corrompu ou protégé par mdp) (1).pdf' do
              delta_cursor = @dropbox.delta_cursor = 'AAEoM_ev4xOyiBuzDKXR1l62aBvB_IQw9t__CMFJ8P5zjiZaEYPXY3Lb82-jNHOatUoLebLikcT6t0N6K74bjw2LTQMKNSqRTMi95VX_e0srrbo6pqTiPCSxmXFTtLTheEJzHpIM9M6leMfIH4dqfqmZkgYE_Rl1CUebwY-6xtqU0ruCCX80np4kg3Uj3b4SPQU'
              @dropbox.save

              dropbox_import = FileImport::Dropbox.new(@dropbox)
              VCR.use_cassette('dropbox_import/customer/rename_automatically_the_same_invalid_file') do
                dropbox_import.check
              end

              # delta
              expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/continue').
                with(headers: @headers_2, body: { cursor: delta_cursor })
              # get file
              expect(WebMock).to have_requested(:post, 'https://content.dropboxapi.com/2/files/download').
                with(headers: @headers.merge({ 'Dropbox-API-Arg' => { path: '/exportation vers iDocus/TS%0001 - TeSt/période actuelle/AC/corrupted.pdf' }.to_json }))
              # rename file
              expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/move').
                with(headers: @headers_2, body: { autorename: true, from_path: '/exportation vers iDocus/TS%0001 - TeSt/période actuelle/AC/corrupted.pdf', to_path: '/exportation vers iDocus/TS%0001 - TeSt/période actuelle/AC/corrupted (fichier corrompu ou protégé par mdp).pdf' })

              expect(WebMock).to have_requested(:any, /.*/).times(3)

              expect(dropbox_import.folders.map(&:exist?).uniq).to eq [true]

              temp_pack = TempPack.where(name: 'TS%0001 AC 201502 all').first
              expect(temp_pack).to be_nil
            end
          end
        end

        context 'given a file already exist' do
          before(:each) do
            @temp_pack = TempPack.find_or_create_by_name 'TS%0001 AC 201502 all'
            @temp_pack.user = @user
            @temp_pack.save

            temp_document = TempDocument.new
            temp_document.user                = @user
            # temp_document.content             = File.open(File.join(Rails.root, 'spec/support/files/2pages.pdf'))
            temp_document.position            = 1
            temp_document.temp_pack           = @temp_pack
            temp_document.original_file_name  = '2pages.pdf'
            temp_document.delivered_by        = 'Tester'
            temp_document.delivery_type       = 'upload'
            file_path = File.join(Rails.root, 'spec/support/files/2pages.pdf')
            temp_document.cloud_content.attach(io: File.open(file_path), filename: File.basename(file_path)) if temp_document.save
          end

          it 'marks one file as already exist' do
            delta_cursor = @dropbox.delta_cursor = 'AAFo1FwisKkH63Oi8KcMuycHN8FBJQXb_QAkzhbpnsp26qshk4QuzEWnz-ygFFuUwV9x-5g_s332-fpJF2I69IU1uDsbs2bit3oBPmIf6LA7wKRCj7HMXxUuURzhQ19o-c_Qzj82CF84DmAaFYaUYLLBARMJXebjy0d3Em0wp0bDTyk1HlIf5RP5Ju3MHuh0VFU'
            @dropbox.save

            dropbox_import = FileImport::Dropbox.new(@dropbox)
            VCR.use_cassette('dropbox_import/customer/marks_one_file_as_already_exist') do
              dropbox_import.check
            end

            # delta
            expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/continue').
              with(headers: @headers_2, body: { cursor: delta_cursor })
            # get file
            expect(WebMock).to have_requested(:post, 'https://content.dropboxapi.com/2/files/download').
              with(headers: @headers.merge({ 'Dropbox-API-Arg' => { path: '/exportation vers iDocus/TS%0001 - TeSt/période actuelle/AC/2pages.pdf' }.to_json }))
            # rename file
            expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/move').
              with(headers: @headers_2, body: { autorename: true, from_path: '/exportation vers iDocus/TS%0001 - TeSt/période actuelle/AC/2pages.pdf', to_path: '/exportation vers iDocus/TS%0001 - TeSt/période actuelle/AC/2pages (fichier déjà importé sur iDocus).pdf' })

            expect(WebMock).to have_requested(:any, /.*/).times(3)

            expect(dropbox_import.folders.map(&:exist?).uniq).to eq [true]

            expect(@temp_pack.temp_documents.count).to eq 1
          end
        end

        context 'the number of elements exceeds one page' do
          it 'queries multiple times' do
            delta_cursor = @dropbox.delta_cursor = 'AAHuDBnQ43SLoVF1tHaTZFX-BAP6ehQyXrd7c6fLyz8_zGt2EsGZBHLfEMOWakddGquh1eZLtLF-mgAsWOVLcl3bT_aqRiBTCyWBHMcmWLgvFMHTTn2CIyl8hdOy3PE_x_xhRirH0Y3PsuAOfJhMVJM9iJulqrNR9uC6cBrLUp2pU8r2EO7fXyoYcOFOaz4117I'
            @dropbox.save

            VCR.use_cassette('dropbox_import/customer/queries_list_folder_continue_multiple_times') do
              FileImport::Dropbox.new(@dropbox).check
            end

            expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/continue').
              with(headers: @headers_2, body: { cursor: delta_cursor })
            expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/continue').
              with(headers: @headers_2, body: { cursor: 'AAFMxB16PCTlIIMB7-YQ0lef5ZMPYf5AdL_BuVAEWnaEYxyMl4QOUOMZeo09FmTsnw9N69LW0reEqPCxGDMlvRKkC-3LjZI-FLrInuAL_BmVQ59HKIWSG8HNHd9gpHuodrkT8ocFy1ZrCNKv33gjmQz-6GQ3dZzZKQTwAa_UvgCq1Apd8ilPmuhiWGpU5peXAQg' })

            expect(WebMock).to have_requested(:any, /.*/).times(2)

            expect(@dropbox.delta_cursor).to eq 'AAFeVq99ipMnuvVTcNS7_M5vHAmtvDE0RvvT9kPOvQVHOv5VDUaP1evskfuIC9BEO2PBGW-7c5T_3wwgyzKdww0nspvUWz6LI8G-myyUojkVp_TvYb-PJ5LfKf9ioItpz9wMPeQupbowctZAVBrtFsqqFoUZrDXw5SrrDhvpg3g4GzHVlAGVMdl4U7ZACSV3eUM'
          end
        end

        context 'given a file marked as already exist' do
          it 'ignores one file marked as already exist' do
            delta_cursor = @dropbox.delta_cursor = 'AAFq6giBBjm91uKMrGu4YJodiVo40udFuHEvAY8vz0w3r97GUR4eN7LeJH_jJSQCdgQJ3TXA9RqZ18saDIaTZyDcpuGypub0dGE5tURcygEFrsDbNRUwNYvbUwMnN2lmh3jY9PVvJoIU4tefUyBhv5hVnu7KEDhNvaFupGJj4MgLXsHW3UO3ciSaY_2NXk8Q9ys'
            @dropbox.save

            dropbox_import = FileImport::Dropbox.new(@dropbox)
            VCR.use_cassette('dropbox_import/customer/ignores_one_file_marked_as_already_exist') do
              dropbox_import.check
            end

            # delta
            expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/continue').
              with(headers: @headers_2, body: { cursor: delta_cursor })

            expect(WebMock).to have_requested(:any, /.*/).once

            expect(dropbox_import.folders.map(&:exist?).uniq).to eq [true]

            temp_pack = TempPack.where(name: 'TS%0001 AC 201502 all').first
            expect(temp_pack).to be_nil
          end
        end

        context 'given folder "/exportation vers iDocus/TS%0001 - TeSt/période précédente" is removed' do
          it 'recreates deleted folders' do
            delta_cursor = @dropbox.delta_cursor = 'AAH9bIkS4lX-fdlMd6s07GM08xItNux2lLhnF40Sp91R-pFZL6U4icK15Qg3PPnf2gMdlCaIZyTu6cwqq_9DeOXdagQThQCglBPX4s_QrYEa7hfemDSomRviYchjlPnRsoLO8nYmCO3QGPbSjuuqzDNiHJgnTjIT5FDv3Hfde2nBEEZpFkhaNBMp-zBSBxASrqU'
            @dropbox.save

            dropbox_import = FileImport::Dropbox.new(@dropbox)
            VCR.use_cassette('dropbox_import/customer/recreates_deleted_folders') do
              dropbox_import.check
            end

            # delta
            expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/continue').
              with(headers: @headers_2, body: { cursor: delta_cursor })
            # creates 2 folders
            [
              '/exportation vers iDocus/TS%0001 - TeSt/période précédente/AC',
              '/exportation vers iDocus/TS%0001 - TeSt/période précédente/VT'
            ].each do |path|
              expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/create_folder').
                with(headers: @headers_2, body: { path: path })
            end

            expect(WebMock).to have_requested(:any, /.*/).times(3)

            expect(dropbox_import.folders.map(&:exist?).uniq).to eq [true]
          end
        end

        context 'given folder at "/exportation vers iDocus/TS%0001 - TeSt/période actuelle" renamed or moved to "PERIODE"' do
          it 'recreates renamed or moved folders' do
            delta_cursor = @dropbox.delta_cursor = 'AAFeVq99ipMnuvVTcNS7_M5vHAmtvDE0RvvT9kPOvQVHOv5VDUaP1evskfuIC9BEO2PBGW-7c5T_3wwgyzKdww0nspvUWz6LI8G-myyUojkVp_TvYb-PJ5LfKf9ioItpz9wMPeQupbowctZAVBrtFsqqFoUZrDXw5SrrDhvpg3g4GzHVlAGVMdl4U7ZACSV3eUM'
            @dropbox.save

            dropbox_import = FileImport::Dropbox.new(@dropbox)
            VCR.use_cassette('dropbox_import/customer/recreates_renamed_or_moved_folders') do
              dropbox_import.check
            end

            # delta
            expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/continue').
              with(headers: @headers_2, body: { cursor: delta_cursor })
            # creates 2 folders
            [
              '/exportation vers iDocus/TS%0001 - TeSt/période actuelle/AC',
              '/exportation vers iDocus/TS%0001 - TeSt/période actuelle/VT'
            ].each do |path|
              expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/create_folder').
                with(headers: @headers_2, body: { path: path })
            end

            expect(WebMock).to have_requested(:any, /.*/).times(3)

            expect(dropbox_import.folders.map(&:exist?).uniq).to eq [true]
          end
        end

        context 'given journal BQ is added' do
          before(:each) { @journal = AccountBookType.create(user_id: @user.id, name: 'BQ', description: '( Banque )') }

          it 'creates 2 folders BQ' do
            delta_cursor = @dropbox.delta_cursor = 'AAHyQInjH2qB7WzJ90XnaqJ8wX-5W2MOSD6Ns7HvQ1cQ-pXIGsXfexRdrsF_DQpg_yB4gWhU_SbNmUGU17NHG9r9pN34CjFqbwi3jZ2onMrEr-oRSqI_XsSzrgF1nauvygNn0KVj46wH9DdBIsYVFXvKiWKdQoSy4xjsIAaJRsoexmg1NvIG7hqOz-aG4ALF6qQ'
            @dropbox.save

            dropbox_import = FileImport::Dropbox.new(@dropbox)

            expect(dropbox_import.folders.select(&:exist?).size).to eq 4

            VCR.use_cassette('dropbox_import/customer/creates_2_folders_bq') do
              dropbox_import.check
            end

            # delta
            expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/continue').
              with(headers: @headers_2, body: { cursor: delta_cursor })
            # creates 2 folders
            [
              '/exportation vers iDocus/TS%0001 - TeSt/période actuelle/BQ',
              '/exportation vers iDocus/TS%0001 - TeSt/période précédente/BQ'
            ].each do |path|
              expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/create_folder').
                with(headers: @headers_2, body: { path: path })
            end

            expect(WebMock).to have_requested(:any, /.*/).times(3)

            expect(dropbox_import.folders.select(&:exist?).size).to eq 6
            expect(dropbox_import.folders.map(&:exist?).uniq).to eq [true]
          end

          context 'and then renamed to BQ1' do
            before(:each) { @journal.update(name: 'BQ1') }

            it 'deletes 2 folders BQ and creates 2 folders BQ1' do
              delta_cursor = @dropbox.delta_cursor = 'AAEdoRmjBjz-axr5GUXLfRTY5H8jf7u2Z0_o9-xTatQQWHmDrLlSnauMSBW05uLqGbZX1VNngVt1UZesUapiT816Vt9HUJK_gC4ZRwX5CwVY7AdONNHIJPUlyFWMm-GZRTayENPXNk0RZci7djjyGktgJeXYNM8vsil6IlYvYXQka_1oW2hZjxIOhIm0C2C8geU'
              @dropbox.import_folder_paths = [
                '/exportation vers iDocus/TS%0001 - TeSt/période actuelle/AC',
                '/exportation vers iDocus/TS%0001 - TeSt/période actuelle/VT',
                '/exportation vers iDocus/TS%0001 - TeSt/période actuelle/BQ',
                '/exportation vers iDocus/TS%0001 - TeSt/période précédente/AC',
                '/exportation vers iDocus/TS%0001 - TeSt/période précédente/VT',
                '/exportation vers iDocus/TS%0001 - TeSt/période précédente/BQ'
              ]
              @dropbox.save

              dropbox_import = FileImport::Dropbox.new(@dropbox)

              expect(dropbox_import.folders.size).to eq 8
              expect(dropbox_import.folders.select(&:exist?).size).to eq 4
              expect(dropbox_import.folders.select(&:to_be_destroyed?).size).to eq 2
              expect(dropbox_import.folders.select(&:to_be_created?).size).to eq 2

              VCR.use_cassette('dropbox_import/customer/deletes_2_folders_BQ_and_creates_2_folders_bq1') do
                dropbox_import.check
              end

              # delta
              expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/continue').
                with(headers: @headers_2, body: { cursor: delta_cursor })
              # creates 2 folders
              [
                '/exportation vers iDocus/TS%0001 - TeSt/période actuelle/BQ1',
                '/exportation vers iDocus/TS%0001 - TeSt/période précédente/BQ1'
              ].each do |path|
                expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/create_folder').
                  with(headers: @headers_2, body: { path: path })
              end
              # deletes 2 folders
              [
                '/exportation vers iDocus/TS%0001 - TeSt/période actuelle/BQ',
                '/exportation vers iDocus/TS%0001 - TeSt/période précédente/BQ'
              ].each do |path|
                expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/delete').
                  with(headers: @headers_2, body: { path: path })
              end

              expect(WebMock).to have_requested(:any, /.*/).times(5)

              expect(dropbox_import.folders.size).to eq 6
              expect(dropbox_import.folders.select(&:exist?).size).to eq 6
            end
          end
        end

        context 'given journal VT is removed' do
          before(:each) { @user.account_book_types.where(name: 'VT').first.destroy }

          it 'deletes 2 folders VT' do
            delta_cursor = @dropbox.delta_cursor = 'AAH-0JN3ZNgN-BjXOCWg8-RvBKHf6e8O9G-T1o7Mdk08b6SR7-rbx89Hd-AVv3lTssRPUu1M4kIqcEDkFFpQzApR6oX1BlSrBXL6G9D_4_TTwjkkeEoj1W7b5VPW2II_XovyMw90ks9QYiGR0KM9repqEWrHrAJsFafIrM5ct0jrovuxvkW5MQld7lifv-A4-2s'
            @dropbox.save

            dropbox_import = FileImport::Dropbox.new(@dropbox)

            expect(dropbox_import.folders.size).to eq 4
            expect(dropbox_import.folders.select(&:exist?).size).to eq 2
            expect(dropbox_import.folders.select(&:to_be_destroyed?).size).to eq 2
            expect(dropbox_import.folders.select(&:to_be_created?).size).to eq 0

            VCR.use_cassette('dropbox_import/customer/deletes_2_folders_VT') do
              dropbox_import.check
            end

            # delta
            expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/continue').
              with(headers: @headers_2, body: { cursor: delta_cursor })
            # deletes 2 folders
            [
              '/exportation vers iDocus/TS%0001 - TeSt/période actuelle/VT',
              '/exportation vers iDocus/TS%0001 - TeSt/période précédente/VT'
            ].each do |path|
              expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/delete').
                with(headers: @headers_2, body: { path: path })
            end

            expect(WebMock).to have_requested(:any, /.*/).times(3)

            expect(dropbox_import.folders.size).to eq 2
            expect(dropbox_import.folders.select(&:exist?).size).to eq 2
          end
        end

        context 'given journal AC is removed' do
          context 'given journal OD is created' do
            context 'given folder test is created' do
              context 'given folder "../période précédente/VT" is removed' do
                context 'given 2 files are present inside période actuelle/VT' do
                  it 'executes multiple jobs' do
                    @user.account_book_types.where(name: 'AC').first.destroy
                    AccountBookType.create(user_id: @user.id, name: 'OD', description: '( Opération diverse )')
                    delta_cursor = @dropbox.delta_cursor = 'AAG1osv_3d2MZkjFa45g0cs3rIWX5xhqAtT-9XJgVReR2IRJmSL-FSuOxacN3ciwnAwxJRoQXwYs8dr-HKgeoYpV4qxud85oO46DhfOkSb4vGJ_ATGrKqQLkDpOsZTjUuGe1rs14fK_gw2oifFvqjonEbQB0g6PDUhRKQ24Zrf9pm061EZI1rBh2gZVx12Ob4GA'
                    @dropbox.save

                    dropbox_import = FileImport::Dropbox.new(@dropbox)

                    expect(dropbox_import.folders.size).to eq 6
                    expect(dropbox_import.folders.select(&:exist?).size).to eq 2
                    expect(dropbox_import.folders.select(&:to_be_destroyed?).size).to eq 2
                    expect(dropbox_import.folders.select(&:to_be_created?).size).to eq 2

                    VCR.use_cassette('dropbox_import/customer/executes_multiple_jobs') do
                      dropbox_import.check
                    end

                    # delta
                    expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/continue').
                      with(headers: @headers_2, body: { cursor: delta_cursor })
                    # get corrupted file
                    expect(WebMock).to have_requested(:post, 'https://content.dropboxapi.com/2/files/download').
                      with(headers: @headers.merge({ 'Dropbox-API-Arg' => { path: '/exportation vers iDocus/TS%0001 - TeSt/période actuelle/VT/corrupted.pdf' }.to_json }))
                    # mark corrupted file as invalid
                    expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/move').
                      with(headers: @headers_2, body: { autorename: true, from_path: '/exportation vers iDocus/TS%0001 - TeSt/période actuelle/VT/corrupted.pdf', to_path: '/exportation vers iDocus/TS%0001 - TeSt/période actuelle/VT/corrupted (fichier corrompu ou protégé par mdp).pdf' })
                    # get file
                    expect(WebMock).to have_requested(:post, 'https://content.dropboxapi.com/2/files/download').
                      with(headers: @headers.merge({ 'Dropbox-API-Arg' => { path: '/exportation vers iDocus/TS%0001 - TeSt/période actuelle/VT/2pages.pdf' }.to_json }))
                    # delete file
                    expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/delete').
                      with(headers: @headers_2, body: { path: '/exportation vers iDocus/TS%0001 - TeSt/période actuelle/VT/2pages.pdf' })
                    # remove journal AC from folder période actuelle
                    expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/delete').
                      with(headers: @headers_2, body: { path: '/exportation vers iDocus/TS%0001 - TeSt/période actuelle/AC' })
                    # creates 3 folders
                    [
                      '/exportation vers iDocus/TS%0001 - TeSt/période actuelle/OD',
                      '/exportation vers iDocus/TS%0001 - TeSt/période précédente/OD',
                      '/exportation vers iDocus/TS%0001 - TeSt/période précédente/VT'
                    ].each do |path|
                      expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/create_folder').
                        with(headers: @headers_2, body: { path: path })
                    end

                    expect(WebMock).to have_requested(:any, /.*/).times(9)

                    expect(TempDocument.count).to eq 1

                    expect(dropbox_import.folders.size).to eq 4
                    expect(dropbox_import.folders.select(&:exist?).size).to eq 4
                  end
                end
              end
            end
          end
        end

        context 'given user has access to another account' do
          before(:each) do
            organization = Organization.create(name: 'TEST', code: 'TS')
            organization.customers << @user
            @user2 = FactoryBot.create(:user, code: 'TS%0002', company: 'DEF')
            @user2.options = UserOptions.create(user_id: @user2.id, is_upload_authorized: true)
            @user2.organization = organization
            @user2.save

            AccountBookType.create(user_id: @user2.id, name: 'AC', description: '( Achat )')
            AccountBookType.create(user_id: @user2.id, name: 'BQ', description: '( Banque )')

            account_sharing = AccountSharing.new
            account_sharing.organization  = organization
            account_sharing.collaborator  = @user
            account_sharing.account       = @user2
            account_sharing.authorized_by = @user2
            account_sharing.save

            @dropbox.delta_cursor = 'AAFgTnd1fNzZHqDCFFgsiy9md7x1X-RNw65zxrs7Gzp-2dmjlVZfojFKxS8tgF6RDZxMaJkBKe2F2vhl16wD7DPQjLyw_leIG3AAjnAqMlnRiSe8AvSpLnyP4MSoyyF0npdIr512ikpwDQhm_SKR3dfTvwAHWvYzLSc7Rd-q1yEkKCnYGTBHveKsSX3v_3Zu_lciCvg39sxuXU2USvxo-CIe'
            @dropbox.save
          end

          it 'creates additionnal folders' do
            dropbox_import = FileImport::Dropbox.new(@dropbox)

            expect(dropbox_import.folders.size).to eq 8
            expect(dropbox_import.folders.select(&:exist?).size).to eq 4
            expect(dropbox_import.folders.select(&:to_be_destroyed?).size).to eq 0
            expect(dropbox_import.folders.select(&:to_be_created?).size).to eq 4

            VCR.use_cassette('dropbox_import/customer/creates_additionnal_folders') do
              dropbox_import.check
            end

            folder_paths = [
              '/exportation vers iDocus/TS%0001 - TeSt/période actuelle/AC',
              '/exportation vers iDocus/TS%0001 - TeSt/période actuelle/VT',
              '/exportation vers iDocus/TS%0001 - TeSt/période précédente/AC',
              '/exportation vers iDocus/TS%0001 - TeSt/période précédente/VT',
              '/exportation vers iDocus/TS%0002 - DEF/période actuelle/AC',
              '/exportation vers iDocus/TS%0002 - DEF/période actuelle/BQ',
              '/exportation vers iDocus/TS%0002 - DEF/période précédente/AC',
              '/exportation vers iDocus/TS%0002 - DEF/période précédente/BQ'
            ]

            # creates 4 folders
            4.times do |i|
              expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/create_folder').
                with(headers: @headers_2, body: { path: folder_paths[i+4] }.to_json)
            end

            # delta
            expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/continue').
              with(headers: @headers_2, body: /\{"cursor":".*"\}/)

            expect(WebMock).to have_requested(:any, /.*/).times(5)

            expect(@dropbox.checked_at).to be_present
            expect(@dropbox.delta_cursor).to be_present
            expect(@dropbox.delta_path_prefix).to eq('/exportation vers iDocus')
            expect(@dropbox.import_folder_paths).to eq(folder_paths)

            expect(dropbox_import.folders.size).to eq 8
            expect(dropbox_import.folders.select(&:exist?).size).to eq 8
          end
        end
      end

      context 'given import folder has been deleted' do
        before(:each) do
          @folder_paths = [
            '/exportation vers iDocus/TS%0001 - TeSt/période actuelle/AC',
            '/exportation vers iDocus/TS%0001 - TeSt/période actuelle/VT',
            '/exportation vers iDocus/TS%0001 - TeSt/période précédente/AC',
            '/exportation vers iDocus/TS%0001 - TeSt/période précédente/VT'
          ]
          @dropbox.import_folder_paths = @folder_paths
          @dropbox.delta_path_prefix = '/exportation vers iDocus'
          @dropbox.delta_cursor = @delta_cursor = 'AAHUih7TxHRIigL_ZKLMFw5fGycgJLtb7OYpbas4sDMVVp9FDcPNvwi5sPPtFpkKiQsqGGs3J8_prkoUE1kM7GlUrz-bTFCo1fnKSp_Z8SXnYKES5c9trusGZbLDHat8QhlWNzKZ1peRsYGeuWy0DgVnw2ZFnUdEMy2onfs_V-AxT931qcX9rxocbuVyGQfPx7NaJ1o65_piVVXnY-EHFSpZ-n0WGeTsMLdPiqLgKlH7jA'
          @dropbox.save
        end

        it 'recreates initial folders' do
          dropbox_import = FileImport::Dropbox.new(@dropbox)

          expect(dropbox_import.folders.size).to eq 4
          expect(dropbox_import.folders.select(&:exist?).size).to eq 4
          expect(dropbox_import.folders.select(&:to_be_destroyed?).size).to eq 0
          expect(dropbox_import.folders.select(&:to_be_created?).size).to eq 0

          VCR.use_cassette('dropbox_import/customer/recreates_initial_folders') do
            dropbox_import.check
          end

          # creates 4 folders
          4.times do |i|
            expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/create_folder').
              with(headers: @headers_2).with(body: { path: @folder_paths[i] })
          end
          # get latest cursor
          expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/get_latest_cursor').
            with(headers: @headers_2, body: '{"path":"/exportation vers iDocus","recursive":true,"include_media_info":false,"include_deleted":false}')
          # delta
          expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/continue').
            with(headers: @headers_2, body: /\{"cursor":".*"\}/).twice

          expect(WebMock).to have_requested(:any, /.*/).times(7)

          expect(@dropbox.checked_at).to be_present
          expect(@dropbox.delta_cursor).not_to eq(@delta_cursor)
          expect(@dropbox.delta_path_prefix).to eq('/exportation vers iDocus')
          expect(@dropbox.import_folder_paths).to eq(@folder_paths)

          expect(dropbox_import.folders.size).to eq 4
          expect(dropbox_import.folders.select(&:exist?).size).to eq 4
        end
      end
    end

    context 'as a collaborator' do
      before(:each) do
        DatabaseCleaner.start

        @organization = Organization.create(name: 'TEST', code: 'TS')

        @collaborator = FactoryBot.create(:user, is_prescriber: true)
        @collaborator.organization = @organization
        @collaborator.save
        @member = Member.create(user: @collaborator, organization: @organization, code: 'TS%COL1')

        @user = FactoryBot.create(:user, code: 'TS%0001', company: 'ABC')
        @user.options = UserOptions.create(user_id: @user.id, is_upload_authorized: true)
        @user.organization = @organization
        @user.save

        AccountBookType.create(user_id: @user.id, name: 'AC', description: '( Achat )')
        AccountBookType.create(user_id: @user.id, name: 'VT', description: '( Vente )')

        @user2 = FactoryBot.create(:user, code: 'TS%0002', company: 'DEF')
        @user2.options = UserOptions.create(user_id: @user2.id, is_upload_authorized: true)
        @user2.organization = @organization
        @user2.save

        AccountBookType.create(user_id: @user2.id, name: 'AC', description: '( Achat )')
        AccountBookType.create(user_id: @user2.id, name: 'BQ', description: '( Banque )')

        @group = Group.new
        @group.name = 'Customers'
        @group.organization = @organization
        @group.members << @member
        @group.customers << @user
        @group.customers << @user2
        @group.save

        efs = @collaborator.find_or_create_external_file_storage
        efs.use ExternalFileStorage::F_DROPBOX
        @dropbox = efs.dropbox_basic
        @dropbox.access_token = 'K4z7I_InsgsAAAAAAAAAkZ76RjGf_qZVQ6y72HOjmCJ1FWGFufHC9ZGbfuqO3fQO'
        @dropbox.save

        @collaborator.reload

        @headers = { 'Authorization' => 'Bearer K4z7I_InsgsAAAAAAAAAkZ76RjGf_qZVQ6y72HOjmCJ1FWGFufHC9ZGbfuqO3fQO' }
        @headers_2 = @headers.merge({ 'Content-Type' => 'application/json' })
      end

      after(:each) { DatabaseCleaner.clean }

      it 'creates initial folders' do
        dropbox_import = FileImport::Dropbox.new(@dropbox)

        expect(dropbox_import.folders.size).to eq 8
        expect(dropbox_import.folders.select(&:exist?).size).to eq 0
        expect(dropbox_import.folders.select(&:to_be_destroyed?).size).to eq 0
        expect(dropbox_import.folders.select(&:to_be_created?).size).to eq 8

        VCR.use_cassette('dropbox_import/collaborator/creates_initial_folders') do
          dropbox_import.check
        end

        folder_paths = [
          '/exportation vers iDocus/TS%COL1/TS%0001 - ABC/période actuelle/AC',
          '/exportation vers iDocus/TS%COL1/TS%0001 - ABC/période actuelle/VT',
          '/exportation vers iDocus/TS%COL1/TS%0001 - ABC/période précédente/AC',
          '/exportation vers iDocus/TS%COL1/TS%0001 - ABC/période précédente/VT',
          '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période actuelle/AC',
          '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période actuelle/BQ',
          '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période précédente/AC',
          '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période précédente/BQ'
        ]

        # creates 8 folders
        8.times do |i|
          expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/create_folder').
            with(headers: @headers_2, body: { path: folder_paths[i] }.to_json)
        end

        # get latest cursor
        expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/get_latest_cursor').
          with(headers: @headers_2, body: '{"path":"/exportation vers iDocus","recursive":true,"include_media_info":false,"include_deleted":false}')
        # delta
        expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/continue').
          with(headers: @headers_2, body: /\{"cursor":".*"\}/)

        expect(WebMock).to have_requested(:any, /.*/).times(10)

        expect(@dropbox.checked_at).to be_present
        expect(@dropbox.delta_cursor).to be_present
        expect(@dropbox.delta_path_prefix).to eq('/exportation vers iDocus')
        expect(@dropbox.import_folder_paths).to eq(folder_paths)

        expect(dropbox_import.folders.size).to eq 8
        expect(dropbox_import.folders.select(&:exist?).size).to eq 8
      end

      context 'given initial folders have been created' do
        before(:each) do
          @dropbox.delta_path_prefix = '/exportation vers iDocus'
          @dropbox.import_folder_paths = [
            '/exportation vers iDocus/TS%COL1/TS%0001 - ABC/période actuelle/AC',
            '/exportation vers iDocus/TS%COL1/TS%0001 - ABC/période actuelle/VT',
            '/exportation vers iDocus/TS%COL1/TS%0001 - ABC/période précédente/AC',
            '/exportation vers iDocus/TS%COL1/TS%0001 - ABC/période précédente/VT',
            '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période actuelle/AC',
            '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période actuelle/BQ',
            '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période précédente/AC',
            '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période précédente/BQ'
          ]
        end

        context 'given a valid file at : /exportation vers iDocus/TS%COL1/TS%0002 - DEF/période actuelle/AC/test.pdf' do
          it 'fetches one valid file' do
            delta_cursor = @dropbox.delta_cursor = 'AAEyDuOI9HBXyj046ZjbKf3IA_k3inM2E-46iIOpgyEBM-VHyxW8iqRClBPIV88Vg3bH2o1U_8Zfs6v6M235y8L05FJsshGX5HEos_jCIw0-j-rVWSS_34vzpchHSp-XQ-E3qiT8FZRHCIruKvdg0Ak76x8DqO7Jjjn0iMX8pOrMdC82sconT9ic4lcr3AZVG7g'
            @dropbox.save

            dropbox_import = FileImport::Dropbox.new(@dropbox)
            VCR.use_cassette('dropbox_import/collaborator/fetches_one_valid_file') do
              dropbox_import.check
            end

            # delta
            expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/continue').
              with(headers: @headers_2, body: /\{"cursor":".*"\}/)
            # get file
            expect(WebMock).to have_requested(:post, 'https://content.dropboxapi.com/2/files/download').
              with(headers: @headers.merge({ 'Dropbox-API-Arg' => { path: '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période actuelle/AC/2pages.pdf' }.to_json }))
            # delete file
            expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/delete').
              with(headers: @headers_2, body: { path: "/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période actuelle/AC/2pages.pdf" })

            expect(WebMock).to have_requested(:any, /.*/).times(3)

            temp_pack = TempPack.where(name: 'TS%0002 AC 201502 all').first
            temp_document = temp_pack.temp_documents.first
            fingerprint = `md5sum #{temp_document.cloud_content_object.path}`.split.first
            expect(temp_pack.temp_documents.count).to eq 1
            expect(temp_document.original_file_name).to eq '2pages.pdf'
            expect(fingerprint).to eq '97f90eac0d07fe5ade8f60a0fa54cdfc'

            expect(dropbox_import.folders.size).to eq 8
            expect(dropbox_import.folders.select(&:exist?).size).to eq 8
          end
        end

        context 'given an invalid file at : /exportation vers iDocus/TS%COL1/TS%0001 - ABC/période actuelle/AC/corrupted.pdf' do
          it 'marks one invalid file' do
            delta_cursor = @dropbox.delta_cursor = 'AAF9GxkuoAmiN04IfYJc0LTi_O3IZ1mUvZcthDSnFWxyFGRhLOJmJ05C4ECIcdcsu7dYu2TuTt2dHBCSuzxF0PbsH_BPJSkQwk6rhl9X4Gyhy1yU3iYB4IwYnrIApyfrIT2pDfndHfkM5NFclJtdrFo0PAW-NPA8QkL9bfTDg0NnSrsO5cz7le05QwnlU9GnRuA'
            @dropbox.save

            dropbox_import = FileImport::Dropbox.new(@dropbox)
            VCR.use_cassette('dropbox_import/collaborator/marks_one_invalid_file') do
              dropbox_import.check
            end

            # delta
            expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/continue').
              with(headers: @headers_2, body: /\{"cursor":".*"\}/)
            # get file
            expect(WebMock).to have_requested(:post, 'https://content.dropboxapi.com/2/files/download').
              with(headers: @headers.merge({ 'Dropbox-API-Arg' => { path: '/exportation vers iDocus/TS%COL1/TS%0001 - ABC/période actuelle/AC/corrupted.pdf' }.to_json }))
            # rename file
            expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/move').
              with(headers: @headers_2, body: { autorename: true, from_path: '/exportation vers iDocus/TS%COL1/TS%0001 - ABC/période actuelle/AC/corrupted.pdf', to_path: '/exportation vers iDocus/TS%COL1/TS%0001 - ABC/période actuelle/AC/corrupted (fichier corrompu ou protégé par mdp).pdf' })

            expect(WebMock).to have_requested(:any, /.*/).times(3)

            temp_pack = TempPack.where(name: 'TS%0001 AC 201502 all').first
            expect(temp_pack).to be_nil

            expect(dropbox_import.folders.size).to eq 8
            expect(dropbox_import.folders.select(&:exist?).size).to eq 8
          end
        end

        context 'given an invalid file already marked at : /exportation vers iDocus/TS%COL1/TS%0001 - ABC/période actuelle/AC/corrupted (erreur fichier non valide pour idocus).pdf' do
          it 'ignores one file marked invalid' do
            delta_cursor = @dropbox.delta_cursor = 'AAFTDWUnP8ka7Cpt-4trBdOEQkxIASVeteG7m5tUOyl1ZOc9fylBuDSt6T0NRREqYvKnfB_Z3j2ivkH_-Np7jZCHUOp1cbWaT0bzEdBoJm-iOEimXdJDaTj-fCDG5tmmjTlzoLzTrhXiQHZk0L0_bDGA4bPn45gyLc0tgu2WSu0JQP6C5liD-Mvfwi577rDqvMM'
            @dropbox.save

            dropbox_import = FileImport::Dropbox.new(@dropbox)
            VCR.use_cassette('dropbox_import/collaborator/ignores_one_file_marked_invalid') do
              dropbox_import.check
            end

            # delta
            expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/continue').
              with(headers: @headers_2, body: /\{"cursor":".*"\}/)

            expect(WebMock).to have_requested(:any, /.*/).once

            temp_pack = TempPack.where(name: 'TS%0001 AC 201502 all').first
            expect(temp_pack).to be_nil

            expect(dropbox_import.folders.size).to eq 8
            expect(dropbox_import.folders.select(&:exist?).size).to eq 8
          end
        end

        context 'given folder "/exportation vers iDocus/TS%COL1/TS%0002 - DEF" is removed' do
          it 'recreates deleted folders' do
            delta_cursor = @dropbox.delta_cursor = 'AAFcZuZzBdduW7iYkysvGdxtnmCGF3nZWpke_Aqu-DCtaUOWecO3TZnHgxZIOm4275s1qRuPvxqg6LH2bL9DTmzX3rqeXVjs4yF2LazsdPH8bTpgRRi-Ck5UQ0HwNqoMylbpNMDkaR-6PgTYdmpxLg-X8nX0NqWmXT3aCKpvm1Ksw7zwe1-b1gtLR_UpUcITt3A'
            @dropbox.save

            dropbox_import = FileImport::Dropbox.new(@dropbox)

            expect(dropbox_import.folders.size).to eq 8
            expect(dropbox_import.folders.select(&:exist?).size).to eq 8
            expect(dropbox_import.folders.select(&:to_be_destroyed?).size).to eq 0
            expect(dropbox_import.folders.select(&:to_be_created?).size).to eq 0

            VCR.use_cassette('dropbox_import/collaborator/recreates_deleted_folders') do
              dropbox_import.check
            end

            # delta
            expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/continue').
              with(headers: @headers_2, body: /\{"cursor":".*"\}/)
            # creates 4 folders
            [
              '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période actuelle/AC',
              '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période actuelle/BQ',
              '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période précédente/AC',
              '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période précédente/BQ'
            ].each do |path|
              expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/create_folder').
                with(headers: @headers_2, body: { path: path }.to_json)
            end

            expect(WebMock).to have_requested(:any, /.*/).times(5)

            expect(dropbox_import.folders.size).to eq 8
            expect(dropbox_import.folders.select(&:exist?).size).to eq 8
          end
        end

        context 'given folder at "/exportation vers iDocus/TS%COL1/TS%0001 - ABC" renamed or moved to "OLD"' do
          it 'recreates renamed or moved folders' do
            delta_cursor = @dropbox.delta_cursor = 'AAG_ogKz7lxdeqZB8WF--O7XtYVelJeGKFUiN9UkkHnX697GEdvXGaxmwaqFmhMnqzP9Jx7AWv4Cg3ruNJ-9nEk-8mK35HKSwUbOSQNgcK2gDneNcLpmjRK_nDsfm749S2egKVYwafSlK4Cvx0GQTMl070VtJkndF_a81AemNglH0RaO56OfdKS2pGIj3n3DqlY'
            @dropbox.save

            dropbox_import = FileImport::Dropbox.new(@dropbox)

            expect(dropbox_import.folders.size).to eq 8
            expect(dropbox_import.folders.select(&:exist?).size).to eq 8
            expect(dropbox_import.folders.select(&:to_be_destroyed?).size).to eq 0
            expect(dropbox_import.folders.select(&:to_be_created?).size).to eq 0

            VCR.use_cassette('dropbox_import/collaborator/recreates_renamed_or_moved_folders') do
              dropbox_import.check
            end

            # delta
            expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/continue').
              with(headers: @headers_2, body: /\{"cursor":".*"\}/)
            # creates 4 folders
            [
              '/exportation vers iDocus/TS%COL1/TS%0001 - ABC/période actuelle/AC',
              '/exportation vers iDocus/TS%COL1/TS%0001 - ABC/période actuelle/VT',
              '/exportation vers iDocus/TS%COL1/TS%0001 - ABC/période précédente/AC',
              '/exportation vers iDocus/TS%COL1/TS%0001 - ABC/période précédente/VT'
            ].each do |path|
              expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/create_folder').
                with(headers: @headers_2, body: { path: path })
            end

            expect(WebMock).to have_requested(:any, /.*/).times(5)

            expect(dropbox_import.folders.size).to eq 8
            expect(dropbox_import.folders.select(&:exist?).size).to eq 8
          end
        end

        context 'given journal VT is added to user TS%0002' do
          before(:each) { @journal = AccountBookType.create(user_id: @user2.id, name: 'VT', description: '( Vente )') }

          it 'creates 2 folders VT' do
            delta_cursor = @dropbox.delta_cursor = 'AAFjJ6WvOylY7N4L0rJnl3KaW4wFJyH5DKk_srAjRyRmRAFGnOBrUjoHeiBkinfGMatNz39lKyrSbtP418o0_CrfH7zjn_HFI-JeL4ELUQc1jg5EgS2g99qklBv3D1CIdUBR4LfP0tkvvuPxHc2PS30MCLp6n7uBFkXYNGJ3QTdZwZ4m7X1dYRy4-cB-I1Z96PA'
            @dropbox.save

            dropbox_import = FileImport::Dropbox.new(@dropbox)

            expect(dropbox_import.folders.size).to eq 10
            expect(dropbox_import.folders.select(&:exist?).size).to eq 8
            expect(dropbox_import.folders.select(&:to_be_destroyed?).size).to eq 0
            expect(dropbox_import.folders.select(&:to_be_created?).size).to eq 2

            VCR.use_cassette('dropbox_import/collaborator/creates_2_folders_vt') do
              dropbox_import.check
            end

            # delta
            expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/continue').
              with(headers: @headers_2, body: /\{"cursor":".*"\}/)
            # creates 2 folders
            [
              '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période actuelle/VT',
              '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période précédente/VT'
            ].each do |path|
              expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/create_folder').
                with(headers: @headers_2, body: { path: path })
            end

            expect(WebMock).to have_requested(:any, /.*/).times(3)

            expect(dropbox_import.folders.size).to eq 10
            expect(dropbox_import.folders.select(&:exist?).size).to eq 10
          end
        end

        context 'given journal BQ is renamed BQ1' do
          before(:each) { @user2.account_book_types.where(name: 'BQ').update_all(name: 'BQ1') }

          it 'deletes 2 folders BQ and creates 2 folders BQ1' do
            delta_cursor = @dropbox.delta_cursor = 'AAFJsqFCPcoQ0HjVpTdtPLbHn8LfAA1-NoXbgYD6h4o40pe3HonDZatq4EYxvSftLKSvW_9lJWldOVlvyAnc5l8eJHtji4dkpu96aCDe5HXQ2IdZLCrlqjLaZnYWZRW65zNXi7G1WTsIC7M0sBvrVwc6QMgSyIYtqhOXirQhr8feWPcJLzF9f0qNKD4fwjDIEk8'
            @dropbox.save

            dropbox_import = FileImport::Dropbox.new(@dropbox)

            expect(dropbox_import.folders.size).to eq 10
            expect(dropbox_import.folders.select(&:exist?).size).to eq 6
            expect(dropbox_import.folders.select(&:to_be_destroyed?).size).to eq 2
            expect(dropbox_import.folders.select(&:to_be_created?).size).to eq 2

            VCR.use_cassette('dropbox_import/collaborator/deletes_2_folders_bq_and_creates_2_folders_bq1') do
              dropbox_import.check
            end

            # delta
            expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/continue').
              with(headers: @headers_2, body: /\{"cursor":".*"\}/)
            # creates 2 folders
            [
              '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période actuelle/BQ1',
              '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période précédente/BQ1'
            ].each do |path|
              expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/create_folder').
                with(headers: @headers_2, body: { path: path })
            end
            # deletes 2 folders
            [
              '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période actuelle/BQ',
              '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période précédente/BQ'
            ].each do |path|
              expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/delete').
                with(headers: @headers_2, body: { path: path })
            end

            expect(WebMock).to have_requested(:any, /.*/).times(5)

            expect(dropbox_import.folders.size).to eq 8
            expect(dropbox_import.folders.select(&:exist?).size).to eq 8
          end
        end

        context 'given journal BQ1 was added' do
          before(:each) do
            @dropbox.import_folder_paths = [
              '/exportation vers iDocus/TS%COL1/TS%0001 - ABC/période actuelle/AC',
              '/exportation vers iDocus/TS%COL1/TS%0001 - ABC/période actuelle/VT',
              '/exportation vers iDocus/TS%COL1/TS%0001 - ABC/période précédente/AC',
              '/exportation vers iDocus/TS%COL1/TS%0001 - ABC/période précédente/VT',
              '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période actuelle/AC',
              '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période actuelle/BQ',
              '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période actuelle/BQ1',
              '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période précédente/AC',
              '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période précédente/BQ',
              '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période précédente/BQ1',
            ]
          end

          context 'given journal BQ and BQ1 are removed' do
            before(:each) { @user2.account_book_types.where(name: 'BQ').destroy_all }

            it 'deletes 2 folders BQ and deletes 2 folders BQ1' do
              delta_cursor = @dropbox.delta_cursor = 'AAGTNO3DBd4s5rlwhR5WCmvdBq8MXjqlXOP9Q6_2C05izwKABCiCppRv4lkygpPCXuAS93GQXw4mrGFjRygrINEA52Go9TRPMDm6KQxSEv3PFQeaRIlE_5825isqPCiJcjHlGXApmV0t0r7ML57BdoNTx3AgrZdkqsfDoYaFeq1WXB5YBSGOzDr2THa_Y-R5kVA'
              @dropbox.save

              dropbox_import = FileImport::Dropbox.new(@dropbox)

              expect(dropbox_import.folders.size).to eq 10
              expect(dropbox_import.folders.select(&:exist?).size).to eq 6
              expect(dropbox_import.folders.select(&:to_be_destroyed?).size).to eq 4
              expect(dropbox_import.folders.select(&:to_be_created?).size).to eq 0

              VCR.use_cassette('dropbox_import/collaborator/deletes_2_folders_bq_and_deletes_2_folders_bq1') do
                dropbox_import.check
              end

              # delta
              expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/continue').
                with(headers: @headers_2, body: /\{"cursor":".*"\}/)
              # deletes 4 folders
              [
                '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période actuelle/BQ',
                '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période actuelle/BQ1',
                '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période précédente/BQ',
                '/exportation vers iDocus/TS%COL1/TS%0002 - DEF/période précédente/BQ1'
              ].each do |path|
                expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/delete').
                  with(headers: @headers_2, body: { path: path })
              end

              expect(WebMock).to have_requested(:any, /.*/).times(5)

              expect(dropbox_import.folders.size).to eq 6
              expect(dropbox_import.folders.select(&:exist?).size).to eq 6
            end

            context 'given TS%0002 is removed from group' do
              before(:each) { @user2.groups.clear }

              it 'removes only the parent folder : TS%0002 - DEF' do
                delta_cursor = @dropbox.delta_cursor = 'AAHC7CsTflyuFB1g45PvjRZMPOPsGh8rMamMgEy1GRZstxGSSqMYS5qCIPP0KXlwGD_Kf9gzGAfQ_1T3gI94XbEArhqIe4FUuc8gXHVlZthXTx_GPsgUxXm3d7sNinwL1l67mmI7FQdCYOVHQEa1QKy-Z-yPfcQY-XJy98zm8-pHkLptzFMe9ry7t6mlQeIyVb0'
                @dropbox.save

                dropbox_import = FileImport::Dropbox.new(@dropbox)

                expect(dropbox_import.folders.size).to eq 10
                expect(dropbox_import.folders.select(&:exist?).size).to eq 4
                expect(dropbox_import.folders.select(&:to_be_destroyed?).size).to eq 6
                expect(dropbox_import.folders.select(&:to_be_created?).size).to eq 0

                VCR.use_cassette('dropbox_import/collaborator/removes_parent_folder_ts%0002_-_def') do
                  dropbox_import.check
                end

                # delta
                expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/continue').
                  with(headers: @headers_2, body: /\{"cursor":".*"\}/)
                # deletes parent folder TS%0002 - DEF
                expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/delete').
                    with(headers: @headers_2, body: { path: '/exportation vers iDocus/TS%COL1/TS%0002 - DEF' })

                expect(WebMock).to have_requested(:any, /.*/).times(2)

                expect(dropbox_import.folders.size).to eq 4
                expect(dropbox_import.folders.select(&:exist?).size).to eq 4
              end
            end
          end
        end

        context 'given journal VT is removed' do
          before(:each) do
            @user.account_book_types.where(name: 'VT').destroy_all
          end

          it 'deletes 2 folders VT' do
            delta_cursor = @dropbox.delta_cursor = 'AAEI0AZaAiixZGjvyPDkMasibXR8h_t4Ief4dV3Smr02lP7tJaoPnvvtZuhlQ1fsWe6vRGLspbCzac4IGLIjpFXxGob0gWurUcpF9CKIdMWtbc81DFnF6BH0ojNIcpqETtubQfM2eWDqqja9y0xLIuHkv1uzyMpg13XU-XkFUnUff3sAUWpGpHUqvn73CUNX-s4'
            @dropbox.save

            dropbox_import = FileImport::Dropbox.new(@dropbox)

            expect(dropbox_import.folders.size).to eq 8
            expect(dropbox_import.folders.select(&:exist?).size).to eq 6
            expect(dropbox_import.folders.select(&:to_be_destroyed?).size).to eq 2
            expect(dropbox_import.folders.select(&:to_be_created?).size).to eq 0

            VCR.use_cassette('dropbox_import/collaborator/deletes_2_folders_VT') do
              dropbox_import.check
            end

            # delta
            expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/continue').
              with(headers: @headers_2, body: /\{"cursor":".*"\}/)
            # deletes 2 folders
            [
              '/exportation vers iDocus/TS%COL1/TS%0001 - ABC/période actuelle/VT',
              '/exportation vers iDocus/TS%COL1/TS%0001 - ABC/période précédente/VT'
            ].each do |path|
              expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/delete').
                with(headers: @headers_2, body: { path: path })
            end

            expect(WebMock).to have_requested(:any, /.*/).times(3)

            expect(dropbox_import.folders.size).to eq 6
            expect(dropbox_import.folders.select(&:exist?).size).to eq 6
          end
        end

        context 'given TS%0001 is removed from group' do
          before(:each) { @user.groups.clear }

          it 'removes folder TS%0001 - ABC' do
            delta_cursor = @dropbox.delta_cursor = 'AAFsdMnyFBU1N5vwJaYhzXNWuMUB5ZcbLjNcc1lhALBC0Tm9aw9lbSEImzVChz7Gx0xp6XpWNg_P5yyWIbZYLvELanE0oNko5xHcxKD7f3Lb-NEUSbrF2dTgrj8gjzVhSS7gbBGbkDSiIrVVUy7ISNJGqJ6Ira_ml8oufdfwY91QT83n16hrJxgEuFI3NgcFouw'
            @dropbox.save

            dropbox_import = FileImport::Dropbox.new(@dropbox)

            expect(dropbox_import.folders.size).to eq 8
            expect(dropbox_import.folders.select(&:exist?).size).to eq 4
            expect(dropbox_import.folders.select(&:to_be_destroyed?).size).to eq 4
            expect(dropbox_import.folders.select(&:to_be_created?).size).to eq 0

            VCR.use_cassette('dropbox_import/collaborator/removes_folder_ts%0001_-_abc') do
              dropbox_import.check
            end

            # delta
            expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/continue').
              with(headers: @headers_2, body: /\{"cursor":".*"\}/)
            # deletes folder TS%0001 - ABC
            expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/delete').
                with(headers: @headers_2, body: { path: '/exportation vers iDocus/TS%COL1/TS%0001 - ABC' })

            expect(WebMock).to have_requested(:any, /.*/).times(2)

            expect(dropbox_import.folders.size).to eq 4
            expect(dropbox_import.folders.select(&:exist?).size).to eq 4
          end
        end

        context 'given TS%0003 is added' do
          before(:each) do
            @user3 = FactoryBot.create(:user, code: 'TS%0003', company: 'GHI')
            @user3.options = UserOptions.create(user_id: @user3.id, is_upload_authorized: true)
            @user3.organization = @organization
            @user3.save

            AccountBookType.create(user_id: @user3.id, name: 'AC', description: '( Achat )')
            AccountBookType.create(user_id: @user3.id, name: 'BQ', description: '( Banque )')

            @group.customers << @user3
            @group.save
          end

          it 'creates TS%0003\'s folders' do
            delta_cursor = @dropbox.delta_cursor = 'AAFRFvW7XcupKKpCyfkNYr3RasrZ5FhOQC31W21kUy7TIhi_BcarXCCDt2LXA9L6sx2DhcROm-qJtquyfiHRFnuDaQmHGVooa39BhxeGZYglo2Lh5zB_aT9yuyALXbulLdkGBQ2-NoKxVR-6J5CfKCISsw9lc71L_NVWnXTN5WIT2hu_bMTMgfKY5yWOi4D8FZg'
            @dropbox.save

            dropbox_import = FileImport::Dropbox.new(@dropbox)

            expect(dropbox_import.folders.size).to eq 12
            expect(dropbox_import.folders.select(&:exist?).size).to eq 8
            expect(dropbox_import.folders.select(&:to_be_destroyed?).size).to eq 0
            expect(dropbox_import.folders.select(&:to_be_created?).size).to eq 4

            VCR.use_cassette('dropbox_import/collaborator/creates_ts%0003s_folders') do
              dropbox_import.check
            end

            # delta
            expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/continue').
              with(headers: @headers_2, body: /\{"cursor":".*"\}/)
            # creates 4 folders
            [
              '/exportation vers iDocus/TS%COL1/TS%0003 - GHI/période actuelle/AC',
              '/exportation vers iDocus/TS%COL1/TS%0003 - GHI/période actuelle/BQ',
              '/exportation vers iDocus/TS%COL1/TS%0003 - GHI/période précédente/AC',
              '/exportation vers iDocus/TS%COL1/TS%0003 - GHI/période précédente/BQ'
            ].each do |path|
              expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/create_folder').
                with(headers: @headers_2, body: { path: path })
            end

            expect(WebMock).to have_requested(:any, /.*/).times(5)

            expect(dropbox_import.folders.size).to eq 12
            expect(dropbox_import.folders.select(&:exist?).size).to eq 12
          end
        end

        context 'given TS%0002 company is modified' do
          before(:each) { @user2.update(company: 'DDD') }

          it 'removes folder "TS%0002 - DEF" and creates folder "TS%0002 - DDD" and subfolders' do
            delta_cursor = @dropbox.delta_cursor = 'AAFPECINUoE4402PmO0Ta4IsLR_KP-_4AdabGI8OS23E3wGqHtixFRrhG5O-Iqmmdhd_9Opdsy83JfMbh1NTUN3rSe4M6D5v0xJ0xRh_Oox7B283OgMVSSNtcXLEFv4AFpAMRnWVQNnJTb1YW7GrwrrVdS9zXipcRQKpMOOIqEowov1n1tLOBXk9Di-tvGzfVyA'
            @dropbox.save

            dropbox_import = FileImport::Dropbox.new(@dropbox)

            expect(dropbox_import.folders.size).to eq 12
            expect(dropbox_import.folders.select(&:exist?).size).to eq 4
            expect(dropbox_import.folders.select(&:to_be_destroyed?).size).to eq 4
            expect(dropbox_import.folders.select(&:to_be_created?).size).to eq 4

            VCR.use_cassette('dropbox_import/collaborator/renames_folder_ts%0002_-_def') do
              dropbox_import.check
            end

            # delta
            expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/continue').
              with(headers: @headers_2, body: /\{"cursor":".*"\}/)
            # deletes folder '/exportation vers iDocus/TS%0002 - DEF'
            expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/delete').
              with(headers: @headers_2, body: { path: '/exportation vers iDocus/TS%COL1/TS%0002 - DEF' })
            # creates 4 folders
            [
              '/exportation vers iDocus/TS%COL1/TS%0002 - DDD/période actuelle/AC',
              '/exportation vers iDocus/TS%COL1/TS%0002 - DDD/période actuelle/BQ',
              '/exportation vers iDocus/TS%COL1/TS%0002 - DDD/période précédente/AC',
              '/exportation vers iDocus/TS%COL1/TS%0002 - DDD/période précédente/BQ'
            ].each do |path|
              expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/create_folder').
                with(headers: @headers_2, body: { path: path })
            end

            expect(WebMock).to have_requested(:any, /.*/).times(6)

            expect(dropbox_import.folders.size).to eq 8
            expect(dropbox_import.folders.select(&:exist?).size).to eq 8
          end
        end
      end
    end

    context 'as a contact' do
      before(:each) do
        DatabaseCleaner.start

        @organization = Organization.create(name: 'TEST', code: 'TS')

        @contact = FactoryBot.create(:user, is_guest: true, code: 'TS%SHR1')
        @contact.organization = @organization
        @contact.save

        @user = FactoryBot.create(:user, code: 'TS%0001', company: 'ABC')
        @user.options = UserOptions.create(user_id: @user.id, is_upload_authorized: true)
        @user.organization = @organization
        @user.save

        AccountBookType.create(user_id: @user.id, name: 'AC', description: '( Achat )')
        AccountBookType.create(user_id: @user.id, name: 'VT', description: '( Vente )')

        @user2 = FactoryBot.create(:user, code: 'TS%0002', company: 'DEF')
        @user2.options = UserOptions.create(user_id: @user2.id, is_upload_authorized: true)
        @user2.organization = @organization
        @user2.save

        AccountBookType.create(user_id: @user2.id, name: 'AC', description: '( Achat )')
        AccountBookType.create(user_id: @user2.id, name: 'BQ', description: '( Banque )')

        [@user, @user2].each do |user|
          account_sharing = AccountSharing.new
          account_sharing.organization  = @organization
          account_sharing.collaborator  = @contact
          account_sharing.account       = user
          account_sharing.authorized_by = user
          account_sharing.save
        end

        efs = @contact.find_or_create_external_file_storage
        efs.use ExternalFileStorage::F_DROPBOX
        @dropbox = efs.dropbox_basic
        @dropbox.access_token = 'K4z7I_InsgsAAAAAAAAAkZ76RjGf_qZVQ6y72HOjmCJ1FWGFufHC9ZGbfuqO3fQO'
        @dropbox.save

        @contact.reload

        @headers = { 'Authorization' => 'Bearer K4z7I_InsgsAAAAAAAAAkZ76RjGf_qZVQ6y72HOjmCJ1FWGFufHC9ZGbfuqO3fQO' }
        @headers_2 = @headers.merge({ 'Content-Type' => 'application/json' })
      end

      after(:each) { DatabaseCleaner.clean }

      it 'creates initial folders' do
        dropbox_import = FileImport::Dropbox.new(@dropbox)

        expect(dropbox_import.folders.size).to eq 8
        expect(dropbox_import.folders.select(&:exist?).size).to eq 0
        expect(dropbox_import.folders.select(&:to_be_destroyed?).size).to eq 0
        expect(dropbox_import.folders.select(&:to_be_created?).size).to eq 8

        VCR.use_cassette('dropbox_import/collaborator/creates_initial_folders') do
          dropbox_import.check
        end

        folder_paths = [
          '/exportation vers iDocus/TS%0001 - ABC/période actuelle/AC',
          '/exportation vers iDocus/TS%0001 - ABC/période actuelle/VT',
          '/exportation vers iDocus/TS%0001 - ABC/période précédente/AC',
          '/exportation vers iDocus/TS%0001 - ABC/période précédente/VT',
          '/exportation vers iDocus/TS%0002 - DEF/période actuelle/AC',
          '/exportation vers iDocus/TS%0002 - DEF/période actuelle/BQ',
          '/exportation vers iDocus/TS%0002 - DEF/période précédente/AC',
          '/exportation vers iDocus/TS%0002 - DEF/période précédente/BQ'
        ]

        # creates 8 folders
        8.times do |i|
          expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/create_folder').
            with(headers: @headers_2, body: { path: folder_paths[i] }.to_json)
        end

        # get latest cursor
        expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/get_latest_cursor').
          with(headers: @headers_2, body: '{"path":"/exportation vers iDocus","recursive":true,"include_media_info":false,"include_deleted":false}')
        # delta
        expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/continue').
          with(headers: @headers_2, body: /\{"cursor":".*"\}/)

        expect(WebMock).to have_requested(:any, /.*/).times(10)

        expect(@dropbox.checked_at).to be_present
        expect(@dropbox.delta_cursor).to be_present
        expect(@dropbox.delta_path_prefix).to eq('/exportation vers iDocus')
        expect(@dropbox.import_folder_paths).to eq(folder_paths)

        expect(dropbox_import.folders.size).to eq 8
        expect(dropbox_import.folders.select(&:exist?).size).to eq 8
      end
    end
  end
end
