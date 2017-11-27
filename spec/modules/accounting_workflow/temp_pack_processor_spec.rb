# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe AccountingWorkflow::TempPackProcessor do
  describe '.process for monthly' do
    before(:all) do
      DatabaseCleaner.start
      Timecop.freeze(Time.local(2013,1,1))

      @user = FactoryGirl.create(:user, code: 'TS0001')
      @user.create_options
      @user.create_notify
      @user.find_or_create_subscription
      @journal = @user.account_book_types.create(name: 'TS', description: 'TEST')

      @upload_file = File.open File.join(Rails.root, 'spec', 'support', 'files', 'upload.pdf'), 'r'
      @file_with_2_pages = File.open File.join(Rails.root, 'spec', 'support', 'files', '2pages.pdf'), 'r'
      @content64 = Base64::encode64(@file_with_2_pages.readlines.join)
    end

    after(:all) do
      @upload_file.close
      @file_with_2_pages.close
      DatabaseCleaner.clean
      Timecop.return
    end

    context 'with 2 uploaded files' do
      before(:all) do
        UploadedDocument.new @upload_file, "upload_with_1_page.pdf", @user, 'TS', 0
        UploadedDocument.new @file_with_2_pages, "upload_with_2_pages.pdf", @user, 'TS', 0
        @temp_pack = @user.temp_packs.first

        AccountingWorkflow::TempPackProcessor.process(@temp_pack)

        @user.reload
        @temp_pack.reload
        @pack = @user.packs.first
      end

      after(:all) do
        TempPack.destroy_all
        Pack.destroy_all
      end

      describe 'temp_pack' do
        subject { @temp_pack }

        describe '#document_not_processed_count' do
          subject { super().document_not_processed_count }
          it { is_expected.to eq(0) }
        end

        describe 'temp_documents' do
          subject { @temp_pack.temp_documents }

          describe '#count' do
            subject { super().count }
            it { is_expected.to eq(2) }
          end
        end
      end

      describe 'pack' do
        subject { @pack }

        it { is_expected.to be_persisted }

        describe '#name' do
          subject { super().name }
          it { is_expected.to eq('TS0001 TS 201301 all') }
        end

        describe 'global document' do
          subject { @pack.original_document }

          describe '#content_file_name' do
            subject { super().content_file_name }
            it { is_expected.to eq('TS0001_TS_201301_all.pdf') }
          end

          describe '#uploaded?' do
            subject { super().uploaded? }
            it { is_expected.to eq(false) }
          end

          describe '#is_a_cover' do
            subject { super().is_a_cover }
            it { is_expected.to eq(false) }
          end

          describe '#position' do
            subject { super().position }
            it { is_expected.to eq(nil) }
          end

          it 'should have 3 pages' do
            expect(DocumentTools.pages_number(subject.content.path)).to eq(3)
          end
        end

        describe 'dividers' do
          subject { @pack.dividers }

          describe '#count' do
            subject { super().count }
            it { is_expected.to eq(2) }
          end

          describe 'pieces' do
            before(:all) do
              @pieces = @pack.dividers.pieces.by_position
            end

            subject { @pieces }

            describe '#count' do
              subject { super().count }
              it { is_expected.to eq(2) }
            end

            describe 'n°1' do
              subject { @pieces[0] }

              describe '#name' do
                subject { super().name }
                it { is_expected.to eq 'TS0001_TS_201301_001' }
              end

              describe '#pages_number' do
                subject { super().pages_number }
                it { is_expected.to eq(1) }
              end

              describe '#origin' do
                subject { super().origin }
                it { is_expected.to eq('upload') }
              end

              describe '#is_a_cover' do
                subject { super().is_a_cover }
                it { is_expected.to eq(false) }
              end

              describe '#position' do
                subject { super().position }
                it { is_expected.to eq(1) }
              end
            end

            describe 'n°2' do
              subject { @pieces[1] }

              describe '#name' do
                subject { super().name }
                it { is_expected.to eq 'TS0001_TS_201301_002' }
              end

              describe '#pages_number' do
                subject { super().pages_number }
                it { is_expected.to eq(2) }
              end

              describe '#origin' do
                subject { super().origin }
                it { is_expected.to eq('upload') }
              end

              describe '#is_a_cover' do
                subject { super().is_a_cover }
                it { is_expected.to eq(false) }
              end

              describe '#position' do
                subject { super().position }
                it { is_expected.to eq(2) }
              end
            end
          end
        end

        describe 'pages' do
          subject { @pack.pages }

          describe '#count' do
            subject { super().count }
            it { is_expected.to eq(3) }
          end

          describe 'n°1' do
            subject { @pack.pages.by_position[0] }

            describe '#content_file_name' do
              subject { super().content_file_name }
              it { is_expected.to eq('TS0001_TS_201301_page_001.pdf') }
            end

            describe '#position' do
              subject { super().position }
              it { is_expected.to eq(0) }
            end

            describe '#mixed?' do
              subject { super().mixed? }
              it { is_expected.to eq(false) }
            end

            describe '#uploaded?' do
              subject { super().uploaded? }
              it { is_expected.to eq(true) }
            end

            describe '#is_a_cover' do
              subject { super().is_a_cover }
              it { is_expected.to eq(false) }
            end

            describe '#tags' do
              subject { super().tags }
              it { is_expected.to eq(['ts0001', 'ts', '201301', '1']) }
            end
          end

          describe 'n°2' do
            subject { @pack.pages.by_position[1] }

            describe '#content_file_name' do
              subject { super().content_file_name }
              it { is_expected.to eq('TS0001_TS_201301_page_002.pdf') }
            end

            describe '#position' do
              subject { super().position }
              it { is_expected.to eq(1) }
            end

            describe '#mixed?' do
              subject { super().mixed? }
              it { is_expected.to eq(false) }
            end

            describe '#uploaded?' do
              subject { super().uploaded? }
              it { is_expected.to eq(true) }
            end

            describe '#is_a_cover' do
              subject { super().is_a_cover }
              it { is_expected.to eq(false) }
            end

            describe '#tags' do
              subject { super().tags }
              it { is_expected.to eq(['ts0001', 'ts', '201301', '2']) }
            end
          end

          describe 'n°3' do
            subject { @pack.pages.by_position[2] }

            describe '#content_file_name' do
              subject { super().content_file_name }
              it { is_expected.to eq('TS0001_TS_201301_page_003.pdf') }
            end

            describe '#position' do
              subject { super().position }
              it { is_expected.to eq(2) }
            end

            describe '#mixed?' do
              subject { super().mixed? }
              it { is_expected.to eq(false) }
            end

            describe '#uploaded?' do
              subject { super().uploaded? }
              it { is_expected.to eq(true) }
            end

            describe '#is_a_cover' do
              subject { super().is_a_cover }
              it { is_expected.to eq(false) }
            end

            describe '#tags' do
              subject { super().tags }
              it { is_expected.to eq(['ts0001', 'ts', '201301', '3']) }
            end
          end
        end

        describe 'pieces' do
          subject { @pack.pieces }

          describe '#count' do
            subject { super().count }
            it { is_expected.to eq(2) }
          end

          describe 'n°1' do
            subject { @pack.pieces.by_position[0] }

            describe '#name' do
              subject { super().name }
              it { is_expected.to eq('TS0001 TS 201301 001') }
            end

            describe '#content_file_name' do
              subject { super().content_file_name }
              it { is_expected.to eq('TS0001_TS_201301_001.pdf') }
            end

            describe '#uploaded?' do
              subject { super().uploaded? }
              it { is_expected.to eq(true) }
            end

            describe '#is_a_cover' do
              subject { super().is_a_cover }
              it { is_expected.to eq(false) }
            end

            describe '#position' do
              subject { super().position }
              it { is_expected.to eq(1) }
            end
          end

          describe 'n°2' do
            subject { @pack.pieces.by_position[1] }

            describe '#name' do
              subject { super().name }
              it { is_expected.to eq('TS0001 TS 201301 002') }
            end

            describe '#content_file_name' do
              subject { super().content_file_name }
              it { is_expected.to eq('TS0001_TS_201301_002.pdf') }
            end

            describe '#uploaded?' do
              subject { super().uploaded? }
              it { is_expected.to eq(true) }
            end

            describe '#is_a_cover' do
              subject { super().is_a_cover }
              it { is_expected.to eq(false) }
            end

            describe '#position' do
              subject { super().position }
              it { is_expected.to eq(2) }
            end
          end
        end
      end
    end

    context 'with 1 cover and 1 scan files current' do
      before(:all) do
        Dir.mktmpdir do |dir|
          @temp_pack = TempPack.find_or_create_by_name 'TS0001 TS 201301 all'

          2.times do |i|
            file_name = "TS0001_TS_201301_00#{i}.pdf"
            file_path = File.join(dir, file_name)
            FileUtils.cp @file_with_2_pages, file_path
            temp_document = TempDocument.new

            temp_document.user               = @user
            temp_document.temp_pack          = @temp_pack
            temp_document.original_file_name = file_name
            temp_document.content            = open(file_path)
            temp_document.position           = @temp_pack.next_document_position

            temp_document.delivered_by       = 'ppp'
            temp_document.delivery_type      = 'scan'

            temp_document.save
            temp_document.ready
          end
        end

        AccountingWorkflow::TempPackProcessor.process(@temp_pack)

        @user.reload
        @temp_pack.reload
        @pack = @user.packs.first
      end

      after(:all) do
        TempPack.destroy_all
        Pack.destroy_all
      end

      describe 'temp_pack' do
        subject { @temp_pack }

        describe '#document_not_processed_count' do
          subject { super().document_not_processed_count }
          it { is_expected.to eq(0) }
        end

        describe 'temp_documents' do
          subject { @temp_pack.temp_documents }

          describe '#count' do
            subject { super().count }
            it { is_expected.to eq(2) }
          end
        end
      end

      describe 'pack' do
        subject { @pack }

        it { is_expected.to be_persisted }

        describe '#name' do
          subject { super().name }
          it { is_expected.to eq('TS0001 TS 201301 all') }
        end

        describe 'global document' do
          subject { @pack.original_document }

          describe '#content_file_name' do
            subject { super().content_file_name }
            it { is_expected.to eq('TS0001_TS_201301_all.pdf') }
          end

          describe '#uploaded?' do
            subject { super().uploaded? }
            it { is_expected.to eq(false) }
          end

          describe '#is_a_cover' do
            subject { super().is_a_cover }
            it { is_expected.to eq(false) }
          end

          describe '#position' do
            subject { super().position }
            it { is_expected.to eq(nil) }
          end

          it 'should have 4 pages' do
            expect(DocumentTools.pages_number(subject.content.path)).to eq(4)
          end
        end

        describe 'dividers' do
          subject { @pack.dividers }

          describe '#count' do
            subject { super().count }
            it { is_expected.to eq(4) }
          end

          describe 'pieces' do
            before(:all) do
              @pieces = @pack.dividers.pieces.by_position
            end

            subject { @pieces }

            describe '#count' do
              subject { super().count }
              it { is_expected.to eq(2) }
            end

            describe 'n°1' do
              subject { @pieces[0] }

              describe '#name' do
                subject { super().name }
                it { is_expected.to eq 'TS0001_TS_201301_000' }
              end

              describe '#pages_number' do
                subject { super().pages_number }
                it { is_expected.to eq(2) }
              end

              describe '#origin' do
                subject { super().origin }
                it { is_expected.to eq('scan') }
              end

              describe '#is_a_cover' do
                subject { super().is_a_cover }
                it { is_expected.to eq(true) }
              end

              describe '#position' do
                subject { super().position }
                it { is_expected.to eq(0) }
              end
            end

            describe 'n°2' do
              subject { @pieces[1] }

              describe '#name' do
                subject { super().name }
                it { is_expected.to eq 'TS0001_TS_201301_001' }
              end

              describe '#pages_number' do
                subject { super().pages_number }
                it { is_expected.to eq(2) }
              end

              describe '#origin' do
                subject { super().origin }
                it { is_expected.to eq('scan') }
              end

              describe '#is_a_cover' do
                subject { super().is_a_cover }
                it { is_expected.to eq(false) }
              end

              describe '#position' do
                subject { super().position }
                it { is_expected.to eq(1) }
              end
            end
          end

          describe 'sheets' do
            before(:all) do
              @sheets = @pack.dividers.sheets.by_position
            end

            subject { @sheets }

            describe '#count' do
              subject { super().count }
              it { is_expected.to eq(2) }
            end

            describe 'n°1' do
              subject { @sheets[0] }

              describe '#name' do
                subject { super().name }
                it { is_expected.to eq 'TS0001_TS_201301_000' }
              end

              describe '#pages_number' do
                subject { super().pages_number }
                it { is_expected.to eq(2) }
              end

              describe '#origin' do
                subject { super().origin }
                it { is_expected.to eq('scan') }
              end

              describe '#is_a_cover' do
                subject { super().is_a_cover }
                it { is_expected.to eq(true) }
              end

              describe '#position' do
                subject { super().position }
                it { is_expected.to eq(0) }
              end
            end

            describe 'n°2' do
              subject { @sheets[1] }

              describe '#name' do
                subject { super().name }
                it { is_expected.to eq 'TS0001_TS_201301_001' }
              end

              describe '#pages_number' do
                subject { super().pages_number }
                it { is_expected.to eq(2) }
              end

              describe '#origin' do
                subject { super().origin }
                it { is_expected.to eq('scan') }
              end

              describe '#is_a_cover' do
                subject { super().is_a_cover }
                it { is_expected.to eq(false) }
              end

              describe '#position' do
                subject { super().position }
                it { is_expected.to eq(1) }
              end
            end
          end
        end

        describe 'pages' do
          subject { @pack.pages }

          describe '#count' do
            subject { super().count }
            it { is_expected.to eq(4) }
          end

          describe 'n°1' do
            subject { @pack.pages.by_position[0] }

            describe '#content_file_name' do
              subject { super().content_file_name }
              it { is_expected.to eq('TS0001_TS_201301_cover_page_001.pdf') }
            end

            describe '#position' do
              subject { super().position }
              it { is_expected.to eq(-2) }
            end

            describe '#mixed?' do
              subject { super().mixed? }
              it { is_expected.to eq(false) }
            end

            describe '#uploaded?' do
              subject { super().uploaded? }
              it { is_expected.to eq(false) }
            end

            describe '#is_a_cover' do
              subject { super().is_a_cover }
              it { is_expected.to eq(true) }
            end

            describe '#tags' do
              subject { super().tags }
              it { is_expected.to eq(['ts0001', 'ts', '201301', '1']) }
            end
          end

          describe 'n°2' do
            subject { @pack.pages.by_position[1] }

            describe '#content_file_name' do
              subject { super().content_file_name }
              it { is_expected.to eq('TS0001_TS_201301_cover_page_002.pdf') }
            end

            describe '#position' do
              subject { super().position }
              it { is_expected.to eq(-1) }
            end

            describe '#mixed?' do
              subject { super().mixed? }
              it { is_expected.to eq(false) }
            end

            describe '#uploaded?' do
              subject { super().uploaded? }
              it { is_expected.to eq(false) }
            end

            describe '#is_a_cover' do
              subject { super().is_a_cover }
              it { is_expected.to eq(true) }
            end

            describe '#tags' do
              subject { super().tags }
              it { is_expected.to eq(['ts0001', 'ts', '201301', '2']) }
            end
          end

          describe 'n°3' do
            subject { @pack.pages.by_position[2] }

            describe '#content_file_name' do
              subject { super().content_file_name }
              it { is_expected.to eq('TS0001_TS_201301_page_001.pdf') }
            end

            describe '#position' do
              subject { super().position }
              it { is_expected.to eq(0) }
            end

            describe '#mixed?' do
              subject { super().mixed? }
              it { is_expected.to eq(false) }
            end

            describe '#uploaded?' do
              subject { super().uploaded? }
              it { is_expected.to eq(false) }
            end

            describe '#is_a_cover' do
              subject { super().is_a_cover }
              it { is_expected.to eq(false) }
            end

            describe '#tags' do
              subject { super().tags }
              it { is_expected.to eq(['ts0001', 'ts', '201301', '1']) }
            end
          end

          describe 'n°4' do
            subject { @pack.pages.by_position[3] }

            describe '#content_file_name' do
              subject { super().content_file_name }
              it { is_expected.to eq('TS0001_TS_201301_page_002.pdf') }
            end

            describe '#position' do
              subject { super().position }
              it { is_expected.to eq(1) }
            end

            describe '#mixed?' do
              subject { super().mixed? }
              it { is_expected.to eq(false) }
            end

            describe '#uploaded?' do
              subject { super().uploaded? }
              it { is_expected.to eq(false) }
            end

            describe '#is_a_cover' do
              subject { super().is_a_cover }
              it { is_expected.to eq(false) }
            end

            describe '#tags' do
              subject { super().tags }
              it { is_expected.to eq(['ts0001', 'ts', '201301', '2']) }
            end
          end
        end

        describe 'pieces' do
          subject { @pack.pieces }

          describe '#count' do
            subject { super().count }
            it { is_expected.to eq(2) }
          end

          describe 'n°1' do
            subject { @pack.pieces.by_position[0] }

            describe '#name' do
              subject { super().name }
              it { is_expected.to eq('TS0001 TS 201301 000') }
            end

            describe '#content_file_name' do
              subject { super().content_file_name }
              it { is_expected.to eq('TS0001_TS_201301_000.pdf') }
            end

            describe '#uploaded?' do
              subject { super().uploaded? }
              it { is_expected.to eq(false) }
            end

            describe '#is_a_cover' do
              subject { super().is_a_cover }
              it { is_expected.to eq(true) }
            end

            describe '#position' do
              subject { super().position }
              it { is_expected.to eq(0) }
            end
          end

          describe 'n°2' do
            subject { @pack.pieces.by_position[1] }

            describe '#name' do
              subject { super().name }
              it { is_expected.to eq('TS0001 TS 201301 001') }
            end

            describe '#content_file_name' do
              subject { super().content_file_name }
              it { is_expected.to eq('TS0001_TS_201301_001.pdf') }
            end

            describe '#uploaded?' do
              subject { super().uploaded? }
              it { is_expected.to eq(false) }
            end

            describe '#is_a_cover' do
              subject { super().is_a_cover }
              it { is_expected.to eq(false) }
            end

            describe '#position' do
              subject { super().position }
              it { is_expected.to eq(1) }
            end
          end
        end
      end
    end

    context 'with 1 dematbox scanned files' do
      before(:all) do
        params = {
          'virtual_box_id' => 'TS0001',
          'service_id' => '1',
          'improved_scan' => @content64,
          'doc_id' => '1',
          'box_id' => '1',
          'text' => nil
        }

        dematbox = Dematbox.new
        dematbox.user = @user
        service = DematboxSubscribedService.new
        service.pid = '1'
        service.is_for_current_period = true
        service.name = 'TS'
        dematbox.services << service
        dematbox.save

        CreateDematboxDocument.new(params).execute

        @temp_pack = @user.temp_packs.first

        AccountingWorkflow::TempPackProcessor.process(@temp_pack)

        @user.reload
        @temp_pack.reload
        @pack = @user.packs.first
      end

      after(:all) do
        TempPack.destroy_all
        Pack.destroy_all
      end

      describe 'temp_pack' do
        subject { @temp_pack }

        describe '#document_not_processed_count' do
          subject { super().document_not_processed_count }
          it { is_expected.to eq(0) }
        end

        describe 'temp_documents' do
          subject { @temp_pack.temp_documents }

          describe '#count' do
            subject { super().count }
            it { is_expected.to eq(1) }
          end
        end
      end

      describe 'pack' do
        subject { @pack }

        it { is_expected.to be_persisted }

        describe '#name' do
          subject { super().name }
          it { is_expected.to eq('TS0001 TS 201301 all') }
        end

        describe 'global document' do
          subject { @pack.original_document }

          describe '#content_file_name' do
            subject { super().content_file_name }
            it { is_expected.to eq('TS0001_TS_201301_all.pdf') }
          end

          describe '#uploaded?' do
            subject { super().uploaded? }
            it { is_expected.to eq(false) }
          end

          describe '#is_a_cover' do
            subject { super().is_a_cover }
            it { is_expected.to eq(false) }
          end

          describe '#position' do
            subject { super().position }
            it { is_expected.to eq(nil) }
          end

          it 'should have 2 pages' do
            expect(DocumentTools.pages_number(subject.content.path)).to eq(2)
          end
        end

        describe 'dividers' do
          subject { @pack.dividers }

          describe '#count' do
            subject { super().count }
            it { is_expected.to eq(1) }
          end

          describe 'pieces' do
            before(:all) do
              @pieces = @pack.dividers.pieces.by_position
            end

            subject { @pieces }

            describe '#count' do
              subject { super().count }
              it { is_expected.to eq(1) }
            end

            describe 'n°1' do
              subject { @pieces[0] }

              describe '#name' do
                subject { super().name }
                it { is_expected.to eq 'TS0001_TS_201301_001' }
              end

              describe '#pages_number' do
                subject { super().pages_number }
                it { is_expected.to eq(2) }
              end

              describe '#origin' do
                subject { super().origin }
                it { is_expected.to eq('dematbox_scan') }
              end

              describe '#is_a_cover' do
                subject { super().is_a_cover }
                it { is_expected.to eq(false) }
              end

              describe '#position' do
                subject { super().position }
                it { is_expected.to eq(1) }
              end
            end
          end
        end

        describe 'pages' do
          subject { @pack.pages }

          describe '#count' do
            subject { super().count }
            it { is_expected.to eq(2) }
          end

          describe 'n°1' do
            subject { @pack.pages.by_position[0] }

            describe '#content_file_name' do
              subject { super().content_file_name }
              it { is_expected.to eq('TS0001_TS_201301_page_001.pdf') }
            end

            describe '#position' do
              subject { super().position }
              it { is_expected.to eq(0) }
            end

            describe '#mixed?' do
              subject { super().mixed? }
              it { is_expected.to eq(false) }
            end

            describe '#uploaded?' do
              subject { super().uploaded? }
              it { is_expected.to eq(false) }
            end

            describe '#is_a_cover' do
              subject { super().is_a_cover }
              it { is_expected.to eq(false) }
            end

            describe '#tags' do
              subject { super().tags }
              it { is_expected.to eq(['ts0001', 'ts', '201301', '1']) }
            end
          end

          describe 'n°2' do
            subject { @pack.pages.by_position[1] }

            describe '#content_file_name' do
              subject { super().content_file_name }
              it { is_expected.to eq('TS0001_TS_201301_page_002.pdf') }
            end

            describe '#position' do
              subject { super().position }
              it { is_expected.to eq(1) }
            end

            describe '#mixed?' do
              subject { super().mixed? }
              it { is_expected.to eq(false) }
            end

            describe '#uploaded?' do
              subject { super().uploaded? }
              it { is_expected.to eq(false) }
            end

            describe '#is_a_cover' do
              subject { super().is_a_cover }
              it { is_expected.to eq(false) }
            end

            describe '#tags' do
              subject { super().tags }
              it { is_expected.to eq(['ts0001', 'ts', '201301', '2']) }
            end
          end
        end

        describe 'pieces' do
          subject { @pack.pieces }

          describe '#count' do
            subject { super().count }
            it { is_expected.to eq(1) }
          end

          describe 'n°1' do
            subject { @pack.pieces.by_position[0] }

            describe '#name' do
              subject { super().name }
              it { is_expected.to eq('TS0001 TS 201301 001') }
            end

            describe '#content_file_name' do
              subject { super().content_file_name }
              it { is_expected.to eq('TS0001_TS_201301_001.pdf') }
            end

            describe '#uploaded?' do
              subject { super().uploaded? }
              it { is_expected.to eq(false) }
            end

            describe '#is_a_cover' do
              subject { super().is_a_cover }
              it { is_expected.to eq(false) }
            end

            describe '#position' do
              subject { super().position }
              it { is_expected.to eq(1) }
            end
          end
        end
      end
    end

    context 'with 2 uploaded files, 2 dematbox scanned files, 1 cover scanned file and 1 scanned file' do
      before(:all) do
        # 2 uploaded files
        UploadedDocument.new @upload_file, "upload_with_1_page.pdf", @user, 'TS', 0
        UploadedDocument.new @file_with_2_pages, "upload_with_2_pages.pdf", @user, 'TS', 0

        params = {
          'virtual_box_id' => 'TS0001',
          'service_id' => '1',
          'improved_scan' => @content64,
          'doc_id' => '1',
          'box_id' => '1',
          'text' => nil
        }

        # 2 dematbox scanned files
        dematbox = Dematbox.new
        dematbox.user = @user
        service = DematboxSubscribedService.new
        service.pid = '1'
        service.is_for_current_period = true
        service.name = 'TS'
        dematbox.services << service
        dematbox.save

        CreateDematboxDocument.new(params).execute

        params2 = {
          'virtual_box_id' => 'TS0001',
          'service_id' => '1',
          'improved_scan' => @content64,
          'doc_id' => '2',
          'box_id' => '1',
          'text' => nil
        }

        CreateDematboxDocument.new(params2).execute

        # 1 cover scanned file and 1 scanned file
        Dir.mktmpdir do |dir|
          @temp_pack = TempPack.find_or_create_by_name 'TS0001 TS 201301 all'

          2.times do |i|
            file_name = "TS0001_TS_201301_00#{i}.pdf"
            file_path = File.join(dir, file_name)
            FileUtils.cp @file_with_2_pages, file_path
            temp_document = TempDocument.new

            temp_document.user               = @user
            temp_document.temp_pack          = @temp_pack
            temp_document.original_file_name = file_name
            temp_document.content            = open(file_path)
            temp_document.position           = @temp_pack.next_document_position

            temp_document.delivered_by       = 'ppp'
            temp_document.delivery_type      = 'scan'

            temp_document.save
            temp_document.ready
          end
        end

        AccountingWorkflow::TempPackProcessor.process(@temp_pack)

        @user.reload
        @temp_pack.reload
        @pack = @user.packs.first
      end

      after(:all) do
        TempPack.destroy_all
        Pack.destroy_all
      end

      describe 'temp_pack' do
        subject { @temp_pack }

        describe '#document_not_processed_count' do
          subject { super().document_not_processed_count }
          it { is_expected.to eq(0) }
        end

        describe 'temp_documents' do
          subject { @temp_pack.temp_documents }

          describe '#count' do
            subject { super().count }
            it { is_expected.to eq(6) }
          end
        end
      end

      describe 'pack' do
        subject { @pack }

        it { is_expected.to be_persisted }

        describe '#name' do
          subject { super().name }
          it { is_expected.to eq('TS0001 TS 201301 all') }
        end

        describe '#pages_count' do
          subject { super().pages_count }
          it { is_expected.to eq(11) }
        end

        describe 'global document' do
          subject { @pack.original_document }

          describe '#content_file_name' do
            subject { super().content_file_name }
            it { is_expected.to eq('TS0001_TS_201301_all.pdf') }
          end

          describe '#uploaded?' do
            subject { super().uploaded? }
            it { is_expected.to eq(false) }
          end

          describe '#is_a_cover' do
            subject { super().is_a_cover }
            it { is_expected.to eq(false) }
          end

          describe '#position' do
            subject { super().position }
            it { is_expected.to eq(nil) }
          end

          it 'should have 11 pages' do
            expect(DocumentTools.pages_number(subject.content.path)).to eq(11)
          end
        end

        describe 'dividers' do
          subject { @pack.dividers }

          describe '#count' do
            subject { super().count }
            it { is_expected.to eq(8) }
          end

          describe 'pieces' do
            before(:all) do
              @pieces = @pack.dividers.pieces.by_position
            end

            subject { @pieces }

            describe '#count' do
              subject { super().count }
              it { is_expected.to eq(6) }
            end

            describe 'n°1' do
              subject { @pieces[0] }

              describe '#name' do
                subject { super().name }
                it { is_expected.to eq 'TS0001_TS_201301_000' }
              end

              describe '#pages_number' do
                subject { super().pages_number }
                it { is_expected.to eq(2) }
              end

              describe '#origin' do
                subject { super().origin }
                it { is_expected.to eq('scan') }
              end

              describe '#is_a_cover' do
                subject { super().is_a_cover }
                it { is_expected.to eq(true) }
              end

              describe '#position' do
                subject { super().position }
                it { is_expected.to eq(0) }
              end
            end

            describe 'n°2' do
              subject { @pieces[1] }

              describe '#name' do
                subject { super().name }
                it { is_expected.to eq 'TS0001_TS_201301_001' }
              end

              describe '#pages_number' do
                subject { super().pages_number }
                it { is_expected.to eq(1) }
              end

              describe '#origin' do
                subject { super().origin }
                it { is_expected.to eq('upload') }
              end

              describe '#is_a_cover' do
                subject { super().is_a_cover }
                it { is_expected.to eq(false) }
              end

              describe '#position' do
                subject { super().position }
                it { is_expected.to eq(1) }
              end
            end

            describe 'n°3' do
              subject { @pieces[2] }

              describe '#name' do
                subject { super().name }
                it { is_expected.to eq 'TS0001_TS_201301_002' }
              end

              describe '#pages_number' do
                subject { super().pages_number }
                it { is_expected.to eq(2) }
              end

              describe '#origin' do
                subject { super().origin }
                it { is_expected.to eq('upload') }
              end

              describe '#is_a_cover' do
                subject { super().is_a_cover }
                it { is_expected.to eq(false) }
              end

              describe '#position' do
                subject { super().position }
                it { is_expected.to eq(2) }
              end
            end

            describe 'n°4' do
              subject { @pieces[3] }

              describe '#name' do
                subject { super().name }
                it { is_expected.to eq 'TS0001_TS_201301_003' }
              end

              describe '#pages_number' do
                subject { super().pages_number }
                it { is_expected.to eq(2) }
              end

              describe '#origin' do
                subject { super().origin }
                it { is_expected.to eq('dematbox_scan') }
              end

              describe '#is_a_cover' do
                subject { super().is_a_cover }
                it { is_expected.to eq(false) }
              end

              describe '#position' do
                subject { super().position }
                it { is_expected.to eq(3) }
              end
            end

            describe 'n°5' do
              subject { @pieces[4] }

              describe '#name' do
                subject { super().name }
                it { is_expected.to eq 'TS0001_TS_201301_004' }
              end

              describe '#pages_number' do
                subject { super().pages_number }
                it { is_expected.to eq(2) }
              end

              describe '#origin' do
                subject { super().origin }
                it { is_expected.to eq('dematbox_scan') }
              end

              describe '#is_a_cover' do
                subject { super().is_a_cover }
                it { is_expected.to eq(false) }
              end

              describe '#position' do
                subject { super().position }
                it { is_expected.to eq(4) }
              end
            end

            describe 'n°6' do
              subject { @pieces[5] }

              describe '#name' do
                subject { super().name }
                it { is_expected.to eq 'TS0001_TS_201301_005' }
              end

              describe '#pages_number' do
                subject { super().pages_number }
                it { is_expected.to eq(2) }
              end

              describe '#origin' do
                subject { super().origin }
                it { is_expected.to eq('scan') }
              end

              describe '#is_a_cover' do
                subject { super().is_a_cover }
                it { is_expected.to eq(false) }
              end

              describe '#position' do
                subject { super().position }
                it { is_expected.to eq(5) }
              end
            end
          end

          describe 'sheets' do
            before(:all) do
              @sheets = @pack.dividers.sheets.by_position
            end

            subject { @sheets }

            describe '#count' do
              subject { super().count }
              it { is_expected.to eq(2) }
            end

            describe 'n°1' do
              subject { @sheets[0] }

              describe '#name' do
                subject { super().name }
                it { is_expected.to eq 'TS0001_TS_201301_000' }
              end

              describe '#pages_number' do
                subject { super().pages_number }
                it { is_expected.to eq(2) }
              end

              describe '#origin' do
                subject { super().origin }
                it { is_expected.to eq('scan') }
              end

              describe '#is_a_cover' do
                subject { super().is_a_cover }
                it { is_expected.to eq(true) }
              end

              describe '#position' do
                subject { super().position }
                it { is_expected.to eq(0) }
              end
            end

            describe 'n°2' do
              subject { @sheets[1] }

              describe '#name' do
                subject { super().name }
                it { is_expected.to eq 'TS0001_TS_201301_001' }
              end

              describe '#pages_number' do
                subject { super().pages_number }
                it { is_expected.to eq(2) }
              end

              describe '#origin' do
                subject { super().origin }
                it { is_expected.to eq('scan') }
              end

              describe '#is_a_cover' do
                subject { super().is_a_cover }
                it { is_expected.to eq(false) }
              end

              describe '#position' do
                subject { super().position }
                it { is_expected.to eq(1) }
              end
            end
          end
        end

        describe 'pages' do
          subject { @pack.pages }

          describe '#count' do
            subject { super().count }
            it { is_expected.to eq(11) }
          end

          describe 'n°1' do
            subject { @pack.pages.by_position[0] }

            describe '#content_file_name' do
              subject { super().content_file_name }
              it { is_expected.to eq('TS0001_TS_201301_cover_page_001.pdf') }
            end

            describe '#position' do
              subject { super().position }
              it { is_expected.to eq(-2) }
            end

            describe '#mixed?' do
              subject { super().mixed? }
              it { is_expected.to eq(false) }
            end

            describe '#uploaded?' do
              subject { super().uploaded? }
              it { is_expected.to eq(false) }
            end

            describe '#is_a_cover' do
              subject { super().is_a_cover }
              it { is_expected.to eq(true) }
            end

            describe '#tags' do
              subject { super().tags }
              it { is_expected.to eq(['ts0001', 'ts', '201301', '1']) }
            end
          end

          describe 'n°2' do
            subject { @pack.pages.by_position[1] }

            describe '#content_file_name' do
              subject { super().content_file_name }
              it { is_expected.to eq('TS0001_TS_201301_cover_page_002.pdf') }
            end

            describe '#position' do
              subject { super().position }
              it { is_expected.to eq(-1) }
            end

            describe '#mixed?' do
              subject { super().mixed? }
              it { is_expected.to eq(false) }
            end

            describe '#uploaded?' do
              subject { super().uploaded? }
              it { is_expected.to eq(false) }
            end

            describe '#is_a_cover' do
              subject { super().is_a_cover }
              it { is_expected.to eq(true) }
            end

            describe '#tags' do
              subject { super().tags }
              it { is_expected.to eq(['ts0001', 'ts', '201301', '2']) }
            end
          end

          describe 'n°3' do
            subject { @pack.pages.by_position[2] }

            describe '#content_file_name' do
              subject { super().content_file_name }
              it { is_expected.to eq('TS0001_TS_201301_page_001.pdf') }
            end

            describe '#position' do
              subject { super().position }
              it { is_expected.to eq(0) }
            end

            describe '#mixed?' do
              subject { super().mixed? }
              it { is_expected.to eq(false) }
            end

            describe '#uploaded?' do
              subject { super().uploaded? }
              it { is_expected.to eq(true) }
            end

            describe '#is_a_cover' do
              subject { super().is_a_cover }
              it { is_expected.to eq(false) }
            end

            describe '#tags' do
              subject { super().tags }
              it { is_expected.to eq(['ts0001', 'ts', '201301', '1']) }
            end
          end

          describe 'n°4' do
            subject { @pack.pages.by_position[3] }

            describe '#content_file_name' do
              subject { super().content_file_name }
              it { is_expected.to eq('TS0001_TS_201301_page_002.pdf') }
            end

            describe '#position' do
              subject { super().position }
              it { is_expected.to eq(1) }
            end

            describe '#mixed?' do
              subject { super().mixed? }
              it { is_expected.to eq(false) }
            end

            describe '#uploaded?' do
              subject { super().uploaded? }
              it { is_expected.to eq(true) }
            end

            describe '#is_a_cover' do
              subject { super().is_a_cover }
              it { is_expected.to eq(false) }
            end

            describe '#tags' do
              subject { super().tags }
              it { is_expected.to eq(['ts0001', 'ts', '201301', '2']) }
            end
          end

          describe 'n°5' do
            subject { @pack.pages.by_position[4] }

            describe '#content_file_name' do
              subject { super().content_file_name }
              it { is_expected.to eq('TS0001_TS_201301_page_003.pdf') }
            end

            describe '#position' do
              subject { super().position }
              it { is_expected.to eq(2) }
            end

            describe '#mixed?' do
              subject { super().mixed? }
              it { is_expected.to eq(false) }
            end

            describe '#uploaded?' do
              subject { super().uploaded? }
              it { is_expected.to eq(true) }
            end

            describe '#is_a_cover' do
              subject { super().is_a_cover }
              it { is_expected.to eq(false) }
            end

            describe '#tags' do
              subject { super().tags }
              it { is_expected.to eq(['ts0001', 'ts', '201301', '3']) }
            end
          end

          describe 'n°6' do
            subject { @pack.pages.by_position[5] }

            describe '#content_file_name' do
              subject { super().content_file_name }
              it { is_expected.to eq('TS0001_TS_201301_page_004.pdf') }
            end

            describe '#position' do
              subject { super().position }
              it { is_expected.to eq(3) }
            end

            describe '#mixed?' do
              subject { super().mixed? }
              it { is_expected.to eq(false) }
            end

            describe '#uploaded?' do
              subject { super().uploaded? }
              it { is_expected.to eq(false) }
            end

            describe '#is_a_cover' do
              subject { super().is_a_cover }
              it { is_expected.to eq(false) }
            end

            describe '#tags' do
              subject { super().tags }
              it { is_expected.to eq(['ts0001', 'ts', '201301', '4']) }
            end
          end

          describe 'n°7' do
            subject { @pack.pages.by_position[6] }

            describe '#content_file_name' do
              subject { super().content_file_name }
              it { is_expected.to eq('TS0001_TS_201301_page_005.pdf') }
            end

            describe '#position' do
              subject { super().position }
              it { is_expected.to eq(4) }
            end

            describe '#mixed?' do
              subject { super().mixed? }
              it { is_expected.to eq(false) }
            end

            describe '#uploaded?' do
              subject { super().uploaded? }
              it { is_expected.to eq(false) }
            end

            describe '#is_a_cover' do
              subject { super().is_a_cover }
              it { is_expected.to eq(false) }
            end

            describe '#tags' do
              subject { super().tags }
              it { is_expected.to eq(['ts0001', 'ts', '201301', '5']) }
            end
          end

          describe 'n°8' do
            subject { @pack.pages.by_position[7] }

            describe '#content_file_name' do
              subject { super().content_file_name }
              it { is_expected.to eq('TS0001_TS_201301_page_006.pdf') }
            end

            describe '#position' do
              subject { super().position }
              it { is_expected.to eq(5) }
            end

            describe '#mixed?' do
              subject { super().mixed? }
              it { is_expected.to eq(false) }
            end

            describe '#uploaded?' do
              subject { super().uploaded? }
              it { is_expected.to eq(false) }
            end

            describe '#is_a_cover' do
              subject { super().is_a_cover }
              it { is_expected.to eq(false) }
            end

            describe '#tags' do
              subject { super().tags }
              it { is_expected.to eq(['ts0001', 'ts', '201301', '6']) }
            end
          end

          describe 'n°9' do
            subject { @pack.pages.by_position[8] }

            describe '#content_file_name' do
              subject { super().content_file_name }
              it { is_expected.to eq('TS0001_TS_201301_page_007.pdf') }
            end

            describe '#position' do
              subject { super().position }
              it { is_expected.to eq(6) }
            end

            describe '#mixed?' do
              subject { super().mixed? }
              it { is_expected.to eq(false) }
            end

            describe '#uploaded?' do
              subject { super().uploaded? }
              it { is_expected.to eq(false) }
            end

            describe '#is_a_cover' do
              subject { super().is_a_cover }
              it { is_expected.to eq(false) }
            end

            describe '#tags' do
              subject { super().tags }
              it { is_expected.to eq(['ts0001', 'ts', '201301', '7']) }
            end
          end

          describe 'n°10' do
            subject { @pack.pages.by_position[9] }

            describe '#content_file_name' do
              subject { super().content_file_name }
              it { is_expected.to eq('TS0001_TS_201301_page_008.pdf') }
            end

            describe '#position' do
              subject { super().position }
              it { is_expected.to eq(7) }
            end

            describe '#mixed?' do
              subject { super().mixed? }
              it { is_expected.to eq(false) }
            end

            describe '#uploaded?' do
              subject { super().uploaded? }
              it { is_expected.to eq(false) }
            end

            describe '#is_a_cover' do
              subject { super().is_a_cover }
              it { is_expected.to eq(false) }
            end

            describe '#tags' do
              subject { super().tags }
              it { is_expected.to eq(['ts0001', 'ts', '201301', '8']) }
            end
          end

          describe 'n°11' do
            subject { @pack.pages.by_position[10] }

            describe '#content_file_name' do
              subject { super().content_file_name }
              it { is_expected.to eq('TS0001_TS_201301_page_009.pdf') }
            end

            describe '#position' do
              subject { super().position }
              it { is_expected.to eq(8) }
            end

            describe '#mixed?' do
              subject { super().mixed? }
              it { is_expected.to eq(false) }
            end

            describe '#uploaded?' do
              subject { super().uploaded? }
              it { is_expected.to eq(false) }
            end

            describe '#is_a_cover' do
              subject { super().is_a_cover }
              it { is_expected.to eq(false) }
            end

            describe '#tags' do
              subject { super().tags }
              it { is_expected.to eq(['ts0001', 'ts', '201301', '9']) }
            end
          end
        end

        describe 'pieces' do
          subject { @pack.pieces }

          describe '#count' do
            subject { super().count }
            it { is_expected.to eq(6) }
          end

          describe 'n°1' do
            subject { @pack.pieces.by_position[0] }

            it 'pages number should eq 2' do
              expect(DocumentTools.pages_number(subject.content.path)).to eq(2)
            end

            describe '#name' do
              subject { super().name }
              it { is_expected.to eq('TS0001 TS 201301 000') }
            end

            describe '#content_file_name' do
              subject { super().content_file_name }
              it { is_expected.to eq('TS0001_TS_201301_000.pdf') }
            end

            describe '#uploaded?' do
              subject { super().uploaded? }
              it { is_expected.to eq(false) }
            end

            describe '#is_a_cover' do
              subject { super().is_a_cover }
              it { is_expected.to eq(true) }
            end

            describe '#position' do
              subject { super().position }
              it { is_expected.to eq(0) }
            end
          end

          describe 'n°2' do
            subject { @pack.pieces.by_position[1] }

            it 'pages number should eq 1' do
              expect(DocumentTools.pages_number(subject.content.path)).to eq(1)
            end

            describe '#name' do
              subject { super().name }
              it { is_expected.to eq('TS0001 TS 201301 001') }
            end

            describe '#content_file_name' do
              subject { super().content_file_name }
              it { is_expected.to eq('TS0001_TS_201301_001.pdf') }
            end

            describe '#uploaded?' do
              subject { super().uploaded? }
              it { is_expected.to eq(true) }
            end

            describe '#is_a_cover' do
              subject { super().is_a_cover }
              it { is_expected.to eq(false) }
            end

            describe '#position' do
              subject { super().position }
              it { is_expected.to eq(1) }
            end
          end

          describe 'n°3' do
            subject { @pack.pieces.by_position[2] }

            it 'pages number should eq 2' do
              expect(DocumentTools.pages_number(subject.content.path)).to eq(2)
            end

            describe '#name' do
              subject { super().name }
              it { is_expected.to eq('TS0001 TS 201301 002') }
            end

            describe '#content_file_name' do
              subject { super().content_file_name }
              it { is_expected.to eq('TS0001_TS_201301_002.pdf') }
            end

            describe '#uploaded?' do
              subject { super().uploaded? }
              it { is_expected.to eq(true) }
            end

            describe '#is_a_cover' do
              subject { super().is_a_cover }
              it { is_expected.to eq(false) }
            end

            describe '#position' do
              subject { super().position }
              it { is_expected.to eq(2) }
            end
          end

          describe 'n°4' do
            subject { @pack.pieces.by_position[3] }

            it 'pages number should eq 2' do
              expect(DocumentTools.pages_number(subject.content.path)).to eq(2)
            end

            describe '#name' do
              subject { super().name }
              it { is_expected.to eq('TS0001 TS 201301 003') }
            end

            describe '#content_file_name' do
              subject { super().content_file_name }
              it { is_expected.to eq('TS0001_TS_201301_003.pdf') }
            end

            describe '#uploaded?' do
              subject { super().uploaded? }
              it { is_expected.to eq(false) }
            end

            describe '#is_a_cover' do
              subject { super().is_a_cover }
              it { is_expected.to eq(false) }
            end

            describe '#position' do
              subject { super().position }
              it { is_expected.to eq(3) }
            end
          end

          describe 'n°5' do
            subject { @pack.pieces.by_position[4] }

            it 'pages number should eq 2' do
              expect(DocumentTools.pages_number(subject.content.path)).to eq(2)
            end

            describe '#name' do
              subject { super().name }
              it { is_expected.to eq('TS0001 TS 201301 004') }
            end

            describe '#content_file_name' do
              subject { super().content_file_name }
              it { is_expected.to eq('TS0001_TS_201301_004.pdf') }
            end

            describe '#uploaded?' do
              subject { super().uploaded? }
              it { is_expected.to eq(false) }
            end

            describe '#is_a_cover' do
              subject { super().is_a_cover }
              it { is_expected.to eq(false) }
            end

            describe '#position' do
              subject { super().position }
              it { is_expected.to eq(4) }
            end
          end

          describe 'n°6' do
            subject { @pack.pieces.by_position[5] }

            it 'pages number should eq 2' do
              expect(DocumentTools.pages_number(subject.content.path)).to eq(2)
            end

            describe '#name' do
              subject { super().name }
              it { is_expected.to eq('TS0001 TS 201301 005') }
            end

            describe '#content_file_name' do
              subject { super().content_file_name }
              it { is_expected.to eq('TS0001_TS_201301_005.pdf') }
            end

            describe '#uploaded?' do
              subject { super().uploaded? }
              it { is_expected.to eq(false) }
            end

            describe '#is_a_cover' do
              subject { super().is_a_cover }
              it { is_expected.to eq(false) }
            end

            describe '#position' do
              subject { super().position }
              it { is_expected.to eq(5) }
            end
          end
        end
      end
    end

    context 'with 1 scanned file with preassignment activated' do
      before(:all) do
        @journal.update_attribute(:entry_type, 2)
        @temp_pack = TempPack.find_or_create_by_name 'TS0001 TS 201301 all'
        @temp_pack.user = @user
        @temp_pack.save

        file_name = 'TS0001_TS_201301_001.pdf'
        original_file_path = File.join(Rails.root, 'spec', 'support', 'files', '2pages.pdf')

        ids = 2.times.map do
          temp_document = TempDocument.new
          temp_document.temp_pack          = @temp_pack
          temp_document.user               = @user
          temp_document.original_file_name = file_name
          temp_document.content            = open(original_file_path)
          temp_document.position           = @temp_pack.next_document_position
          temp_document.delivered_by       = 'ppp'
          temp_document.delivery_type      = 'scan'
          temp_document.state              = 'bundled'
          temp_document.pages_number       = 2
          temp_document.save
          temp_document.id
        end

        Dir.mktmpdir do |dir|
          file_path = File.join(dir, file_name)
          Pdftk.new.merge([original_file_path, original_file_path], file_path)

          temp_document_2 = TempDocument.new
          temp_document_2.temp_pack                  = @temp_pack
          temp_document_2.user                       = @user
          temp_document_2.original_file_name         = file_name
          temp_document_2.content                    = open(file_path)
          temp_document_2.position                   = @temp_pack.next_document_position
          temp_document_2.is_an_original             = false
          temp_document_2.scan_bundling_document_ids = ids
          temp_document_2.delivered_by               = 'ppp'
          temp_document_2.delivery_type              = 'scan'
          temp_document_2.pages_number               = 4
          temp_document_2.save
          temp_document_2.ready
        end

        AccountingWorkflow::TempPackProcessor.process(@temp_pack)

        @user.reload
        @temp_pack.reload
        @pack = @user.packs.first
      end

      after(:all) do
        @journal.update_attribute(:entry_type, 0)
        TempPack.destroy_all
        Pack.destroy_all
        FileUtils.remove_entry(Rails.root.join('files/test/prepa_compta/pre_assignments/input/'))
      end

      it 'creates two sheets metadata' do
        expect(@pack.dividers.sheets.count).to eq(2)
        expect(@pack.dividers.sheets.first.position).to eq(1)
        expect(@pack.dividers.sheets.last.position).to eq(2)
      end

      it 'should create file to preassign successfully' do
        file_path = AccountingWorkflow.pre_assignments_dir.join('input', 'AC', 'TS0001_TS_201301_001.pdf')
        expect(File.exist?(file_path)).to be true
      end
    end

    context 'with 2 processing' do
      before(:all) do
        @temp_pack = TempPack.find_or_create_by_name 'TS0001 TS 201301 all'

        Dir.mktmpdir do |dir|
          file_name = 'TS0001_TS_201301_001.pdf'
          file_path = File.join(dir, file_name)
          FileUtils.cp @file_with_2_pages, file_path
          temp_document = TempDocument.new

          temp_document.user               = @user
          temp_document.temp_pack          = @temp_pack
          temp_document.original_file_name = file_name
          temp_document.content            = open(file_path)
          temp_document.position           = @temp_pack.next_document_position

          temp_document.delivered_by       = 'petersbourg'
          temp_document.delivery_type      = 'scan'

          temp_document.save
          temp_document.ready
        end

        AccountingWorkflow::TempPackProcessor.process(@temp_pack)

        Dir.mktmpdir do |dir|
          file_name = 'TS0001_TS_201301_002.pdf'
          file_path = File.join(dir, file_name)
          FileUtils.cp @file_with_2_pages, file_path
          temp_document = TempDocument.new

          temp_document.user               = @user
          temp_document.temp_pack          = @temp_pack
          temp_document.original_file_name = file_name
          temp_document.content            = open(file_path)
          temp_document.position           = @temp_pack.next_document_position

          temp_document.delivered_by       = 'petersbourg'
          temp_document.delivery_type      = 'scan'

          temp_document.save
          temp_document.ready
        end

        AccountingWorkflow::TempPackProcessor.process(@temp_pack)

        @user.reload
        @temp_pack.reload
        @pack = @user.packs.first
      end

      after(:all) do
        TempPack.destroy_all
        Pack.destroy_all
      end

      describe 'temp_pack' do
        subject { @temp_pack }

        describe '#document_not_processed_count' do
          subject { super().document_not_processed_count }
          it { is_expected.to eq(0) }
        end

        describe 'temp_documents' do
          subject { @temp_pack.temp_documents }

          describe '#count' do
            subject { super().count }
            it { is_expected.to eq(2) }
          end
        end
      end

      describe 'pack' do
        subject { @pack }

        it { is_expected.to be_persisted }

        describe '#name' do
          subject { super().name }
          it { is_expected.to eq('TS0001 TS 201301 all') }
        end

        describe 'global document' do
          subject { @pack.original_document }

          describe '#content_file_name' do
            subject { super().content_file_name }
            it { is_expected.to eq('TS0001_TS_201301_all.pdf') }
          end

          describe '#uploaded?' do
            subject { super().uploaded? }
            it { is_expected.to eq(false) }
          end

          describe '#is_a_cover' do
            subject { super().is_a_cover }
            it { is_expected.to eq(false) }
          end

          describe '#position' do
            subject { super().position }
            it { is_expected.to eq(nil) }
          end

          it 'should have 4 pages' do
            expect(DocumentTools.pages_number(subject.content.path)).to eq(4)
          end
        end

        describe 'dividers' do
          subject { @pack.dividers }

          describe '#count' do
            subject { super().count }
            it { is_expected.to eq(4) }
          end

          describe 'pieces' do
            before(:all) do
              @pieces = @pack.dividers.pieces.by_position
            end

            subject { @pieces }

            describe '#count' do
              subject { super().count }
              it { is_expected.to eq(2) }
            end

            describe 'n°1' do
              subject { @pieces[0] }

              describe '#name' do
                subject { super().name }
                it { is_expected.to eq 'TS0001_TS_201301_001' }
              end

              describe '#pages_number' do
                subject { super().pages_number }
                it { is_expected.to eq(2) }
              end

              describe '#origin' do
                subject { super().origin }
                it { is_expected.to eq('scan') }
              end

              describe '#is_a_cover' do
                subject { super().is_a_cover }
                it { is_expected.to eq(false) }
              end

              describe '#position' do
                subject { super().position }
                it { is_expected.to eq(1) }
              end
            end

            describe 'n°2' do
              subject { @pieces[1] }

              describe '#name' do
                subject { super().name }
                it { is_expected.to eq 'TS0001_TS_201301_002' }
              end

              describe '#pages_number' do
                subject { super().pages_number }
                it { is_expected.to eq(2) }
              end

              describe '#origin' do
                subject { super().origin }
                it { is_expected.to eq('scan') }
              end

              describe '#is_a_cover' do
                subject { super().is_a_cover }
                it { is_expected.to eq(false) }
              end

              describe '#position' do
                subject { super().position }
                it { is_expected.to eq(2) }
              end
            end
          end

          describe 'sheets' do
            before(:all) do
              @sheets = @pack.dividers.sheets.by_position
            end

            subject { @sheets }

            describe '#count' do
              subject { super().count }
              it { is_expected.to eq(2) }
            end

            describe 'n°1' do
              subject { @sheets[0] }

              describe '#name' do
                subject { super().name }
                it { is_expected.to eq 'TS0001_TS_201301_001' }
              end

              describe '#pages_number' do
                subject { super().pages_number }
                it { is_expected.to eq(2) }
              end

              describe '#origin' do
                subject { super().origin }
                it { is_expected.to eq('scan') }
              end

              describe '#is_a_cover' do
                subject { super().is_a_cover }
                it { is_expected.to eq(false) }
              end

              describe '#position' do
                subject { super().position }
                it { is_expected.to eq(1) }
              end
            end

            describe 'n°2' do
              subject { @sheets[1] }

              describe '#name' do
                subject { super().name }
                it { is_expected.to eq 'TS0001_TS_201301_002' }
              end

              describe '#pages_number' do
                subject { super().pages_number }
                it { is_expected.to eq(2) }
              end

              describe '#origin' do
                subject { super().origin }
                it { is_expected.to eq('scan') }
              end

              describe '#is_a_cover' do
                subject { super().is_a_cover }
                it { is_expected.to eq(false) }
              end

              describe '#position' do
                subject { super().position }
                it { is_expected.to eq(2) }
              end
            end
          end
        end

        describe 'pages' do
          subject { @pack.pages }

          describe '#count' do
            subject { super().count }
            it { is_expected.to eq(4) }
          end

          describe 'n°1' do
            subject { @pack.pages.by_position[0] }

            describe '#content_file_name' do
              subject { super().content_file_name }
              it { is_expected.to eq('TS0001_TS_201301_page_001.pdf') }
            end

            describe '#position' do
              subject { super().position }
              it { is_expected.to eq(0) }
            end

            describe '#mixed?' do
              subject { super().mixed? }
              it { is_expected.to eq(false) }
            end

            describe '#uploaded?' do
              subject { super().uploaded? }
              it { is_expected.to eq(false) }
            end

            describe '#is_a_cover' do
              subject { super().is_a_cover }
              it { is_expected.to eq(false) }
            end

            describe '#tags' do
              subject { super().tags }
              it { is_expected.to eq(['ts0001', 'ts', '201301', '1']) }
            end
          end

          describe 'n°2' do
            subject { @pack.pages.by_position[1] }

            describe '#content_file_name' do
              subject { super().content_file_name }
              it { is_expected.to eq('TS0001_TS_201301_page_002.pdf') }
            end

            describe '#position' do
              subject { super().position }
              it { is_expected.to eq(1) }
            end

            describe '#mixed?' do
              subject { super().mixed? }
              it { is_expected.to eq(false) }
            end

            describe '#uploaded?' do
              subject { super().uploaded? }
              it { is_expected.to eq(false) }
            end

            describe '#is_a_cover' do
              subject { super().is_a_cover }
              it { is_expected.to eq(false) }
            end

            describe '#tags' do
              subject { super().tags }
              it { is_expected.to eq(['ts0001', 'ts', '201301', '2']) }
            end
          end

          describe 'n°3' do
            subject { @pack.pages.by_position[2] }

            describe '#content_file_name' do
              subject { super().content_file_name }
              it { is_expected.to eq('TS0001_TS_201301_page_003.pdf') }
            end

            describe '#position' do
              subject { super().position }
              it { is_expected.to eq(2) }
            end

            describe '#mixed?' do
              subject { super().mixed? }
              it { is_expected.to eq(false) }
            end

            describe '#uploaded?' do
              subject { super().uploaded? }
              it { is_expected.to eq(false) }
            end

            describe '#is_a_cover' do
              subject { super().is_a_cover }
              it { is_expected.to eq(false) }
            end

            describe '#tags' do
              subject { super().tags }
              it { is_expected.to eq(['ts0001', 'ts', '201301', '3']) }
            end
          end

          describe 'n°4' do
            subject { @pack.pages.by_position[3] }

            describe '#content_file_name' do
              subject { super().content_file_name }
              it { is_expected.to eq('TS0001_TS_201301_page_004.pdf') }
            end

            describe '#position' do
              subject { super().position }
              it { is_expected.to eq(3) }
            end

            describe '#mixed?' do
              subject { super().mixed? }
              it { is_expected.to eq(false) }
            end

            describe '#uploaded?' do
              subject { super().uploaded? }
              it { is_expected.to eq(false) }
            end

            describe '#is_a_cover' do
              subject { super().is_a_cover }
              it { is_expected.to eq(false) }
            end

            describe '#tags' do
              subject { super().tags }
              it { is_expected.to eq(['ts0001', 'ts', '201301', '4']) }
            end
          end
        end

        describe 'pieces' do
          subject { @pack.pieces }

          describe '#count' do
            subject { super().count }
            it { is_expected.to eq(2) }
          end

          describe 'n°1' do
            subject { @pack.pieces.by_position[0] }

            describe '#name' do
              subject { super().name }
              it { is_expected.to eq('TS0001 TS 201301 001') }
            end

            describe '#content_file_name' do
              subject { super().content_file_name }
              it { is_expected.to eq('TS0001_TS_201301_001.pdf') }
            end

            describe '#uploaded?' do
              subject { super().uploaded? }
              it { is_expected.to eq(false) }
            end

            describe '#is_a_cover' do
              subject { super().is_a_cover }
              it { is_expected.to eq(false) }
            end

            describe '#position' do
              subject { super().position }
              it { is_expected.to eq(1) }
            end
          end

          describe 'n°2' do
            subject { @pack.pieces.by_position[1] }

            describe '#name' do
              subject { super().name }
              it { is_expected.to eq('TS0001 TS 201301 002') }
            end

            describe '#content_file_name' do
              subject { super().content_file_name }
              it { is_expected.to eq('TS0001_TS_201301_002.pdf') }
            end

            describe '#uploaded?' do
              subject { super().uploaded? }
              it { is_expected.to eq(false) }
            end

            describe '#is_a_cover' do
              subject { super().is_a_cover }
              it { is_expected.to eq(false) }
            end

            describe '#position' do
              subject { super().position }
              it { is_expected.to eq(2) }
            end
          end
        end
      end
    end

    context 'with 2 processing each with 1 cover' do
      before(:all) do
        Dir.mktmpdir do |dir|
          @temp_pack = TempPack.find_or_create_by_name 'TS0001 TS 201301 all'

          2.times do |i|
            file_name = "TS0001_TS_201301_00#{i}.pdf"
            file_path = File.join(dir, file_name)
            FileUtils.cp @file_with_2_pages, file_path
            temp_document = TempDocument.new

            temp_document.user               = @user
            temp_document.temp_pack          = @temp_pack
            temp_document.original_file_name = file_name
            temp_document.content            = open(file_path)
            temp_document.position           = @temp_pack.next_document_position

            temp_document.delivered_by       = 'petersbourg'
            temp_document.delivery_type      = 'scan'

            temp_document.save
            temp_document.ready
          end

          AccountingWorkflow::TempPackProcessor.process(@temp_pack)

          2.times do |i|
            file_name = "TS0001_TS_201301_00#{i}.pdf"
            file_path = File.join(dir, file_name)
            FileUtils.cp @file_with_2_pages, file_path
            temp_document = TempDocument.new

            temp_document.user               = @user
            temp_document.temp_pack          = @temp_pack
            temp_document.original_file_name = file_name
            temp_document.content            = open(file_path)
            temp_document.position           = @temp_pack.next_document_position

            temp_document.delivered_by       = 'petersbourg'
            temp_document.delivery_type      = 'scan'

            temp_document.save
            temp_document.ready
          end

          AccountingWorkflow::TempPackProcessor.process(@temp_pack)
        end

        @user.reload
        @temp_pack.reload
        @pack = @user.packs.first
      end

      after(:all) do
        TempPack.destroy_all
        Pack.destroy_all
      end

      describe 'temp_pack' do
        subject { @temp_pack }

        describe '#document_not_processed_count' do
          subject { super().document_not_processed_count }
          it { is_expected.to eq(0) }
        end

        describe 'temp_documents' do
          subject { @temp_pack.temp_documents }

          describe '#count' do
            subject { super().count }
            it { is_expected.to eq(4) }
          end
        end
      end

      describe 'pack' do
        subject { @pack }

        it { is_expected.to be_persisted }

        describe '#name' do
          subject { super().name }
          it { is_expected.to eq('TS0001 TS 201301 all') }
        end

        describe 'global document' do
          subject { @pack.original_document }

          describe '#content_file_name' do
            subject { super().content_file_name }
            it { is_expected.to eq('TS0001_TS_201301_all.pdf') }
          end

          describe '#uploaded?' do
            subject { super().uploaded? }
            it { is_expected.to eq(false) }
          end

          describe '#is_a_cover' do
            subject { super().is_a_cover }
            it { is_expected.to eq(false) }
          end

          describe '#position' do
            subject { super().position }
            it { is_expected.to eq(nil) }
          end

          it 'should have 6 pages' do
            expect(DocumentTools.pages_number(subject.content.path)).to eq(6)
          end
        end

        describe 'dividers' do
          subject { @pack.dividers }

          describe '#count' do
            subject { super().count }
            it { is_expected.to eq(6) }
          end

          describe 'pieces' do
            before(:all) do
              @pieces = @pack.dividers.pieces.by_position
            end

            subject { @pieces }

            describe '#count' do
              subject { super().count }
              it { is_expected.to eq(3) }
            end

            describe 'n°1' do
              subject { @pieces[0] }

              describe '#name' do
                subject { super().name }
                it { is_expected.to eq 'TS0001_TS_201301_000' }
              end

              describe '#pages_number' do
                subject { super().pages_number }
                it { is_expected.to eq(2) }
              end

              describe '#origin' do
                subject { super().origin }
                it { is_expected.to eq('scan') }
              end

              describe '#is_a_cover' do
                subject { super().is_a_cover }
                it { is_expected.to eq(true) }
              end

              describe '#position' do
                subject { super().position }
                it { is_expected.to eq(0) }
              end
            end

            describe 'n°2' do
              subject { @pieces[1] }

              describe '#name' do
                subject { super().name }
                it { is_expected.to eq 'TS0001_TS_201301_001' }
              end

              describe '#pages_number' do
                subject { super().pages_number }
                it { is_expected.to eq(2) }
              end

              describe '#origin' do
                subject { super().origin }
                it { is_expected.to eq('scan') }
              end

              describe '#is_a_cover' do
                subject { super().is_a_cover }
                it { is_expected.to eq(false) }
              end

              describe '#position' do
                subject { super().position }
                it { is_expected.to eq(1) }
              end
            end

            describe 'n°3' do
              subject { @pieces[2] }

              describe '#name' do
                subject { super().name }
                it { is_expected.to eq 'TS0001_TS_201301_002' }
              end

              describe '#pages_number' do
                subject { super().pages_number }
                it { is_expected.to eq(2) }
              end

              describe '#origin' do
                subject { super().origin }
                it { is_expected.to eq('scan') }
              end

              describe '#is_a_cover' do
                subject { super().is_a_cover }
                it { is_expected.to eq(false) }
              end

              describe '#position' do
                subject { super().position }
                it { is_expected.to eq(2) }
              end
            end
          end

          describe 'sheets' do
            before(:all) do
              @sheets = @pack.dividers.sheets.by_position
            end

            subject { @sheets }

            describe '#count' do
              subject { super().count }
              it { is_expected.to eq(3) }
            end

            describe 'n°1' do
              subject { @sheets[0] }

              describe '#name' do
                subject { super().name }
                it { is_expected.to eq 'TS0001_TS_201301_000' }
              end

              describe '#pages_number' do
                subject { super().pages_number }
                it { is_expected.to eq(2) }
              end

              describe '#origin' do
                subject { super().origin }
                it { is_expected.to eq('scan') }
              end

              describe '#is_a_cover' do
                subject { super().is_a_cover }
                it { is_expected.to eq(true) }
              end

              describe '#position' do
                subject { super().position }
                it { is_expected.to eq(0) }
              end
            end

            describe 'n°2' do
              subject { @sheets[1] }

              describe '#name' do
                subject { super().name }
                it { is_expected.to eq 'TS0001_TS_201301_001' }
              end

              describe '#pages_number' do
                subject { super().pages_number }
                it { is_expected.to eq(2) }
              end

              describe '#origin' do
                subject { super().origin }
                it { is_expected.to eq('scan') }
              end

              describe '#is_a_cover' do
                subject { super().is_a_cover }
                it { is_expected.to eq(false) }
              end

              describe '#position' do
                subject { super().position }
                it { is_expected.to eq(1) }
              end
            end

            describe 'n°3' do
              subject { @sheets[2] }

              describe '#name' do
                subject { super().name }
                it { is_expected.to eq 'TS0001_TS_201301_002' }
              end

              describe '#pages_number' do
                subject { super().pages_number }
                it { is_expected.to eq(2) }
              end

              describe '#origin' do
                subject { super().origin }
                it { is_expected.to eq('scan') }
              end

              describe '#is_a_cover' do
                subject { super().is_a_cover }
                it { is_expected.to eq(false) }
              end

              describe '#position' do
                subject { super().position }
                it { is_expected.to eq(2) }
              end
            end
          end
        end

        describe 'pages' do
          subject { @pack.pages }

          describe '#count' do
            subject { super().count }
            it { is_expected.to eq(6) }
          end

          describe 'n°1' do
            subject { @pack.pages.by_position[0] }

            describe '#content_file_name' do
              subject { super().content_file_name }
              it { is_expected.to eq('TS0001_TS_201301_cover_page_001.pdf') }
            end

            describe '#position' do
              subject { super().position }
              it { is_expected.to eq(-2) }
            end

            describe '#mixed?' do
              subject { super().mixed? }
              it { is_expected.to eq(false) }
            end

            describe '#uploaded?' do
              subject { super().uploaded? }
              it { is_expected.to eq(false) }
            end

            describe '#is_a_cover' do
              subject { super().is_a_cover }
              it { is_expected.to eq(true) }
            end

            describe '#tags' do
              subject { super().tags }
              it { is_expected.to eq(['ts0001', 'ts', '201301', '1']) }
            end
          end

          describe 'n°2' do
            subject { @pack.pages.by_position[1] }

            describe '#content_file_name' do
              subject { super().content_file_name }
              it { is_expected.to eq('TS0001_TS_201301_cover_page_002.pdf') }
            end

            describe '#position' do
              subject { super().position }
              it { is_expected.to eq(-1) }
            end

            describe '#mixed?' do
              subject { super().mixed? }
              it { is_expected.to eq(false) }
            end

            describe '#uploaded?' do
              subject { super().uploaded? }
              it { is_expected.to eq(false) }
            end

            describe '#is_a_cover' do
              subject { super().is_a_cover }
              it { is_expected.to eq(true) }
            end

            describe '#tags' do
              subject { super().tags }
              it { is_expected.to eq(['ts0001', 'ts', '201301', '2']) }
            end
          end

          describe 'n°3' do
            subject { @pack.pages.by_position[2] }

            describe '#content_file_name' do
              subject { super().content_file_name }
              it { is_expected.to eq('TS0001_TS_201301_page_001.pdf') }
            end

            describe '#position' do
              subject { super().position }
              it { is_expected.to eq(0) }
            end

            describe '#mixed?' do
              subject { super().mixed? }
              it { is_expected.to eq(false) }
            end

            describe '#uploaded?' do
              subject { super().uploaded? }
              it { is_expected.to eq(false) }
            end

            describe '#is_a_cover' do
              subject { super().is_a_cover }
              it { is_expected.to eq(false) }
            end

            describe '#tags' do
              subject { super().tags }
              it { is_expected.to eq(['ts0001', 'ts', '201301', '1']) }
            end
          end

          describe 'n°4' do
            subject { @pack.pages.by_position[3] }

            describe '#content_file_name' do
              subject { super().content_file_name }
              it { is_expected.to eq('TS0001_TS_201301_page_002.pdf') }
            end

            describe '#position' do
              subject { super().position }
              it { is_expected.to eq(1) }
            end

            describe '#mixed?' do
              subject { super().mixed? }
              it { is_expected.to eq(false) }
            end

            describe '#uploaded?' do
              subject { super().uploaded? }
              it { is_expected.to eq(false) }
            end

            describe '#is_a_cover' do
              subject { super().is_a_cover }
              it { is_expected.to eq(false) }
            end

            describe '#tags' do
              subject { super().tags }
              it { is_expected.to eq(['ts0001', 'ts', '201301', '2']) }
            end
          end

          describe 'n°5' do
            subject { @pack.pages.by_position[4] }

            describe '#content_file_name' do
              subject { super().content_file_name }
              it { is_expected.to eq('TS0001_TS_201301_page_003.pdf') }
            end

            describe '#position' do
              subject { super().position }
              it { is_expected.to eq(2) }
            end

            describe '#mixed?' do
              subject { super().mixed? }
              it { is_expected.to eq(false) }
            end

            describe '#uploaded?' do
              subject { super().uploaded? }
              it { is_expected.to eq(false) }
            end

            describe '#is_a_cover' do
              subject { super().is_a_cover }
              it { is_expected.to eq(false) }
            end

            describe '#tags' do
              subject { super().tags }
              it { is_expected.to eq(['ts0001', 'ts', '201301', '3']) }
            end
          end

          describe 'n°6' do
            subject { @pack.pages.by_position[5] }

            describe '#content_file_name' do
              subject { super().content_file_name }
              it { is_expected.to eq('TS0001_TS_201301_page_004.pdf') }
            end

            describe '#position' do
              subject { super().position }
              it { is_expected.to eq(3) }
            end

            describe '#mixed?' do
              subject { super().mixed? }
              it { is_expected.to eq(false) }
            end

            describe '#uploaded?' do
              subject { super().uploaded? }
              it { is_expected.to eq(false) }
            end

            describe '#is_a_cover' do
              subject { super().is_a_cover }
              it { is_expected.to eq(false) }
            end

            describe '#tags' do
              subject { super().tags }
              it { is_expected.to eq(['ts0001', 'ts', '201301', '4']) }
            end
          end
        end

        describe 'pieces' do
          subject { @pack.pieces }

          describe '#count' do
            subject { super().count }
            it { is_expected.to eq(3) }
          end

          describe 'n°1' do
            subject { @pack.pieces.by_position[0] }

            describe '#name' do
              subject { super().name }
              it { is_expected.to eq('TS0001 TS 201301 000') }
            end

            describe '#content_file_name' do
              subject { super().content_file_name }
              it { is_expected.to eq('TS0001_TS_201301_000.pdf') }
            end

            describe '#uploaded?' do
              subject { super().uploaded? }
              it { is_expected.to eq(false) }
            end

            describe '#is_a_cover' do
              subject { super().is_a_cover }
              it { is_expected.to eq(true) }
            end

            describe '#position' do
              subject { super().position }
              it { is_expected.to eq(0) }
            end
          end

          describe 'n°2' do
            subject { @pack.pieces.by_position[1] }

            describe '#name' do
              subject { super().name }
              it { is_expected.to eq('TS0001 TS 201301 001') }
            end

            describe '#content_file_name' do
              subject { super().content_file_name }
              it { is_expected.to eq('TS0001_TS_201301_001.pdf') }
            end

            describe '#uploaded?' do
              subject { super().uploaded? }
              it { is_expected.to eq(false) }
            end

            describe '#is_a_cover' do
              subject { super().is_a_cover }
              it { is_expected.to eq(false) }
            end

            describe '#position' do
              subject { super().position }
              it { is_expected.to eq(1) }
            end
          end

          describe 'n°3' do
            subject { @pack.pieces.by_position[2] }

            describe '#name' do
              subject { super().name }
              it { is_expected.to eq('TS0001 TS 201301 002') }
            end

            describe '#content_file_name' do
              subject { super().content_file_name }
              it { is_expected.to eq('TS0001_TS_201301_002.pdf') }
            end

            describe '#uploaded?' do
              subject { super().uploaded? }
              it { is_expected.to eq(false) }
            end

            describe '#is_a_cover' do
              subject { super().is_a_cover }
              it { is_expected.to eq(false) }
            end

            describe '#position' do
              subject { super().position }
              it { is_expected.to eq(2) }
            end
          end
        end
      end
    end
  end

  describe '.process for yearly' do
    before(:all) do
      DatabaseCleaner.start
      Timecop.freeze(Time.local(2015,1,1))

      @user = FactoryGirl.create(:user, code: 'TS0001')
      @user.create_notify
      @subscription = Subscription.create(user_id: @user.id, period_duration: 12)
      UpdatePeriod.new(@subscription.current_period).execute
      @journal = @user.account_book_types.create(name: 'TS', description: 'TEST')

      @upload_file = File.open File.join(Rails.root, 'spec', 'support', 'files', 'upload.pdf'), 'r'
      @file_with_2_pages = File.open File.join(Rails.root, 'spec', 'support', 'files', '2pages.pdf'), 'r'
    end

    after(:all) do
      @upload_file.close
      @file_with_2_pages.close
      DatabaseCleaner.clean
      Timecop.return
    end

    context 'with 2 uploaded files' do
      before(:all) do
        UploadedDocument.new @upload_file, "upload_with_1_page.pdf", @user, 'TS', 0
        UploadedDocument.new @file_with_2_pages, "upload_with_2_pages.pdf", @user, 'TS', 0

        @temp_pack = @user.temp_packs.first

        AccountingWorkflow::TempPackProcessor.process(@temp_pack)

        @user.reload
        @temp_pack.reload
        @pack = @user.packs.first
      end

      after(:all) do
        TempPack.destroy_all
        Pack.destroy_all
      end

      describe 'temp_pack' do
        subject { @temp_pack }

        describe '#document_not_processed_count' do
          subject { super().document_not_processed_count }
          it { is_expected.to eq(0) }
        end

        describe 'temp_documents' do
          subject { @temp_pack.temp_documents }

          describe '#count' do
            subject { super().count }
            it { is_expected.to eq(2) }
          end
        end
      end

      describe 'pack' do
        subject { @pack }

        it { is_expected.to be_persisted }

        describe '#name' do
          subject { super().name }
          it { is_expected.to eq('TS0001 TS 2015 all') }
        end

        describe 'global document' do
          subject { @pack.original_document }

          describe '#content_file_name' do
            subject { super().content_file_name }
            it { is_expected.to eq('TS0001_TS_2015_all.pdf') }
          end

          describe '#uploaded?' do
            subject { super().uploaded? }
            it { is_expected.to eq(false) }
          end

          describe '#is_a_cover' do
            subject { super().is_a_cover }
            it { is_expected.to eq(false) }
          end

          describe '#position' do
            subject { super().position }
            it { is_expected.to eq(nil) }
          end

          it 'should have 3 pages' do
            expect(DocumentTools.pages_number(subject.content.path)).to eq(3)
          end
        end

        describe 'dividers' do
          subject { @pack.dividers }

          describe '#count' do
            subject { super().count }
            it { is_expected.to eq(2) }
          end

          describe 'pieces' do
            before(:all) do
              @pieces = @pack.dividers.pieces.by_position
            end

            subject { @pieces }

            describe '#count' do
              subject { super().count }
              it { is_expected.to eq(2) }
            end

            describe 'n°1' do
              subject { @pieces[0] }

              describe '#name' do
                subject { super().name }
                it { is_expected.to eq 'TS0001_TS_2015_001' }
              end

              describe '#pages_number' do
                subject { super().pages_number }
                it { is_expected.to eq(1) }
              end

              describe '#origin' do
                subject { super().origin }
                it { is_expected.to eq('upload') }
              end

              describe '#is_a_cover' do
                subject { super().is_a_cover }
                it { is_expected.to eq(false) }
              end

              describe '#position' do
                subject { super().position }
                it { is_expected.to eq(1) }
              end
            end

            describe 'n°2' do
              subject { @pieces[1] }

              describe '#name' do
                subject { super().name }
                it { is_expected.to eq 'TS0001_TS_2015_002' }
              end

              describe '#pages_number' do
                subject { super().pages_number }
                it { is_expected.to eq(2) }
              end

              describe '#origin' do
                subject { super().origin }
                it { is_expected.to eq('upload') }
              end

              describe '#is_a_cover' do
                subject { super().is_a_cover }
                it { is_expected.to eq(false) }
              end

              describe '#position' do
                subject { super().position }
                it { is_expected.to eq(2) }
              end
            end
          end
        end

        describe 'pages' do
          subject { @pack.pages }

          describe '#count' do
            subject { super().count }
            it { is_expected.to eq(3) }
          end

          describe 'n°1' do
            subject { @pack.pages.by_position[0] }

            describe '#content_file_name' do
              subject { super().content_file_name }
              it { is_expected.to eq('TS0001_TS_2015_page_001.pdf') }
            end

            describe '#position' do
              subject { super().position }
              it { is_expected.to eq(0) }
            end

            describe '#mixed?' do
              subject { super().mixed? }
              it { is_expected.to eq(false) }
            end

            describe '#uploaded?' do
              subject { super().uploaded? }
              it { is_expected.to eq(true) }
            end

            describe '#is_a_cover' do
              subject { super().is_a_cover }
              it { is_expected.to eq(false) }
            end

            describe '#tags' do
              subject { super().tags }
              it { is_expected.to eq(['ts0001', 'ts', '2015', '1']) }
            end
          end

          describe 'n°2' do
            subject { @pack.pages.by_position[1] }

            describe '#content_file_name' do
              subject { super().content_file_name }
              it { is_expected.to eq('TS0001_TS_2015_page_002.pdf') }
            end

            describe '#position' do
              subject { super().position }
              it { is_expected.to eq(1) }
            end

            describe '#mixed?' do
              subject { super().mixed? }
              it { is_expected.to eq(false) }
            end

            describe '#uploaded?' do
              subject { super().uploaded? }
              it { is_expected.to eq(true) }
            end

            describe '#is_a_cover' do
              subject { super().is_a_cover }
              it { is_expected.to eq(false) }
            end

            describe '#tags' do
              subject { super().tags }
              it { is_expected.to eq(['ts0001', 'ts', '2015', '2']) }
            end
          end

          describe 'n°3' do
            subject { @pack.pages.by_position[2] }

            describe '#content_file_name' do
              subject { super().content_file_name }
              it { is_expected.to eq('TS0001_TS_2015_page_003.pdf') }
            end

            describe '#position' do
              subject { super().position }
              it { is_expected.to eq(2) }
            end

            describe '#mixed?' do
              subject { super().mixed? }
              it { is_expected.to eq(false) }
            end

            describe '#uploaded?' do
              subject { super().uploaded? }
              it { is_expected.to eq(true) }
            end

            describe '#is_a_cover' do
              subject { super().is_a_cover }
              it { is_expected.to eq(false) }
            end

            describe '#tags' do
              subject { super().tags }
              it { is_expected.to eq(['ts0001', 'ts', '2015', '3']) }
            end
          end
        end

        describe 'pieces' do
          subject { @pack.pieces }

          describe '#count' do
            subject { super().count }
            it { is_expected.to eq(2) }
          end

          describe 'n°1' do
            subject { @pack.pieces.by_position[0] }

            describe '#name' do
              subject { super().name }
              it { is_expected.to eq('TS0001 TS 2015 001') }
            end

            describe '#content_file_name' do
              subject { super().content_file_name }
              it { is_expected.to eq('TS0001_TS_2015_001.pdf') }
            end

            describe '#uploaded?' do
              subject { super().uploaded? }
              it { is_expected.to eq(true) }
            end

            describe '#is_a_cover' do
              subject { super().is_a_cover }
              it { is_expected.to eq(false) }
            end

            describe '#position' do
              subject { super().position }
              it { is_expected.to eq(1) }
            end
          end

          describe 'n°2' do
            subject { @pack.pieces.by_position[1] }

            describe '#name' do
              subject { super().name }
              it { is_expected.to eq('TS0001 TS 2015 002') }
            end

            describe '#content_file_name' do
              subject { super().content_file_name }
              it { is_expected.to eq('TS0001_TS_2015_002.pdf') }
            end

            describe '#uploaded?' do
              subject { super().uploaded? }
              it { is_expected.to eq(true) }
            end

            describe '#is_a_cover' do
              subject { super().is_a_cover }
              it { is_expected.to eq(false) }
            end

            describe '#position' do
              subject { super().position }
              it { is_expected.to eq(2) }
            end
          end
        end
      end
    end
  end
end
