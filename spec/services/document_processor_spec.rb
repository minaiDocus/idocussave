# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe DocumentProcessor do
  describe '.process' do
    before(:all) do
      Timecop.freeze(Time.local(2013,1,1))

      @user = FactoryGirl.create(:user, code: 'TS0001')
      journal = AccountBookType.create(name: 'TS', description: 'TEST')
      journal.clients << @user

      @upload_file = File.open File.join(Rails.root, 'spec', 'support', 'files', 'upload.pdf'), 'r'
      @file_with_2_pages = File.open File.join(Rails.root, 'spec', 'support', 'files', '2pages.pdf'), 'r'
      @content64 = Base64::encode64(@file_with_2_pages.readlines.join)
    end

    after(:all) do
      @upload_file.close
      @file_with_2_pages.close
      Timecop.return
    end

    context 'with 2 uploaded files' do
      before(:all) do
        UploadedDocument.new @upload_file, "upload_with_1_page.pdf", @user, 'TS', true
        UploadedDocument.new @file_with_2_pages, "upload_with_2_pages.pdf", @user, 'TS', true

        DocumentProcessor.process
        @user.reload
        @pack = @user.packs.first
        @temp_pack = TempPack.where(name: @pack.name).first
      end

      after(:all) do
        TempPack.destroy_all
        Pack.destroy_all
      end

      describe 'temp_pack' do
        subject { @temp_pack }

        its(:document_not_processed_count) { should eq(0) }

        describe 'temp_documents' do
          subject { @temp_pack.temp_documents }

          its(:count) { should eq(2) }
        end
      end

      describe 'pack' do
        subject { @pack }

        it { should be_persisted }
        its(:name) { should eq('TS0001 TS 201301 all') }

        describe 'global document' do
          subject { @pack.original_document }

          its(:content_file_name) { should eq('TS0001_TS_201301_all.pdf') }
          its(:uploaded?) { should == false }
          its(:is_a_cover) { should == false }
          its(:position) { should eq(nil) }

          it 'should have 3 pages' do
            expect(DocumentTools.pages_number(subject.content.path)).to eq(3)
          end
        end

        describe 'dividers' do
          subject { @pack.dividers }

          its(:count) { should eq(2) }

          describe 'pieces' do
            before(:all) do
              @pieces = @pack.dividers.pieces.by_position
            end

            subject { @pieces }

            its(:count) { should eq(2) }

            describe 'n°1' do
              subject { @pieces[0] }

              its(:name) { should eq 'TS0001_TS_201301_001' }
              its(:pages_number) { should eq(1) }
              its(:origin) { should eq('upload') }
              its(:is_a_cover) { should == false }
              its(:position) { should eq(1) }
            end

            describe 'n°2' do
              subject { @pieces[1] }

              its(:name) { should eq 'TS0001_TS_201301_002' }
              its(:pages_number) { should eq(2) }
              its(:origin) { should eq('upload') }
              its(:is_a_cover) { should == false }
              its(:position) { should eq(2) }
            end
          end
        end

        describe 'pages' do
          subject { @pack.pages }

          its(:count) { should eq(3) }

          describe 'n°1' do
            subject { @pack.pages.by_position[0] }

            its(:content_file_name) { should eq('TS0001_TS_201301_page_001.pdf') }
            its(:position) { should eq(0) }
            its(:mixed?) { should == false }
            its(:uploaded?) { should == true }
            its(:is_a_cover) { should == false }
            its(:tags) { should eq(['ts0001', 'ts', '201301', '1']) }
          end

          describe 'n°2' do
            subject { @pack.pages.by_position[1] }

            its(:content_file_name) { should eq('TS0001_TS_201301_page_002.pdf') }
            its(:position) { should eq(1) }
            its(:mixed?) { should == false }
            its(:uploaded?) { should == true }
            its(:is_a_cover) { should == false }
            its(:tags) { should eq(['ts0001', 'ts', '201301', '2']) }
          end

          describe 'n°3' do
            subject { @pack.pages.by_position[2] }

            its(:content_file_name) { should eq('TS0001_TS_201301_page_003.pdf') }
            its(:position) { should eq(2) }
            its(:mixed?) { should == false }
            its(:uploaded?) { should == true }
            its(:is_a_cover) { should == false }
            its(:tags) { should eq(['ts0001', 'ts', '201301', '3']) }
          end
        end

        describe 'pieces' do
          subject { @pack.pieces }

          its(:count) { should eq(2) }

          describe 'n°1' do
            subject { @pack.pieces.by_position[0] }

            its(:name) { should eq('TS0001 TS 201301 001') }
            its(:content_file_name) { should eq('TS0001_TS_201301_001.pdf') }
            its(:uploaded?) { should == true }
            its(:is_a_cover) { should == false }
            its(:position) { should eq(1) }
          end

          describe 'n°2' do
            subject { @pack.pieces.by_position[1] }

            its(:name) { should eq('TS0001 TS 201301 002') }
            its(:content_file_name) { should eq('TS0001_TS_201301_002.pdf') }
            its(:uploaded?) { should == true }
            its(:is_a_cover) { should == false }
            its(:position) { should eq(2) }
          end
        end
      end
    end

    context 'with 1 cover and 1 scan files current' do
      before(:all) do
        Dir.mktmpdir do |dir|
          temp_pack = TempPack.find_or_create_by_name 'TS0001 TS 201301 all'

          2.times do |i|
            file_name = "TS0001_TS_201301_00#{i}.pdf"
            file_path = File.join(dir, file_name)
            FileUtils.cp @file_with_2_pages, file_path
            temp_document = TempDocument.new

            temp_document.temp_pack          = temp_pack
            temp_document.original_file_name = file_name
            temp_document.content            = open(file_path)
            temp_document.position           = temp_pack.next_document_position

            temp_document.delivered_by       = 'ppp'
            temp_document.delivery_type      = 'scan'

            temp_document.save
            temp_document.ready
          end
        end

        DocumentProcessor.process
        @user.reload
        @pack = @user.packs.first
        @temp_pack = TempPack.where(name: @pack.name).first
      end

      after(:all) do
        TempPack.destroy_all
        Pack.destroy_all
      end

      describe 'temp_pack' do
        subject { @temp_pack }

        its(:document_not_processed_count) { should eq(0) }

        describe 'temp_documents' do
          subject { @temp_pack.temp_documents }

          its(:count) { should eq(2) }
        end
      end

      describe 'pack' do
        subject { @pack }

        it { should be_persisted }
        its(:name) { should eq('TS0001 TS 201301 all') }

        describe 'global document' do
          subject { @pack.original_document }

          its(:content_file_name) { should eq('TS0001_TS_201301_all.pdf') }
          its(:uploaded?) { should == false }
          its(:is_a_cover) { should == false }
          its(:position) { should eq(nil) }

          it 'should have 4 pages' do
            expect(DocumentTools.pages_number(subject.content.path)).to eq(4)
          end
        end

        describe 'dividers' do
          subject { @pack.dividers }

          its(:count) { should eq(4) }

          describe 'pieces' do
            before(:all) do
              @pieces = @pack.dividers.pieces.by_position
            end

            subject { @pieces }

            its(:count) { should eq(2) }

            describe 'n°1' do
              subject { @pieces[0] }

              its(:name) { should eq 'TS0001_TS_201301_000' }
              its(:pages_number) { should eq(2) }
              its(:origin) { should eq('scan') }
              its(:is_a_cover) { should == true }
              its(:position) { should eq(0) }
            end

            describe 'n°2' do
              subject { @pieces[1] }

              its(:name) { should eq 'TS0001_TS_201301_001' }
              its(:pages_number) { should eq(2) }
              its(:origin) { should eq('scan') }
              its(:is_a_cover) { should == false }
              its(:position) { should eq(1) }
            end
          end

          describe 'sheets' do
            before(:all) do
              @sheets = @pack.dividers.sheets.by_position
            end

            subject { @sheets }

            its(:count) { should eq(2) }

            describe 'n°1' do
              subject { @sheets[0] }

              its(:name) { should eq 'TS0001_TS_201301_000' }
              its(:pages_number) { should eq(2) }
              its(:origin) { should eq('scan') }
              its(:is_a_cover) { should == true }
              its(:position) { should eq(0) }
            end

            describe 'n°2' do
              subject { @sheets[1] }

              its(:name) { should eq 'TS0001_TS_201301_001' }
              its(:pages_number) { should eq(2) }
              its(:origin) { should eq('scan') }
              its(:is_a_cover) { should == false }
              its(:position) { should eq(1) }
            end
          end
        end

        describe 'pages' do
          subject { @pack.pages }

          its(:count) { should eq(4) }

          describe 'n°1' do
            subject { @pack.pages.by_position[0] }

            its(:content_file_name) { should eq('TS0001_TS_201301_cover_page_001.pdf') }
            its(:position) { should eq(-2) }
            its(:mixed?) { should == false }
            its(:uploaded?) { should == false }
            its(:is_a_cover) { should == true }
            its(:tags) { should eq(['ts0001', 'ts', '201301', '1']) }
          end

          describe 'n°2' do
            subject { @pack.pages.by_position[1] }

            its(:content_file_name) { should eq('TS0001_TS_201301_cover_page_002.pdf') }
            its(:position) { should eq(-1) }
            its(:mixed?) { should == false }
            its(:uploaded?) { should == false }
            its(:is_a_cover) { should == true }
            its(:tags) { should eq(['ts0001', 'ts', '201301', '2']) }
          end

          describe 'n°3' do
            subject { @pack.pages.by_position[2] }

            its(:content_file_name) { should eq('TS0001_TS_201301_page_001.pdf') }
            its(:position) { should eq(0) }
            its(:mixed?) { should == false }
            its(:uploaded?) { should == false }
            its(:is_a_cover) { should == false }
            its(:tags) { should eq(['ts0001', 'ts', '201301', '1']) }
          end

          describe 'n°4' do
            subject { @pack.pages.by_position[3] }

            its(:content_file_name) { should eq('TS0001_TS_201301_page_002.pdf') }
            its(:position) { should eq(1) }
            its(:mixed?) { should == false }
            its(:uploaded?) { should == false }
            its(:is_a_cover) { should == false }
            its(:tags) { should eq(['ts0001', 'ts', '201301', '2']) }
          end
        end

        describe 'pieces' do
          subject { @pack.pieces }

          its(:count) { should eq(2) }

          describe 'n°1' do
            subject { @pack.pieces.by_position[0] }

            its(:name) { should eq('TS0001 TS 201301 000') }
            its(:content_file_name) { should eq('TS0001_TS_201301_000.pdf') }
            its(:uploaded?) { should == false }
            its(:is_a_cover) { should == true }
            its(:position) { should eq(0) }
          end

          describe 'n°2' do
            subject { @pack.pieces.by_position[1] }

            its(:name) { should eq('TS0001 TS 201301 001') }
            its(:content_file_name) { should eq('TS0001_TS_201301_001.pdf') }
            its(:uploaded?) { should == false }
            its(:is_a_cover) { should == false }
            its(:position) { should eq(1) }
          end
        end
      end
    end

    context 'with 1 dematbox scanned files' do
      before(:all) do
        params = {
          'virtual_box_id' => '1',
          'service_id' => '1',
          'improved_scan' => @content64,
          'doc_id' => '1',
          'box_id' => '1',
          'text' => nil
        }

        dematbox = Dematbox.new(number: 1)
        dematbox.user = @user
        service = DematboxSubscribedService.new
        service.pid = '1'
        service.is_for_current_period = true
        service.name = 'TS'
        dematbox.services << service
        dematbox.save

        DematboxDocument.new(params)

        DocumentProcessor.process
        @user.reload
        @pack = @user.packs.first
        @temp_pack = TempPack.where(name: @pack.name).first
      end

      after(:all) do
        TempPack.destroy_all
        Pack.destroy_all
      end

      describe 'temp_pack' do
        subject { @temp_pack }

        its(:document_not_processed_count) { should eq(0) }

        describe 'temp_documents' do
          subject { @temp_pack.temp_documents }

          its(:count) { should eq(1) }
        end
      end

      describe 'pack' do
        subject { @pack }

        it { should be_persisted }
        its(:name) { should eq('TS0001 TS 201301 all') }

        describe 'global document' do
          subject { @pack.original_document }

          its(:content_file_name) { should eq('TS0001_TS_201301_all.pdf') }
          its(:uploaded?) { should == false }
          its(:is_a_cover) { should == false }
          its(:position) { should eq(nil) }

          it 'should have 2 pages' do
            expect(DocumentTools.pages_number(subject.content.path)).to eq(2)
          end
        end

        describe 'dividers' do
          subject { @pack.dividers }

          its(:count) { should eq(1) }

          describe 'pieces' do
            before(:all) do
              @pieces = @pack.dividers.pieces.by_position
            end

            subject { @pieces }

            its(:count) { should eq(1) }

            describe 'n°1' do
              subject { @pieces[0] }

              its(:name) { should eq 'TS0001_TS_201301_001' }
              its(:pages_number) { should eq(2) }
              its(:origin) { should eq('dematbox_scan') }
              its(:is_a_cover) { should == false }
              its(:position) { should eq(1) }
            end
          end
        end

        describe 'pages' do
          subject { @pack.pages }

          its(:count) { should eq(2) }

          describe 'n°1' do
            subject { @pack.pages.by_position[0] }

            its(:content_file_name) { should eq('TS0001_TS_201301_page_001.pdf') }
            its(:position) { should eq(0) }
            its(:mixed?) { should == false }
            its(:uploaded?) { should == false }
            its(:is_a_cover) { should == false }
            its(:tags) { should eq(['ts0001', 'ts', '201301', '1']) }
          end

          describe 'n°2' do
            subject { @pack.pages.by_position[1] }

            its(:content_file_name) { should eq('TS0001_TS_201301_page_002.pdf') }
            its(:position) { should eq(1) }
            its(:mixed?) { should == false }
            its(:uploaded?) { should == false }
            its(:is_a_cover) { should == false }
            its(:tags) { should eq(['ts0001', 'ts', '201301', '2']) }
          end
        end

        describe 'pieces' do
          subject { @pack.pieces }

          its(:count) { should eq(1) }

          describe 'n°1' do
            subject { @pack.pieces.by_position[0] }

            its(:name) { should eq('TS0001 TS 201301 001') }
            its(:content_file_name) { should eq('TS0001_TS_201301_001.pdf') }
            its(:uploaded?) { should == false }
            its(:is_a_cover) { should == false }
            its(:position) { should eq(1) }
          end
        end
      end
    end

    context 'with 2 uploaded files, 2 dematbox scanned files, 1 cover scanned file and 1 scanned file' do
      before(:all) do
        # 2 uploaded files
        UploadedDocument.new @upload_file, "upload_with_1_page.pdf", @user, 'TS', true
        UploadedDocument.new @file_with_2_pages, "upload_with_2_pages.pdf", @user, 'TS', true

        params = {
          'virtual_box_id' => '1',
          'service_id' => '1',
          'improved_scan' => @content64,
          'doc_id' => '1',
          'box_id' => '1',
          'text' => nil
        }

        # 2 dematbox scanned files
        dematbox = Dematbox.new(number: 1)
        dematbox.user = @user
        service = DematboxSubscribedService.new
        service.pid = '1'
        service.is_for_current_period = true
        service.name = 'TS'
        dematbox.services << service
        dematbox.save

        DematboxDocument.new(params)

        params2 = {
          'virtual_box_id' => '1',
          'service_id' => '1',
          'improved_scan' => @content64,
          'doc_id' => '2',
          'box_id' => '1',
          'text' => nil
        }

        DematboxDocument.new(params2)

        # 1 cover scanned file and 1 scanned file
        Dir.mktmpdir do |dir|
          temp_pack = TempPack.find_or_create_by_name 'TS0001 TS 201301 all'

          2.times do |i|
            file_name = "TS0001_TS_201301_00#{i}.pdf"
            file_path = File.join(dir, file_name)
            FileUtils.cp @file_with_2_pages, file_path
            temp_document = TempDocument.new

            temp_document.temp_pack          = temp_pack
            temp_document.original_file_name = file_name
            temp_document.content            = open(file_path)
            temp_document.position           = temp_pack.next_document_position

            temp_document.delivered_by       = 'ppp'
            temp_document.delivery_type      = 'scan'

            temp_document.save
            temp_document.ready
          end
        end

        DocumentProcessor.process
        @user.reload
        @pack = @user.packs.first
        @temp_pack = TempPack.where(name: @pack.name).first
      end

      after(:all) do
        TempPack.destroy_all
        Pack.destroy_all
      end

      describe 'temp_pack' do
        subject { @temp_pack }

        its(:document_not_processed_count) { should eq(0) }

        describe 'temp_documents' do
          subject { @temp_pack.temp_documents }

          its(:count) { should eq(6) }
        end
      end

      describe 'pack' do
        subject { @pack }

        it { should be_persisted }
        its(:name) { should eq('TS0001 TS 201301 all') }
        its(:pages_count) { should eq(11) }
        its(:uploaded_pages_count) { should eq(3) }

        describe 'global document' do
          subject { @pack.original_document }

          its(:content_file_name) { should eq('TS0001_TS_201301_all.pdf') }
          its(:uploaded?) { should == false }
          its(:is_a_cover) { should == false }
          its(:position) { should eq(nil) }

          it 'should have 11 pages' do
            expect(DocumentTools.pages_number(subject.content.path)).to eq(11)
          end
        end

        describe 'dividers' do
          subject { @pack.dividers }

          its(:count) { should eq(8) }

          describe 'pieces' do
            before(:all) do
              @pieces = @pack.dividers.pieces.by_position
            end

            subject { @pieces }

            its(:count) { should eq(6) }

            describe 'n°1' do
              subject { @pieces[0] }

              its(:name) { should eq 'TS0001_TS_201301_000' }
              its(:pages_number) { should eq(2) }
              its(:origin) { should eq('scan') }
              its(:is_a_cover) { should == true }
              its(:position) { should eq(0) }
            end

            describe 'n°2' do
              subject { @pieces[1] }

              its(:name) { should eq 'TS0001_TS_201301_001' }
              its(:pages_number) { should eq(1) }
              its(:origin) { should eq('upload') }
              its(:is_a_cover) { should == false }
              its(:position) { should eq(1) }
            end

            describe 'n°3' do
              subject { @pieces[2] }

              its(:name) { should eq 'TS0001_TS_201301_002' }
              its(:pages_number) { should eq(2) }
              its(:origin) { should eq('upload') }
              its(:is_a_cover) { should == false }
              its(:position) { should eq(2) }
            end

            describe 'n°4' do
              subject { @pieces[3] }

              its(:name) { should eq 'TS0001_TS_201301_003' }
              its(:pages_number) { should eq(2) }
              its(:origin) { should eq('dematbox_scan') }
              its(:is_a_cover) { should == false }
              its(:position) { should eq(3) }
            end

            describe 'n°5' do
              subject { @pieces[4] }

              its(:name) { should eq 'TS0001_TS_201301_004' }
              its(:pages_number) { should eq(2) }
              its(:origin) { should eq('dematbox_scan') }
              its(:is_a_cover) { should == false }
              its(:position) { should eq(4) }
            end

            describe 'n°6' do
              subject { @pieces[5] }

              its(:name) { should eq 'TS0001_TS_201301_005' }
              its(:pages_number) { should eq(2) }
              its(:origin) { should eq('scan') }
              its(:is_a_cover) { should == false }
              its(:position) { should eq(5) }
            end
          end

          describe 'sheets' do
            before(:all) do
              @sheets = @pack.dividers.sheets.by_position
            end

            subject { @sheets }

            its(:count) { should eq(2) }

            describe 'n°1' do
              subject { @sheets[0] }

              its(:name) { should eq 'TS0001_TS_201301_000' }
              its(:pages_number) { should eq(2) }
              its(:origin) { should eq('scan') }
              its(:is_a_cover) { should == true }
              its(:position) { should eq(0) }
            end

            describe 'n°2' do
              subject { @sheets[1] }

              its(:name) { should eq 'TS0001_TS_201301_001' }
              its(:pages_number) { should eq(2) }
              its(:origin) { should eq('scan') }
              its(:is_a_cover) { should == false }
              its(:position) { should eq(1) }
            end
          end
        end

        describe 'pages' do
          subject { @pack.pages }

          its(:count) { should eq(11) }

          describe 'n°1' do
            subject { @pack.pages.by_position[0] }

            its(:content_file_name) { should eq('TS0001_TS_201301_cover_page_001.pdf') }
            its(:position) { should eq(-2) }
            its(:mixed?) { should == false }
            its(:uploaded?) { should == false }
            its(:is_a_cover) { should == true }
            its(:tags) { should eq(['ts0001', 'ts', '201301', '1']) }
          end

          describe 'n°2' do
            subject { @pack.pages.by_position[1] }

            its(:content_file_name) { should eq('TS0001_TS_201301_cover_page_002.pdf') }
            its(:position) { should eq(-1) }
            its(:mixed?) { should == false }
            its(:uploaded?) { should == false }
            its(:is_a_cover) { should == true }
            its(:tags) { should eq(['ts0001', 'ts', '201301', '2']) }
          end

          describe 'n°3' do
            subject { @pack.pages.by_position[2] }

            its(:content_file_name) { should eq('TS0001_TS_201301_page_001.pdf') }
            its(:position) { should eq(0) }
            its(:mixed?) { should == false }
            its(:uploaded?) { should == true }
            its(:is_a_cover) { should == false }
            its(:tags) { should eq(['ts0001', 'ts', '201301', '1']) }
          end

          describe 'n°4' do
            subject { @pack.pages.by_position[3] }

            its(:content_file_name) { should eq('TS0001_TS_201301_page_002.pdf') }
            its(:position) { should eq(1) }
            its(:mixed?) { should == false }
            its(:uploaded?) { should == true }
            its(:is_a_cover) { should == false }
            its(:tags) { should eq(['ts0001', 'ts', '201301', '2']) }
          end

          describe 'n°5' do
            subject { @pack.pages.by_position[4] }

            its(:content_file_name) { should eq('TS0001_TS_201301_page_003.pdf') }
            its(:position) { should eq(2) }
            its(:mixed?) { should == false }
            its(:uploaded?) { should == true }
            its(:is_a_cover) { should == false }
            its(:tags) { should eq(['ts0001', 'ts', '201301', '3']) }
          end

          describe 'n°6' do
            subject { @pack.pages.by_position[5] }

            its(:content_file_name) { should eq('TS0001_TS_201301_page_004.pdf') }
            its(:position) { should eq(3) }
            its(:mixed?) { should == false }
            its(:uploaded?) { should == false }
            its(:is_a_cover) { should == false }
            its(:tags) { should eq(['ts0001', 'ts', '201301', '4']) }
          end

          describe 'n°7' do
            subject { @pack.pages.by_position[6] }

            its(:content_file_name) { should eq('TS0001_TS_201301_page_005.pdf') }
            its(:position) { should eq(4) }
            its(:mixed?) { should == false }
            its(:uploaded?) { should == false }
            its(:is_a_cover) { should == false }
            its(:tags) { should eq(['ts0001', 'ts', '201301', '5']) }
          end

          describe 'n°8' do
            subject { @pack.pages.by_position[7] }

            its(:content_file_name) { should eq('TS0001_TS_201301_page_006.pdf') }
            its(:position) { should eq(5) }
            its(:mixed?) { should == false }
            its(:uploaded?) { should == false }
            its(:is_a_cover) { should == false }
            its(:tags) { should eq(['ts0001', 'ts', '201301', '6']) }
          end

          describe 'n°9' do
            subject { @pack.pages.by_position[8] }

            its(:content_file_name) { should eq('TS0001_TS_201301_page_007.pdf') }
            its(:position) { should eq(6) }
            its(:mixed?) { should == false }
            its(:uploaded?) { should == false }
            its(:is_a_cover) { should == false }
            its(:tags) { should eq(['ts0001', 'ts', '201301', '7']) }
          end

          describe 'n°10' do
            subject { @pack.pages.by_position[9] }

            its(:content_file_name) { should eq('TS0001_TS_201301_page_008.pdf') }
            its(:position) { should eq(7) }
            its(:mixed?) { should == false }
            its(:uploaded?) { should == false }
            its(:is_a_cover) { should == false }
            its(:tags) { should eq(['ts0001', 'ts', '201301', '8']) }
          end

          describe 'n°11' do
            subject { @pack.pages.by_position[10] }

            its(:content_file_name) { should eq('TS0001_TS_201301_page_009.pdf') }
            its(:position) { should eq(8) }
            its(:mixed?) { should == false }
            its(:uploaded?) { should == false }
            its(:is_a_cover) { should == false }
            its(:tags) { should eq(['ts0001', 'ts', '201301', '9']) }
          end
        end

        describe 'pieces' do
          subject { @pack.pieces }

          its(:count) { should eq(6) }

          describe 'n°1' do
            subject { @pack.pieces.by_position[0] }

            it 'pages number should eq 2' do
              expect(DocumentTools.pages_number(subject.content.path)).to eq(2)
            end
            its(:name) { should eq('TS0001 TS 201301 000') }
            its(:content_file_name) { should eq('TS0001_TS_201301_000.pdf') }
            its(:uploaded?) { should == false }
            its(:is_a_cover) { should == true }
            its(:position) { should eq(0) }
          end

          describe 'n°2' do
            subject { @pack.pieces.by_position[1] }

            it 'pages number should eq 1' do
              expect(DocumentTools.pages_number(subject.content.path)).to eq(1)
            end
            its(:name) { should eq('TS0001 TS 201301 001') }
            its(:content_file_name) { should eq('TS0001_TS_201301_001.pdf') }
            its(:uploaded?) { should == true }
            its(:is_a_cover) { should == false }
            its(:position) { should eq(1) }
          end

          describe 'n°3' do
            subject { @pack.pieces.by_position[2] }

            it 'pages number should eq 2' do
              expect(DocumentTools.pages_number(subject.content.path)).to eq(2)
            end
            its(:name) { should eq('TS0001 TS 201301 002') }
            its(:content_file_name) { should eq('TS0001_TS_201301_002.pdf') }
            its(:uploaded?) { should == true }
            its(:is_a_cover) { should == false }
            its(:position) { should eq(2) }
          end

          describe 'n°4' do
            subject { @pack.pieces.by_position[3] }

            it 'pages number should eq 2' do
              expect(DocumentTools.pages_number(subject.content.path)).to eq(2)
            end
            its(:name) { should eq('TS0001 TS 201301 003') }
            its(:content_file_name) { should eq('TS0001_TS_201301_003.pdf') }
            its(:uploaded?) { should == false }
            its(:is_a_cover) { should == false }
            its(:position) { should eq(3) }
          end

          describe 'n°5' do
            subject { @pack.pieces.by_position[4] }

            it 'pages number should eq 2' do
              expect(DocumentTools.pages_number(subject.content.path)).to eq(2)
            end
            its(:name) { should eq('TS0001 TS 201301 004') }
            its(:content_file_name) { should eq('TS0001_TS_201301_004.pdf') }
            its(:uploaded?) { should == false }
            its(:is_a_cover) { should == false }
            its(:position) { should eq(4) }
          end

          describe 'n°6' do
            subject { @pack.pieces.by_position[5] }

            it 'pages number should eq 2' do
              expect(DocumentTools.pages_number(subject.content.path)).to eq(2)
            end
            its(:name) { should eq('TS0001 TS 201301 005') }
            its(:content_file_name) { should eq('TS0001_TS_201301_005.pdf') }
            its(:uploaded?) { should == false }
            its(:is_a_cover) { should == false }
            its(:position) { should eq(5) }
          end
        end
      end
    end
  end
end
