# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe FileImport::Dropbox do
  before(:each) do
    Timecop.freeze(Time.local(2020,10,2))
  end

  after(:all) do
    Timecop.return
  end

  describe '#check' do
    context 'as a customer', :customer do
      before(:each) do
        DatabaseCleaner.start

        @user = FactoryBot.create(:user, code: 'IDOC%001')
        @user.options = UserOptions.create(user_id: @user.id, is_upload_authorized: true)
        @prescriber = create(:user, is_prescriber: true)
        @collaborator = Collaborator.new(@prescriber)
        @organization = Organization.create(name: 'IDOC TEST', code: 'IDO')
        @organization.customers << @user
        Member.create(user: @prescriber, organization: @organization, code: 'IDOC%002')

        AccountBookType.create(user_id: @user.id, name: 'AC', description: '( Achat )')
        AccountBookType.create(user_id: @user.id, name: 'VT', description: '( Vente )')

        efs = @user.find_or_create_external_file_storage
        efs.use ExternalFileStorage::F_DROPBOX
        @dropbox = efs.dropbox_basic
        @dropbox.access_token = 'd_8hw4XA240AAAAAAAAAAbdOcCNXL3qwaOp05judYxFkgJBjoRxIwBlDVCbOW3m2'
        @dropbox.save

        @user.reload

        @headers = { 'Authorization' => "Bearer #{@dropbox.access_token}" }
        @headers_2 = @headers.merge({ 'Content-Type' => 'application/json' })

        Settings.create(notify_errors_to: ['jean@idocus.com'])
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
          '/exportation vers iDocus/IDOC%001 - Test/période actuelle/AC',
          '/exportation vers iDocus/IDOC%001 - Test/période actuelle/VT',
          '/exportation vers iDocus/IDOC%001 - Test/période précédente/AC',
          '/exportation vers iDocus/IDOC%001 - Test/période précédente/VT'
        ]

        # creates 4 folders
        4.times do |i|
          expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/create_folder').
            with(headers: @headers_2, body: { path: folder_paths[i] })
        end
        # get latest cursor
        expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/get_latest_cursor').
          with(headers: @headers_2, body: '{"path":"/exportation vers iDocus","recursive":true,"include_media_info":false,"include_deleted":false}')
        # delta
        expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/continue').
          with(headers: @headers_2, body: /\{"cursor":".*"\}/)

        expect(WebMock).to have_requested(:any, /dropboxapi/).times(6)

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
            '/exportation vers iDocus/IDOC%001 - Test/période actuelle/AC',
            '/exportation vers iDocus/IDOC%001 - Test/période actuelle/VT',
            '/exportation vers iDocus/IDOC%001 - Test/période précédente/AC',
            '/exportation vers iDocus/IDOC%001 - Test/période précédente/VT'
          ]
          @dropbox.save
        end

        # NOTE: needs a better implementation of error
        it 'handles folder create failure' do
          delta_cursor = @dropbox.delta_cursor = 'AAGHorvqbn5732RU2CX9vD2vlIBHo--yqnTrT7aePCT0ioyAMfDOp02vn1FK1f3Duvun8QTCVTKnQ8jkWz674vsRGFWZmjfGL0ibYPHrKvsK8XNV4llsPt230EHl2vODBVk6ybGtcLxlT-fETh_bVF0YnueeM5MNyS54CMlJOxUUGjTMJTgKB9Xm47Vd-5siYlAa7qBIoGijEJyKaWFpfvktECxe5ePceh_JOYw_QSxu3OoEOf7QuS9KrZey1n5QNTE'
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
            '/exportation vers iDocus/IDOC%001 - Test/période actuelle/AC',
            '/exportation vers iDocus/IDOC%001 - Test/période actuelle/VT',
            '/exportation vers iDocus/IDOC%001 - Test/période précédente/AC',
            '/exportation vers iDocus/IDOC%001 - Test/période précédente/VT'
          ]

          # delta
          expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/continue').
            with(headers: @headers_2, body: /\{"cursor":".*"\}/)
          # fails to create 4 folders
          folder_paths.each do |path|
            expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/create_folder').
              with(headers: @headers_2, body: { path: path })
          end
          expect(WebMock).to have_requested(:any, /dropboxapi/).times(5)

          expect(@dropbox.import_folder_paths).to eq(folder_paths)
          expect(dropbox_import.folders.size).to eq 4
          expect(dropbox_import.folders.select(&:exist?).size).to eq 4
        end

        context 'given a valid file at : /exportation vers iDocus/IDOC%001 - Test/période actuelle/AC/test.pdf' do
          it 'fetches one valid file' do
            delta_cursor = @dropbox.delta_cursor = 'AAGHorvqbn5732RU2CX9vD2vlIBHo--yqnTrT7aePCT0ioyAMfDOp02vn1FK1f3Duvun8QTCVTKnQ8jkWz674vsRGFWZmjfGL0ibYPHrKvsK8XNV4llsPt230EHl2vODBVk6ybGtcLxlT-fETh_bVF0YnueeM5MNyS54CMlJOxUUGjTMJTgKB9Xm47Vd-5siYlAa7qBIoGijEJyKaWFpfvktECxe5ePceh_JOYw_QSxu3OoEOf7QuS9KrZey1n5QNTE'
            @dropbox.save

            dropbox_import = FileImport::Dropbox.new(@dropbox)
            VCR.use_cassette('dropbox_import/customer/fetches_one_valid_file') do
              dropbox_import.check
            end

            # delta
            expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/continue')
            # get file
            expect(WebMock).to have_requested(:post, 'https://content.dropboxapi.com/2/files/download')
            # delete file

            expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/delete')

            expect(WebMock).to have_requested(:any, /dropboxapi/).times(3)

            temp_pack = TempPack.where(name: 'IDOC%001 AC 202010 all').first
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
          delta_cursor = @dropbox.delta_cursor = 'AAGHorvqbn5732RU2CX9vD2vlIBHo--yqnTrT7aePCT0ioyAMfDOp02vn1FK1f3Duvun8QTCVTKnQ8jkWz674vsRGFWZmjfGL0ibYPHrKvsK8XNV4llsPt230EHl2vODBVk6ybGtcLxlT-fETh_bVF0YnueeM5MNyS54CMlJOxUUGjTMJTgKB9Xm47Vd-5siYlAa7qBIoGijEJyKaWFpfvktECxe5ePceh_JOYw_QSxu3OoEOf7QuS9KrZey1n5QNTE'
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
            with(headers: @headers.merge({ 'Dropbox-API-Arg' => { path: '/exportation vers iDocus/IDOC%001 - Test/période actuelle/AC/test.pdf' }.to_json }))
          # delete file
          expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/delete').
            with(headers: @headers_2, body: { path: "/exportation vers iDocus/IDOC%001 - Test/période actuelle/AC/test.pdf" })

          expect(WebMock).to have_requested(:any, /dropboxapi/).times(3)

          temp_pack = TempPack.where(name: 'IDOC%001 AC 202010 all').first
          temp_document = temp_pack.temp_documents.first
          fingerprint = `md5sum #{temp_document.cloud_content_object.path}`.split.first
          expect(temp_pack.temp_documents.count).to eq 1
          expect(temp_document.original_file_name).to eq 'test.pdf'
          expect(fingerprint).to eq '97f90eac0d07fe5ade8f60a0fa54cdfc'
          expect(dropbox_import.folders.map(&:exist?).uniq).to eq [true]
        end

        context 'given an invalid file at : /exportation vers iDocus/IDOC%001 - Test/période actuelle/AC/corrupted.pdf' do
          it 'marks one invalid file' do
            delta_cursor = @dropbox.delta_cursor = 'AAGHorvqbn5732RU2CX9vD2vlIBHo--yqnTrT7aePCT0ioyAMfDOp02vn1FK1f3Duvun8QTCVTKnQ8jkWz674vsRGFWZmjfGL0ibYPHrKvsK8XNV4llsPt230EHl2vODBVk6ybGtcLxlT-fETh_bVF0YnueeM5MNyS54CMlJOxUUGjTMJTgKB9Xm47Vd-5siYlAa7qBIoGijEJyKaWFpfvktECxe5ePceh_JOYw_QSxu3OoEOf7QuS9KrZey1n5QNTE'
            @dropbox.save

            dropbox_import = FileImport::Dropbox.new(@dropbox)
            VCR.use_cassette('dropbox_import/customer/marks_one_invalid_file') do
              dropbox_import.check
            end

            # delta
            expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/continue')
            # get file
            expect(WebMock).to have_requested(:post, 'https://content.dropboxapi.com/2/files/download')
            # rename file
            expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/move')

            expect(WebMock).to have_requested(:any, /dropboxapi/).times(3)

            expect(dropbox_import.folders.map(&:exist?).uniq).to eq [true]

            temp_pack = TempPack.where(name: 'IDOC%001 AC 202010 all').first
            expect(temp_pack).to be_nil
          end
        end

        context 'given an invalid file already marked at : /exportation vers iDocus/IDOC%001 - Test/période actuelle/AC/corrupted (erreur fichier non valide pour idocus).pdf' do
          it 'ignores one file marked invalid' do
            delta_cursor = @dropbox.delta_cursor = 'AAGHorvqbn5732RU2CX9vD2vlIBHo--yqnTrT7aePCT0ioyAMfDOp02vn1FK1f3Duvun8QTCVTKnQ8jkWz674vsRGFWZmjfGL0ibYPHrKvsK8XNV4llsPt230EHl2vODBVk6ybGtcLxlT-fETh_bVF0YnueeM5MNyS54CMlJOxUUGjTMJTgKB9Xm47Vd-5siYlAa7qBIoGijEJyKaWFpfvktECxe5ePceh_JOYw_QSxu3OoEOf7QuS9KrZey1n5QNTE'
            @dropbox.save

            dropbox_import = FileImport::Dropbox.new(@dropbox)
            VCR.use_cassette('dropbox_import/customer/ignores_one_file_marked_invalid') do
              dropbox_import.check
            end

            # delta
            expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/continue')

            expect(WebMock).to have_requested(:any, /dropboxapi/).once

            expect(dropbox_import.folders.map(&:exist?).uniq).to eq [true]

            temp_pack = TempPack.where(name: 'IDOC%001 AC 202010 all').first
            expect(temp_pack).to be_nil
          end

          context 'given another invalid file with the same name at : /exportation vers iDocus/IDOC%001 - Test/période actuelle/AC/corrupted.pdf' do
            it 'marks the file as invalid but with number : corrupted (fichier corrompu ou protégé par mdp) (1).pdf' do
              delta_cursor = @dropbox.delta_cursor = 'AAGHorvqbn5732RU2CX9vD2vlIBHo--yqnTrT7aePCT0ioyAMfDOp02vn1FK1f3Duvun8QTCVTKnQ8jkWz674vsRGFWZmjfGL0ibYPHrKvsK8XNV4llsPt230EHl2vODBVk6ybGtcLxlT-fETh_bVF0YnueeM5MNyS54CMlJOxUUGjTMJTgKB9Xm47Vd-5siYlAa7qBIoGijEJyKaWFpfvktECxe5ePceh_JOYw_QSxu3OoEOf7QuS9KrZey1n5QNTE'
              @dropbox.save

              dropbox_import = FileImport::Dropbox.new(@dropbox)
              VCR.use_cassette('dropbox_import/customer/rename_automatically_the_same_invalid_file') do
                dropbox_import.check
              end

              # delta
              expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/continue')
              # get file
              expect(WebMock).to have_requested(:post, 'https://content.dropboxapi.com/2/files/download')
              # rename file
              expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/move')

              expect(WebMock).to have_requested(:any, /dropboxapi/).times(3)

              expect(dropbox_import.folders.map(&:exist?).uniq).to eq [true]

              temp_pack = TempPack.where(name: 'IDOC%001 AC 202010 all').first
              expect(temp_pack).to be_nil
            end
          end
        end

        context 'given a file already exist' do
          before(:each) do
            @temp_pack = TempPack.find_or_create_by_name 'IDOC%001 AC 202010 all'
            @temp_pack.user = @user
            @temp_pack.save

            temp_document = TempDocument.new
            temp_document.user                = @user
            temp_document.organization        = @organization
            temp_document.position            = 1
            temp_document.temp_pack           = @temp_pack
            temp_document.original_file_name  = '2pages.pdf'
            temp_document.delivered_by        = @user.code
            temp_document.delivery_type       = 'upload'
            file_path = File.join(Rails.root, 'spec/support/files/2pages.pdf')
            temp_document.cloud_content.attach(io: File.open(file_path), filename: File.basename(file_path)) if temp_document.save
          end

          it 'marks one file as already exist' do
            allow_any_instance_of(UploadedDocument).to receive(:unique?).and_return(false)

            delta_cursor = @dropbox.delta_cursor = 'AAGHorvqbn5732RU2CX9vD2vlIBHo--yqnTrT7aePCT0ioyAMfDOp02vn1FK1f3Duvun8QTCVTKnQ8jkWz674vsRGFWZmjfGL0ibYPHrKvsK8XNV4llsPt230EHl2vODBVk6ybGtcLxlT-fETh_bVF0YnueeM5MNyS54CMlJOxUUGjTMJTgKB9Xm47Vd-5siYlAa7qBIoGijEJyKaWFpfvktECxe5ePceh_JOYw_QSxu3OoEOf7QuS9KrZey1n5QNTE'
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
              with(headers: @headers.merge({ 'Dropbox-API-Arg' => { path: '/exportation vers iDocus/IDOC%001 - Test/période actuelle/AC/2pages.pdf' }.to_json }))
            # rename file
            expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/move').
              with(headers: @headers_2, body: { autorename: true, from_path: '/exportation vers iDocus/IDOC%001 - Test/période actuelle/AC/2pages.pdf', to_path: '/exportation vers iDocus/IDOC%001 - Test/période actuelle/AC/2pages (fichier déjà importé sur iDocus).pdf' })

            expect(WebMock).to have_requested(:any, /dropboxapi/).times(3)

            expect(dropbox_import.folders.map(&:exist?).uniq).to eq [true]

            expect(@temp_pack.temp_documents.count).to eq 1
          end
        end

        context 'the number of elements exceeds one page' do
          it 'queries multiple times' do
            delta_cursor = @dropbox.delta_cursor = 'AAGHorvqbn5732RU2CX9vD2vlIBHo--yqnTrT7aePCT0ioyAMfDOp02vn1FK1f3Duvun8QTCVTKnQ8jkWz674vsRGFWZmjfGL0ibYPHrKvsK8XNV4llsPt230EHl2vODBVk6ybGtcLxlT-fETh_bVF0YnueeM5MNyS54CMlJOxUUGjTMJTgKB9Xm47Vd-5siYlAa7qBIoGijEJyKaWFpfvktECxe5ePceh_JOYw_QSxu3OoEOf7QuS9KrZey1n5QNTE'
            @dropbox.save

            VCR.use_cassette('dropbox_import/customer/queries_list_folder_continue_multiple_times') do
              FileImport::Dropbox.new(@dropbox).check
            end

            expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/continue').
              with(headers: @headers_2, body: { cursor: delta_cursor })
            # expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/continue').
            #   with(headers: @headers_2, body: { cursor: 'AAFMxB16PCTlIIMB7-YQ0lef5ZMPYf5AdL_BuVAEWnaEYxyMl4QOUOMZeo09FmTsnw9N69LW0reEqPCxGDMlvRKkC-3LjZI-FLrInuAL_BmVQ59HKIWSG8HNHd9gpHuodrkT8ocFy1ZrCNKv33gjmQz-6GQ3dZzZKQTwAa_UvgCq1Apd8ilPmuhiWGpU5peXAQg' })

            expect(WebMock).to have_requested(:any, /dropboxapi/).times(1)

            #expect(@dropbox.delta_cursor).to eq 'AAFeVq99ipMnuvVTcNS7_M5vHAmtvDE0RvvT9kPOvQVHOv5VDUaP1evskfuIC9BEO2PBGW-7c5T_3wwgyzKdww0nspvUWz6LI8G-myyUojkVp_TvYb-PJ5LfKf9ioItpz9wMPeQupbowctZAVBrtFsqqFoUZrDXw5SrrDhvpg3g4GzHVlAGVMdl4U7ZACSV3eUM'
          end
        end

        context 'given a file marked as already exist' do
          it 'ignores one file marked as already exist' do
            delta_cursor = @dropbox.delta_cursor = 'AAGHorvqbn5732RU2CX9vD2vlIBHo--yqnTrT7aePCT0ioyAMfDOp02vn1FK1f3Duvun8QTCVTKnQ8jkWz674vsRGFWZmjfGL0ibYPHrKvsK8XNV4llsPt230EHl2vODBVk6ybGtcLxlT-fETh_bVF0YnueeM5MNyS54CMlJOxUUGjTMJTgKB9Xm47Vd-5siYlAa7qBIoGijEJyKaWFpfvktECxe5ePceh_JOYw_QSxu3OoEOf7QuS9KrZey1n5QNTE'
            @dropbox.save

            dropbox_import = FileImport::Dropbox.new(@dropbox)
            VCR.use_cassette('dropbox_import/customer/ignores_one_file_marked_as_already_exist') do
              dropbox_import.check
            end

            # delta
            expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/continue')

            expect(WebMock).to have_requested(:any, /dropboxapi/).once

            expect(dropbox_import.folders.map(&:exist?).uniq).to eq [true]

            temp_pack = TempPack.where(name: 'IDOC%001 AC 202010 all').first
            expect(temp_pack).to be_nil
          end
        end

        context 'given folder "/exportation vers iDocus/IDOC%001 - Test/période précédente" is removed' do
          it 'recreates deleted folders' do
            delta_cursor = @dropbox.delta_cursor = 'AAGHorvqbn5732RU2CX9vD2vlIBHo--yqnTrT7aePCT0ioyAMfDOp02vn1FK1f3Duvun8QTCVTKnQ8jkWz674vsRGFWZmjfGL0ibYPHrKvsK8XNV4llsPt230EHl2vODBVk6ybGtcLxlT-fETh_bVF0YnueeM5MNyS54CMlJOxUUGjTMJTgKB9Xm47Vd-5siYlAa7qBIoGijEJyKaWFpfvktECxe5ePceh_JOYw_QSxu3OoEOf7QuS9KrZey1n5QNTE'
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
              '/exportation vers iDocus/IDOC%001 - Test/période précédente/AC',
              '/exportation vers iDocus/IDOC%001 - Test/période précédente/VT'
            ].each do |path|
              expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/create_folder').
                with(headers: @headers_2, body: { path: path })
            end

            expect(WebMock).to have_requested(:any, /dropboxapi/).times(3)

            expect(dropbox_import.folders.map(&:exist?).uniq).to eq [true]
          end
        end

        context 'given folder at "/exportation vers iDocus/IDOC%001 - Test/période actuelle" renamed or moved to "PERIODE"' do
          it 'recreates renamed or moved folders' do
            delta_cursor = @dropbox.delta_cursor = 'AAGHorvqbn5732RU2CX9vD2vlIBHo--yqnTrT7aePCT0ioyAMfDOp02vn1FK1f3Duvun8QTCVTKnQ8jkWz674vsRGFWZmjfGL0ibYPHrKvsK8XNV4llsPt230EHl2vODBVk6ybGtcLxlT-fETh_bVF0YnueeM5MNyS54CMlJOxUUGjTMJTgKB9Xm47Vd-5siYlAa7qBIoGijEJyKaWFpfvktECxe5ePceh_JOYw_QSxu3OoEOf7QuS9KrZey1n5QNTE'
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
              '/exportation vers iDocus/IDOC%001 - Test/période actuelle/AC',
              '/exportation vers iDocus/IDOC%001 - Test/période actuelle/VT'
            ].each do |path|
              expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/create_folder').
                with(headers: @headers_2, body: { path: path })
            end

            expect(WebMock).to have_requested(:any, /dropboxapi/).times(3)

            expect(dropbox_import.folders.map(&:exist?).uniq).to eq [true]
          end
        end

        context 'given journal BQ is added' do
          before(:each) { @journal = AccountBookType.create(user_id: @user.id, name: 'BQ', description: '( Banque )') }

          it 'creates 2 folders BQ' do
            delta_cursor = @dropbox.delta_cursor = 'AAGHorvqbn5732RU2CX9vD2vlIBHo--yqnTrT7aePCT0ioyAMfDOp02vn1FK1f3Duvun8QTCVTKnQ8jkWz674vsRGFWZmjfGL0ibYPHrKvsK8XNV4llsPt230EHl2vODBVk6ybGtcLxlT-fETh_bVF0YnueeM5MNyS54CMlJOxUUGjTMJTgKB9Xm47Vd-5siYlAa7qBIoGijEJyKaWFpfvktECxe5ePceh_JOYw_QSxu3OoEOf7QuS9KrZey1n5QNTE'
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
              '/exportation vers iDocus/IDOC%001 - Test/période actuelle/BQ',
              '/exportation vers iDocus/IDOC%001 - Test/période précédente/BQ'
            ].each do |path|
              expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/create_folder').
                with(headers: @headers_2, body: { path: path })
            end

            expect(WebMock).to have_requested(:any, /dropboxapi/).times(3)

            expect(dropbox_import.folders.select(&:exist?).size).to eq 6
            expect(dropbox_import.folders.map(&:exist?).uniq).to eq [true]
          end

          context 'and then renamed to BQ1' do
            before(:each) { @journal.update(name: 'BQ1') }

            it 'deletes 2 folders BQ and creates 2 folders BQ1' do
              delta_cursor = @dropbox.delta_cursor = 'AAGHorvqbn5732RU2CX9vD2vlIBHo--yqnTrT7aePCT0ioyAMfDOp02vn1FK1f3Duvun8QTCVTKnQ8jkWz674vsRGFWZmjfGL0ibYPHrKvsK8XNV4llsPt230EHl2vODBVk6ybGtcLxlT-fETh_bVF0YnueeM5MNyS54CMlJOxUUGjTMJTgKB9Xm47Vd-5siYlAa7qBIoGijEJyKaWFpfvktECxe5ePceh_JOYw_QSxu3OoEOf7QuS9KrZey1n5QNTE'
              @dropbox.import_folder_paths = [
                '/exportation vers iDocus/IDOC%001 - Test/période actuelle/AC',
                '/exportation vers iDocus/IDOC%001 - Test/période actuelle/VT',
                '/exportation vers iDocus/IDOC%001 - Test/période actuelle/BQ',
                '/exportation vers iDocus/IDOC%001 - Test/période précédente/AC',
                '/exportation vers iDocus/IDOC%001 - Test/période précédente/VT',
                '/exportation vers iDocus/IDOC%001 - Test/période précédente/BQ'
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
                '/exportation vers iDocus/IDOC%001 - Test/période actuelle/BQ1',
                '/exportation vers iDocus/IDOC%001 - Test/période précédente/BQ1'
              ].each do |path|
                expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/create_folder').
                  with(headers: @headers_2, body: { path: path })
              end
              # deletes 2 folders
              [
                '/exportation vers iDocus/IDOC%001 - Test/période actuelle/BQ',
                '/exportation vers iDocus/IDOC%001 - Test/période précédente/BQ'
              ].each do |path|
                expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/delete').
                  with(headers: @headers_2, body: { path: path })
              end

              expect(WebMock).to have_requested(:any, /dropboxapi/).times(5)

              expect(dropbox_import.folders.size).to eq 6
              expect(dropbox_import.folders.select(&:exist?).size).to eq 6
            end
          end
        end

        context 'given journal VT is removed' do
          before(:each) { @user.account_book_types.where(name: 'VT').first.destroy }

          it 'deletes 2 folders VT' do
            delta_cursor = @dropbox.delta_cursor = 'AAGHorvqbn5732RU2CX9vD2vlIBHo--yqnTrT7aePCT0ioyAMfDOp02vn1FK1f3Duvun8QTCVTKnQ8jkWz674vsRGFWZmjfGL0ibYPHrKvsK8XNV4llsPt230EHl2vODBVk6ybGtcLxlT-fETh_bVF0YnueeM5MNyS54CMlJOxUUGjTMJTgKB9Xm47Vd-5siYlAa7qBIoGijEJyKaWFpfvktECxe5ePceh_JOYw_QSxu3OoEOf7QuS9KrZey1n5QNTE'
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
              '/exportation vers iDocus/IDOC%001 - Test/période actuelle/VT',
              '/exportation vers iDocus/IDOC%001 - Test/période précédente/VT'
            ].each do |path|
              expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/delete').
                with(headers: @headers_2, body: { path: path })
            end

            expect(WebMock).to have_requested(:any, /dropboxapi/).times(3)

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
                    delta_cursor = @dropbox.delta_cursor = 'AAGHorvqbn5732RU2CX9vD2vlIBHo--yqnTrT7aePCT0ioyAMfDOp02vn1FK1f3Duvun8QTCVTKnQ8jkWz674vsRGFWZmjfGL0ibYPHrKvsK8XNV4llsPt230EHl2vODBVk6ybGtcLxlT-fETh_bVF0YnueeM5MNyS54CMlJOxUUGjTMJTgKB9Xm47Vd-5siYlAa7qBIoGijEJyKaWFpfvktECxe5ePceh_JOYw_QSxu3OoEOf7QuS9KrZey1n5QNTE'
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
                      with(headers: @headers.merge({ 'Dropbox-API-Arg' => { path: '/exportation vers iDocus/IDOC%001 - Test/période actuelle/VT/corrupted.pdf' }.to_json }))
                    # mark corrupted file as invalid
                    expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/move').
                      with(headers: @headers_2, body: { autorename: true, from_path: '/exportation vers iDocus/IDOC%001 - Test/période actuelle/VT/corrupted.pdf', to_path: '/exportation vers iDocus/IDOC%001 - Test/période actuelle/VT/corrupted (fichier corrompu ou protégé par mdp).pdf' })
                    # get file
                    expect(WebMock).to have_requested(:post, 'https://content.dropboxapi.com/2/files/download').
                      with(headers: @headers.merge({ 'Dropbox-API-Arg' => { path: '/exportation vers iDocus/IDOC%001 - Test/période actuelle/VT/2pages.pdf' }.to_json }))
                    # delete file
                    expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/delete').
                      with(headers: @headers_2, body: { path: '/exportation vers iDocus/IDOC%001 - Test/période actuelle/VT/2pages.pdf' })
                    # remove journal AC from folder période actuelle
                    expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/delete').
                      with(headers: @headers_2, body: { path: '/exportation vers iDocus/IDOC%001 - Test/période actuelle/AC' })

                    # creates 3 folders
                    [
                      '/exportation vers iDocus/IDOC%001 - Test/période actuelle/OD',
                      '/exportation vers iDocus/IDOC%001 - Test/période précédente/OD',
                      '/exportation vers iDocus/IDOC%001 - Test/période précédente/VT'
                    ].each do |path|
                      expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/create_folder').
                        with(headers: @headers_2, body: { path: path })
                    end

                    expect(WebMock).to have_requested(:any, /dropboxapi/).times(9)

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
            organization = Organization.create(name: 'TEST', code: 'IDOC')
            organization.customers << @user
            @user2 = FactoryBot.create(:user, code: 'IDOC%003', company: 'DEF')
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

            @dropbox.delta_cursor = 'AAGHorvqbn5732RU2CX9vD2vlIBHo--yqnTrT7aePCT0ioyAMfDOp02vn1FK1f3Duvun8QTCVTKnQ8jkWz674vsRGFWZmjfGL0ibYPHrKvsK8XNV4llsPt230EHl2vODBVk6ybGtcLxlT-fETh_bVF0YnueeM5MNyS54CMlJOxUUGjTMJTgKB9Xm47Vd-5siYlAa7qBIoGijEJyKaWFpfvktECxe5ePceh_JOYw_QSxu3OoEOf7QuS9KrZey1n5QNTE'
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
              '/exportation vers iDocus/IDOC%001 - Test/période actuelle/AC',
              '/exportation vers iDocus/IDOC%001 - Test/période actuelle/VT',
              '/exportation vers iDocus/IDOC%001 - Test/période précédente/AC',
              '/exportation vers iDocus/IDOC%001 - Test/période précédente/VT',
              '/exportation vers iDocus/IDOC%003 - DEF/période actuelle/AC',
              '/exportation vers iDocus/IDOC%003 - DEF/période actuelle/BQ',
              '/exportation vers iDocus/IDOC%003 - DEF/période précédente/AC',
              '/exportation vers iDocus/IDOC%003 - DEF/période précédente/BQ'
            ]

            # creates 4 folders
            4.times do |i|
              expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/create_folder').
                with(headers: @headers_2, body: { path: folder_paths[i + 4] }.to_json)
            end

            # delta
            expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/continue').
              with(headers: @headers_2, body: /\{"cursor":".*"\}/)

            expect(WebMock).to have_requested(:any, /dropboxapi/).times(5)

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
            '/exportation vers iDocus/IDOC%001 - Test/période actuelle/AC',
            '/exportation vers iDocus/IDOC%001 - Test/période actuelle/VT',
            '/exportation vers iDocus/IDOC%001 - Test/période précédente/AC',
            '/exportation vers iDocus/IDOC%001 - Test/période précédente/VT'
          ]
          @dropbox.import_folder_paths = @folder_paths
          @dropbox.delta_path_prefix = '/exportation vers iDocus'
          @dropbox.delta_cursor = @delta_cursor = 'AAGHorvqbn5732RU2CX9vD2vlIBHo--yqnTrT7aePCT0ioyAMfDOp02vn1FK1f3Duvun8QTCVTKnQ8jkWz674vsRGFWZmjfGL0ibYPHrKvsK8XNV4llsPt230EHl2vODBVk6ybGtcLxlT-fETh_bVF0YnueeM5MNyS54CMlJOxUUGjTMJTgKB9Xm47Vd-5siYlAa7qBIoGijEJyKaWFpfvktECxe5ePceh_JOYw_QSxu3OoEOf7QuS9KrZey1n5QNTE'
          @dropbox.save
        end

        it 'recreates initial folders', :review_after do
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
          # expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/get_latest_cursor').
          #   with(headers: @headers_2, body: '{"path":"/exportation vers iDocus","recursive":true,"include_media_info":false,"include_deleted":false, "include_has_explicit_shared_members": false}')
          # delta
          # expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/continue').
          #   with(headers: @headers_2, body: /\{"cursor":".*"\}/).twice

          # expect(WebMock).to have_requested(:any, /dropboxapi/).times(7)

          expect(@dropbox.checked_at).to be_present
          expect(@dropbox.delta_cursor).not_to eq(@delta_cursor)
          expect(@dropbox.delta_path_prefix).to eq('/exportation vers iDocus')
          expect(@dropbox.import_folder_paths).to eq(@folder_paths)

          expect(dropbox_import.folders.size).to eq 4
          expect(dropbox_import.folders.select(&:exist?).size).to eq 4
        end
      end
    end

    context 'as a collaborator', :collaborator do
      before(:each) do
        DatabaseCleaner.start

        @organization = Organization.create(name: 'TEST', code: 'IDOC')

        @collaborator = FactoryBot.create(:user, is_prescriber: true)
        @collaborator.organization = @organization
        @collaborator.save
        @member = Member.create(user: @collaborator, organization: @organization, code: 'IDOC%COL1')

        @user = FactoryBot.create(:user, code: 'IDOC%001', company: 'ABC')
        @user.options = UserOptions.create(user_id: @user.id, is_upload_authorized: true)
        @user.organization = @organization
        @user.save

        AccountBookType.create(user_id: @user.id, name: 'AC', description: '( Achat )')
        AccountBookType.create(user_id: @user.id, name: 'VT', description: '( Vente )')

        @user2 = FactoryBot.create(:user, code: 'IDOC%002', company: 'DEF')
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
        @dropbox.access_token = 'd_8hw4XA240AAAAAAAAAAbdOcCNXL3qwaOp05judYxFkgJBjoRxIwBlDVCbOW3m2'
        @dropbox.save

        @collaborator.reload

        @headers = { 'Authorization' => 'Bearer d_8hw4XA240AAAAAAAAAAbdOcCNXL3qwaOp05judYxFkgJBjoRxIwBlDVCbOW3m2' }
        @headers_2 = @headers.merge({ 'Content-Type' => 'application/json' })

        Settings.create(notify_errors_to: ['jean@idocus.com'])
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
          '/exportation vers iDocus/IDOC%COL1/IDOC%001 - ABC/période actuelle/AC',
          '/exportation vers iDocus/IDOC%COL1/IDOC%001 - ABC/période actuelle/VT',
          '/exportation vers iDocus/IDOC%COL1/IDOC%001 - ABC/période précédente/AC',
          '/exportation vers iDocus/IDOC%COL1/IDOC%001 - ABC/période précédente/VT',
          '/exportation vers iDocus/IDOC%COL1/IDOC%002 - DEF/période actuelle/AC',
          '/exportation vers iDocus/IDOC%COL1/IDOC%002 - DEF/période actuelle/BQ',
          '/exportation vers iDocus/IDOC%COL1/IDOC%002 - DEF/période précédente/AC',
          '/exportation vers iDocus/IDOC%COL1/IDOC%002 - DEF/période précédente/BQ'
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

        expect(WebMock).to have_requested(:any, /dropboxapi/).times(10)

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
            '/exportation vers iDocus/IDOC%COL1/IDOC%001 - ABC/période actuelle/AC',
            '/exportation vers iDocus/IDOC%COL1/IDOC%001 - ABC/période actuelle/VT',
            '/exportation vers iDocus/IDOC%COL1/IDOC%001 - ABC/période précédente/AC',
            '/exportation vers iDocus/IDOC%COL1/IDOC%001 - ABC/période précédente/VT',
            '/exportation vers iDocus/IDOC%COL1/IDOC%002 - DEF/période actuelle/AC',
            '/exportation vers iDocus/IDOC%COL1/IDOC%002 - DEF/période actuelle/BQ',
            '/exportation vers iDocus/IDOC%COL1/IDOC%002 - DEF/période précédente/AC',
            '/exportation vers iDocus/IDOC%COL1/IDOC%002 - DEF/période précédente/BQ'
          ]
        end

        context 'given a valid file at : /exportation vers iDocus/IDOC%COL1/IDOC%002 - DEF/période actuelle/AC/test.pdf' do
          it 'fetches one valid file' do
            delta_cursor = @dropbox.delta_cursor = 'AAGHorvqbn5732RU2CX9vD2vlIBHo--yqnTrT7aePCT0ioyAMfDOp02vn1FK1f3Duvun8QTCVTKnQ8jkWz674vsRGFWZmjfGL0ibYPHrKvsK8XNV4llsPt230EHl2vODBVk6ybGtcLxlT-fETh_bVF0YnueeM5MNyS54CMlJOxUUGjTMJTgKB9Xm47Vd-5siYlAa7qBIoGijEJyKaWFpfvktECxe5ePceh_JOYw_QSxu3OoEOf7QuS9KrZey1n5QNTE'
            @dropbox.save

            dropbox_import = FileImport::Dropbox.new(@dropbox)
            VCR.use_cassette('dropbox_import/collaborator/fetches_one_valid_file') do
              dropbox_import.check
            end

            # delta
            expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/continue')
            # get file
            expect(WebMock).to have_requested(:post, 'https://content.dropboxapi.com/2/files/download')
            # delete file
            expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/delete')

            expect(WebMock).to have_requested(:any, /dropboxapi/).times(3)

            temp_pack = TempPack.where(name: 'IDOC%002 AC 202010 all').first
            temp_document = temp_pack.temp_documents.first
            fingerprint = `md5sum #{temp_document.cloud_content_object.path}`.split.first
            expect(temp_pack.temp_documents.count).to eq 1
            expect(temp_document.original_file_name).to eq '2pages.pdf'
            expect(fingerprint).to eq '97f90eac0d07fe5ade8f60a0fa54cdfc'

            expect(dropbox_import.folders.size).to eq 8
            expect(dropbox_import.folders.select(&:exist?).size).to eq 8
          end
        end

        context 'given an invalid file at : /exportation vers iDocus/IDOC%COL1/IDOC%001 - ABC/période actuelle/AC/corrupted.pdf' do
          it 'marks one invalid file' do
            delta_cursor = @dropbox.delta_cursor = 'AAGHorvqbn5732RU2CX9vD2vlIBHo--yqnTrT7aePCT0ioyAMfDOp02vn1FK1f3Duvun8QTCVTKnQ8jkWz674vsRGFWZmjfGL0ibYPHrKvsK8XNV4llsPt230EHl2vODBVk6ybGtcLxlT-fETh_bVF0YnueeM5MNyS54CMlJOxUUGjTMJTgKB9Xm47Vd-5siYlAa7qBIoGijEJyKaWFpfvktECxe5ePceh_JOYw_QSxu3OoEOf7QuS9KrZey1n5QNTE'
            @dropbox.save

            dropbox_import = FileImport::Dropbox.new(@dropbox)
            VCR.use_cassette('dropbox_import/collaborator/marks_one_invalid_file') do
              dropbox_import.check
            end

            # delta
            expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/continue')
            # get file
            expect(WebMock).to have_requested(:post, 'https://content.dropboxapi.com/2/files/download')
            # rename file
            expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/move')

            expect(WebMock).to have_requested(:any, /dropboxapi/).times(3)

            temp_pack = TempPack.where(name: 'IDOC%001 AC 202010 all').first
            expect(temp_pack).to be_nil

            expect(dropbox_import.folders.size).to eq 8
            expect(dropbox_import.folders.select(&:exist?).size).to eq 8
          end
        end

        context 'given an invalid file already marked at : /exportation vers iDocus/IDOC%COL1/IDOC%001 - ABC/période actuelle/AC/corrupted (erreur fichier non valide pour idocus).pdf' do
          it 'ignores one file marked invalid' do
            delta_cursor = @dropbox.delta_cursor = 'AAGHorvqbn5732RU2CX9vD2vlIBHo--yqnTrT7aePCT0ioyAMfDOp02vn1FK1f3Duvun8QTCVTKnQ8jkWz674vsRGFWZmjfGL0ibYPHrKvsK8XNV4llsPt230EHl2vODBVk6ybGtcLxlT-fETh_bVF0YnueeM5MNyS54CMlJOxUUGjTMJTgKB9Xm47Vd-5siYlAa7qBIoGijEJyKaWFpfvktECxe5ePceh_JOYw_QSxu3OoEOf7QuS9KrZey1n5QNTE'
            @dropbox.save

            dropbox_import = FileImport::Dropbox.new(@dropbox)
            VCR.use_cassette('dropbox_import/collaborator/ignores_one_file_marked_invalid') do
              dropbox_import.check
            end

            # delta
            expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/continue')

            expect(WebMock).to have_requested(:any, /dropboxapi/).once

            temp_pack = TempPack.where(name: 'IDOC%001 AC 202010 all').first
            expect(temp_pack).to be_nil

            expect(dropbox_import.folders.size).to eq 8
            expect(dropbox_import.folders.select(&:exist?).size).to eq 8
          end
        end

        context 'given folder "/exportation vers iDocus/IDOC%COL1/IDOC%002 - DEF" is removed' do
          it 'recreates deleted folders' do
            delta_cursor = @dropbox.delta_cursor = 'AAGHorvqbn5732RU2CX9vD2vlIBHo--yqnTrT7aePCT0ioyAMfDOp02vn1FK1f3Duvun8QTCVTKnQ8jkWz674vsRGFWZmjfGL0ibYPHrKvsK8XNV4llsPt230EHl2vODBVk6ybGtcLxlT-fETh_bVF0YnueeM5MNyS54CMlJOxUUGjTMJTgKB9Xm47Vd-5siYlAa7qBIoGijEJyKaWFpfvktECxe5ePceh_JOYw_QSxu3OoEOf7QuS9KrZey1n5QNTE'
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
            expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/continue')
            # creates 4 folders
            [
              '/exportation vers iDocus/IDOC%COL1/IDOC%002 - DEF/période actuelle/AC',
              '/exportation vers iDocus/IDOC%COL1/IDOC%002 - DEF/période actuelle/BQ',
              '/exportation vers iDocus/IDOC%COL1/IDOC%002 - DEF/période précédente/AC',
              '/exportation vers iDocus/IDOC%COL1/IDOC%002 - DEF/période précédente/BQ'
            ].each do |path|
              expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/create_folder').
                with(headers: @headers_2, body: { path: path }.to_json)
            end

            expect(WebMock).to have_requested(:any, /dropboxapi/).times(5)

            expect(dropbox_import.folders.size).to eq 8
            expect(dropbox_import.folders.select(&:exist?).size).to eq 8
          end
        end

        context 'given folder at "/exportation vers iDocus/IDOC%COL1/IDOC%001 - ABC" renamed or moved to "OLD"' do
          it 'recreates renamed or moved folders' do
            @dropbox.delta_cursor = 'AAGHorvqbn5732RU2CX9vD2vlIBHo--yqnTrT7aePCT0ioyAMfDOp02vn1FK1f3Duvun8QTCVTKnQ8jkWz674vsRGFWZmjfGL0ibYPHrKvsK8XNV4llsPt230EHl2vODBVk6ybGtcLxlT-fETh_bVF0YnueeM5MNyS54CMlJOxUUGjTMJTgKB9Xm47Vd-5siYlAa7qBIoGijEJyKaWFpfvktECxe5ePceh_JOYw_QSxu3OoEOf7QuS9KrZey1n5QNTE'
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
              '/exportation vers iDocus/IDOC%COL1/IDOC%001 - ABC/période actuelle/AC',
              '/exportation vers iDocus/IDOC%COL1/IDOC%001 - ABC/période actuelle/VT',
              '/exportation vers iDocus/IDOC%COL1/IDOC%001 - ABC/période précédente/AC',
              '/exportation vers iDocus/IDOC%COL1/IDOC%001 - ABC/période précédente/VT'
            ].each do |path|
              expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/create_folder').
                with(headers: @headers_2, body: { path: path })
            end

            expect(WebMock).to have_requested(:any, /dropboxapi/).times(5)

            expect(dropbox_import.folders.size).to eq 8
            expect(dropbox_import.folders.select(&:exist?).size).to eq 8
          end
        end

        context 'given journal VT is added to user IDOC%002' do
          before(:each) { @journal = AccountBookType.create(user_id: @user2.id, name: 'VT', description: '( Vente )') }

          it 'creates 2 folders VT' do
            delta_cursor = @dropbox.delta_cursor = 'AAGHorvqbn5732RU2CX9vD2vlIBHo--yqnTrT7aePCT0ioyAMfDOp02vn1FK1f3Duvun8QTCVTKnQ8jkWz674vsRGFWZmjfGL0ibYPHrKvsK8XNV4llsPt230EHl2vODBVk6ybGtcLxlT-fETh_bVF0YnueeM5MNyS54CMlJOxUUGjTMJTgKB9Xm47Vd-5siYlAa7qBIoGijEJyKaWFpfvktECxe5ePceh_JOYw_QSxu3OoEOf7QuS9KrZey1n5QNTE'
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
              '/exportation vers iDocus/IDOC%COL1/IDOC%002 - DEF/période actuelle/VT',
              '/exportation vers iDocus/IDOC%COL1/IDOC%002 - DEF/période précédente/VT'
            ].each do |path|
              expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/create_folder').
                with(headers: @headers_2, body: { path: path })
            end

            expect(WebMock).to have_requested(:any, /dropboxapi/).times(3)

            expect(dropbox_import.folders.size).to eq 10
            expect(dropbox_import.folders.select(&:exist?).size).to eq 10
          end
        end

        context 'given journal BQ is renamed BQ1' do
          before(:each) { @user2.account_book_types.where(name: 'BQ').update_all(name: 'BQ1') }

          it 'deletes 2 folders BQ and creates 2 folders BQ1' do
            delta_cursor = @dropbox.delta_cursor = 'AAGHorvqbn5732RU2CX9vD2vlIBHo--yqnTrT7aePCT0ioyAMfDOp02vn1FK1f3Duvun8QTCVTKnQ8jkWz674vsRGFWZmjfGL0ibYPHrKvsK8XNV4llsPt230EHl2vODBVk6ybGtcLxlT-fETh_bVF0YnueeM5MNyS54CMlJOxUUGjTMJTgKB9Xm47Vd-5siYlAa7qBIoGijEJyKaWFpfvktECxe5ePceh_JOYw_QSxu3OoEOf7QuS9KrZey1n5QNTE'
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
              '/exportation vers iDocus/IDOC%COL1/IDOC%002 - DEF/période actuelle/BQ1',
              '/exportation vers iDocus/IDOC%COL1/IDOC%002 - DEF/période précédente/BQ1'
            ].each do |path|
              expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/create_folder').
                with(headers: @headers_2, body: { path: path })
            end
            # deletes 2 folders
            [
              '/exportation vers iDocus/IDOC%COL1/IDOC%002 - DEF/période actuelle/BQ',
              '/exportation vers iDocus/IDOC%COL1/IDOC%002 - DEF/période précédente/BQ'
            ].each do |path|
              expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/delete').
                with(headers: @headers_2, body: { path: path })
            end

            expect(WebMock).to have_requested(:any, /dropboxapi/).times(5)

            expect(dropbox_import.folders.size).to eq 8
            expect(dropbox_import.folders.select(&:exist?).size).to eq 8
          end
        end

        context 'given journal BQ1 was added' do
          before(:each) do
            @dropbox.import_folder_paths = [
              '/exportation vers iDocus/IDOC%COL1/IDOC%001 - ABC/période actuelle/AC',
              '/exportation vers iDocus/IDOC%COL1/IDOC%001 - ABC/période actuelle/VT',
              '/exportation vers iDocus/IDOC%COL1/IDOC%001 - ABC/période précédente/AC',
              '/exportation vers iDocus/IDOC%COL1/IDOC%001 - ABC/période précédente/VT',
              '/exportation vers iDocus/IDOC%COL1/IDOC%002 - DEF/période actuelle/AC',
              '/exportation vers iDocus/IDOC%COL1/IDOC%002 - DEF/période actuelle/BQ',
              '/exportation vers iDocus/IDOC%COL1/IDOC%002 - DEF/période actuelle/BQ1',
              '/exportation vers iDocus/IDOC%COL1/IDOC%002 - DEF/période précédente/AC',
              '/exportation vers iDocus/IDOC%COL1/IDOC%002 - DEF/période précédente/BQ',
              '/exportation vers iDocus/IDOC%COL1/IDOC%002 - DEF/période précédente/BQ1',
            ]
          end

          context 'given journal BQ and BQ1 are removed' do
            before(:each) { @user2.account_book_types.where(name: 'BQ').destroy_all }

            it 'deletes 2 folders BQ and deletes 2 folders BQ1' do
              delta_cursor = @dropbox.delta_cursor = 'AAGHorvqbn5732RU2CX9vD2vlIBHo--yqnTrT7aePCT0ioyAMfDOp02vn1FK1f3Duvun8QTCVTKnQ8jkWz674vsRGFWZmjfGL0ibYPHrKvsK8XNV4llsPt230EHl2vODBVk6ybGtcLxlT-fETh_bVF0YnueeM5MNyS54CMlJOxUUGjTMJTgKB9Xm47Vd-5siYlAa7qBIoGijEJyKaWFpfvktECxe5ePceh_JOYw_QSxu3OoEOf7QuS9KrZey1n5QNTE'
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
                '/exportation vers iDocus/IDOC%COL1/IDOC%002 - DEF/période actuelle/BQ',
                '/exportation vers iDocus/IDOC%COL1/IDOC%002 - DEF/période actuelle/BQ1',
                '/exportation vers iDocus/IDOC%COL1/IDOC%002 - DEF/période précédente/BQ',
                '/exportation vers iDocus/IDOC%COL1/IDOC%002 - DEF/période précédente/BQ1'
              ].each do |path|
                expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/delete').
                  with(headers: @headers_2, body: { path: path })
              end

              expect(WebMock).to have_requested(:any, /dropboxapi/).times(5)

              expect(dropbox_import.folders.size).to eq 6
              expect(dropbox_import.folders.select(&:exist?).size).to eq 6
            end

            context 'given IDOC%002 is removed from group' do
              before(:each) { @user2.groups.clear }

              it 'removes only the parent folder : IDOC%002 - DEF' do
                delta_cursor = @dropbox.delta_cursor = 'AAGHorvqbn5732RU2CX9vD2vlIBHo--yqnTrT7aePCT0ioyAMfDOp02vn1FK1f3Duvun8QTCVTKnQ8jkWz674vsRGFWZmjfGL0ibYPHrKvsK8XNV4llsPt230EHl2vODBVk6ybGtcLxlT-fETh_bVF0YnueeM5MNyS54CMlJOxUUGjTMJTgKB9Xm47Vd-5siYlAa7qBIoGijEJyKaWFpfvktECxe5ePceh_JOYw_QSxu3OoEOf7QuS9KrZey1n5QNTE'
                @dropbox.save

                dropbox_import = FileImport::Dropbox.new(@dropbox)

                expect(dropbox_import.folders.size).to eq 10
                expect(dropbox_import.folders.select(&:exist?).size).to eq 4
                expect(dropbox_import.folders.select(&:to_be_destroyed?).size).to eq 6
                expect(dropbox_import.folders.select(&:to_be_created?).size).to eq 0

                VCR.use_cassette('dropbox_import/collaborator/removes_parent_folder_IDOC%002_-_def') do
                  dropbox_import.check
                end

                # delta
                expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/continue')
                # deletes parent folder IDOC%002 - DEF
                expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/delete')

                expect(WebMock).to have_requested(:any, /dropboxapi/).times(2)

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
            delta_cursor = @dropbox.delta_cursor = 'AAGHorvqbn5732RU2CX9vD2vlIBHo--yqnTrT7aePCT0ioyAMfDOp02vn1FK1f3Duvun8QTCVTKnQ8jkWz674vsRGFWZmjfGL0ibYPHrKvsK8XNV4llsPt230EHl2vODBVk6ybGtcLxlT-fETh_bVF0YnueeM5MNyS54CMlJOxUUGjTMJTgKB9Xm47Vd-5siYlAa7qBIoGijEJyKaWFpfvktECxe5ePceh_JOYw_QSxu3OoEOf7QuS9KrZey1n5QNTE'
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
              '/exportation vers iDocus/IDOC%COL1/IDOC%001 - ABC/période actuelle/VT',
              '/exportation vers iDocus/IDOC%COL1/IDOC%001 - ABC/période précédente/VT'
            ].each do |path|
              expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/delete').
                with(headers: @headers_2, body: { path: path })
            end

            expect(WebMock).to have_requested(:any, /dropboxapi/).times(3)

            expect(dropbox_import.folders.size).to eq 6
            expect(dropbox_import.folders.select(&:exist?).size).to eq 6
          end
        end

        context 'given IDOC%001 is removed from group' do
          before(:each) { @user.groups.clear }

          it 'removes folder IDOC%001 - ABC' do
            delta_cursor = @dropbox.delta_cursor = 'AAGHorvqbn5732RU2CX9vD2vlIBHo--yqnTrT7aePCT0ioyAMfDOp02vn1FK1f3Duvun8QTCVTKnQ8jkWz674vsRGFWZmjfGL0ibYPHrKvsK8XNV4llsPt230EHl2vODBVk6ybGtcLxlT-fETh_bVF0YnueeM5MNyS54CMlJOxUUGjTMJTgKB9Xm47Vd-5siYlAa7qBIoGijEJyKaWFpfvktECxe5ePceh_JOYw_QSxu3OoEOf7QuS9KrZey1n5QNTE'
            @dropbox.save

            dropbox_import = FileImport::Dropbox.new(@dropbox)

            expect(dropbox_import.folders.size).to eq 8
            expect(dropbox_import.folders.select(&:exist?).size).to eq 4
            expect(dropbox_import.folders.select(&:to_be_destroyed?).size).to eq 4
            expect(dropbox_import.folders.select(&:to_be_created?).size).to eq 0

            VCR.use_cassette('dropbox_import/collaborator/removes_folder_idoc%001_-_abc') do
              dropbox_import.check
            end

            # delta
            expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/continue').
              with(headers: @headers_2, body: /\{"cursor":".*"\}/)
            # deletes folder IDOC%001 - ABC
            expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/delete').
              with(headers: @headers_2, body: { path: '/exportation vers iDocus/IDOC%COL1/IDOC%001 - ABC' })

            expect(WebMock).to have_requested(:any, /dropboxapi/).times(2)

            expect(dropbox_import.folders.size).to eq 4
            expect(dropbox_import.folders.select(&:exist?).size).to eq 4
          end
        end

        context 'given IDOC%003 is added' do
          before(:each) do
            @user3 = FactoryBot.create(:user, code: 'IDOC%003', company: 'GHI')
            @user3.options = UserOptions.create(user_id: @user3.id, is_upload_authorized: true)
            @user3.organization = @organization
            @user3.save

            AccountBookType.create(user_id: @user3.id, name: 'AC', description: '( Achat )')
            AccountBookType.create(user_id: @user3.id, name: 'BQ', description: '( Banque )')

            @group.customers << @user3
            @group.save
          end

          it 'creates IDOC%003\'s folders' do
            delta_cursor = @dropbox.delta_cursor = 'AAGHorvqbn5732RU2CX9vD2vlIBHo--yqnTrT7aePCT0ioyAMfDOp02vn1FK1f3Duvun8QTCVTKnQ8jkWz674vsRGFWZmjfGL0ibYPHrKvsK8XNV4llsPt230EHl2vODBVk6ybGtcLxlT-fETh_bVF0YnueeM5MNyS54CMlJOxUUGjTMJTgKB9Xm47Vd-5siYlAa7qBIoGijEJyKaWFpfvktECxe5ePceh_JOYw_QSxu3OoEOf7QuS9KrZey1n5QNTE'
            @dropbox.save

            dropbox_import = FileImport::Dropbox.new(@dropbox)

            expect(dropbox_import.folders.size).to eq 12
            expect(dropbox_import.folders.select(&:exist?).size).to eq 8
            expect(dropbox_import.folders.select(&:to_be_destroyed?).size).to eq 0
            expect(dropbox_import.folders.select(&:to_be_created?).size).to eq 4

            VCR.use_cassette('dropbox_import/collaborator/creates_idoc%003s_folders') do
              dropbox_import.check
            end

            # delta
            expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/continue').
              with(headers: @headers_2, body: /\{"cursor":".*"\}/)
            # # creates 4 folders
            [
              '/exportation vers iDocus/IDOC%COL1/IDOC%003 - GHI/période actuelle/AC',
              '/exportation vers iDocus/IDOC%COL1/IDOC%003 - GHI/période actuelle/BQ',
              '/exportation vers iDocus/IDOC%COL1/IDOC%003 - GHI/période précédente/AC',
              '/exportation vers iDocus/IDOC%COL1/IDOC%003 - GHI/période précédente/BQ'
            ].each do |path|
              expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/create_folder').
                with(headers: @headers_2, body: { path: path })
            end

            expect(WebMock).to have_requested(:any, /dropboxapi/).times(5)

            expect(dropbox_import.folders.size).to eq 12
            expect(dropbox_import.folders.select(&:exist?).size).to eq 12
          end
        end

        context 'given IDOC%002 company is modified' do
          before(:each) { @user2.update(company: 'DDD') }

          it 'removes folder "IDOC%002 - DEF" and creates folder "IDOC%002 - DDD" and subfolders' do
            delta_cursor = @dropbox.delta_cursor = 'AAGHorvqbn5732RU2CX9vD2vlIBHo--yqnTrT7aePCT0ioyAMfDOp02vn1FK1f3Duvun8QTCVTKnQ8jkWz674vsRGFWZmjfGL0ibYPHrKvsK8XNV4llsPt230EHl2vODBVk6ybGtcLxlT-fETh_bVF0YnueeM5MNyS54CMlJOxUUGjTMJTgKB9Xm47Vd-5siYlAa7qBIoGijEJyKaWFpfvktECxe5ePceh_JOYw_QSxu3OoEOf7QuS9KrZey1n5QNTE'
            @dropbox.save

            dropbox_import = FileImport::Dropbox.new(@dropbox)

            expect(dropbox_import.folders.size).to eq 12
            expect(dropbox_import.folders.select(&:exist?).size).to eq 4
            expect(dropbox_import.folders.select(&:to_be_destroyed?).size).to eq 4
            expect(dropbox_import.folders.select(&:to_be_created?).size).to eq 4

            VCR.use_cassette('dropbox_import/collaborator/renames_folder_idoc%002_-_def') do
              dropbox_import.check
            end

            # delta
            expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder/continue').
              with(headers: @headers_2, body: /\{"cursor":".*"\}/)
            # deletes folder '/exportation vers iDocus/IDOC%002 - DEF'
            expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/delete').
              with(headers: @headers_2, body: { path: '/exportation vers iDocus/IDOC%COL1/IDOC%002 - DEF' })
            # creates 4 folders
            [
              '/exportation vers iDocus/IDOC%COL1/IDOC%002 - DDD/période actuelle/AC',
              '/exportation vers iDocus/IDOC%COL1/IDOC%002 - DDD/période actuelle/BQ',
              '/exportation vers iDocus/IDOC%COL1/IDOC%002 - DDD/période précédente/AC',
              '/exportation vers iDocus/IDOC%COL1/IDOC%002 - DDD/période précédente/BQ'
            ].each do |path|
              expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/create_folder').
                with(headers: @headers_2, body: { path: path })
            end

            expect(WebMock).to have_requested(:any, /dropboxapi/).times(6)

            expect(dropbox_import.folders.size).to eq 8
            expect(dropbox_import.folders.select(&:exist?).size).to eq 8
          end
        end
      end
    end

    context 'as a contact', :contact do
      before(:each) do
        DatabaseCleaner.start

        @organization = Organization.create(name: 'TEST', code: 'IDOC')

        @contact = FactoryBot.create(:user, is_guest: true, code: 'IDOC%SHR1')
        @contact.organization = @organization
        @contact.save

        @user = FactoryBot.create(:user, code: 'IDOC%001', company: 'ABC')
        @user.options = UserOptions.create(user_id: @user.id, is_upload_authorized: true)
        @user.organization = @organization
        @user.save

        AccountBookType.create(user_id: @user.id, name: 'AC', description: '( Achat )')
        AccountBookType.create(user_id: @user.id, name: 'VT', description: '( Vente )')

        @user2 = FactoryBot.create(:user, code: 'IDOC%002', company: 'DEF')
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
        @dropbox.access_token = 'd_8hw4XA240AAAAAAAAAAbdOcCNXL3qwaOp05judYxFkgJBjoRxIwBlDVCbOW3m2'
        @dropbox.save

        @contact.reload

        @headers = { 'Authorization' => 'Bearer d_8hw4XA240AAAAAAAAAAbdOcCNXL3qwaOp05judYxFkgJBjoRxIwBlDVCbOW3m2' }
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
          '/exportation vers iDocus/IDOC%001 - ABC/période actuelle/AC',
          '/exportation vers iDocus/IDOC%001 - ABC/période actuelle/VT',
          '/exportation vers iDocus/IDOC%001 - ABC/période précédente/AC',
          '/exportation vers iDocus/IDOC%001 - ABC/période précédente/VT',
          '/exportation vers iDocus/IDOC%002 - DEF/période actuelle/AC',
          '/exportation vers iDocus/IDOC%002 - DEF/période actuelle/BQ',
          '/exportation vers iDocus/IDOC%002 - DEF/période précédente/AC',
          '/exportation vers iDocus/IDOC%002 - DEF/période précédente/BQ'
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

        expect(WebMock).to have_requested(:any, /dropboxapi/).times(10)

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
