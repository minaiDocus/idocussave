# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe AccountingWorkflow::GroupDocument do
  before(:all) do
    Timecop.freeze(Time.local(2015,1,1,0,1,0))
  end

  after(:all) do
    Timecop.return
  end

  describe '.position' do
    it 'returns 5' do
      result = AccountingWorkflow::GroupDocument.position('TS0001_AC_201501_005.pdf')
      expect(result).to eq 5
    end

    it 'returns 5' do
      result = AccountingWorkflow::GroupDocument.position('TS_0001_AC_201501_005.pdf')
      expect(result).to eq 5
    end

    it 'returns 3' do
      result = AccountingWorkflow::GroupDocument.position('TS0001_AC_201501_003_001.pdf')
      expect(result).to eq 3
    end

    it 'returns 3' do
      result = AccountingWorkflow::GroupDocument.position('TS_0001_AC_201501_003_001.pdf')
      expect(result).to eq 3
    end

    it 'returns 1017' do
      result = AccountingWorkflow::GroupDocument.position('TS_0001_AC_201501_1017_001.pdf')
      expect(result).to eq 1017
    end

    it 'returns nil' do
      result = AccountingWorkflow::GroupDocument.position('TS0001_AC_201501_005_001_001.pdf')
      expect(result).to be_nil
    end
  end

  describe '.basename' do
    it 'returns TS0001 AC 201501' do
      result = AccountingWorkflow::GroupDocument.basename('TS0001_AC_201501_005.pdf')
      expect(result).to eq 'TS0001 AC 201501'
    end

    it 'returns TS0001 AC 201501' do
      result = AccountingWorkflow::GroupDocument.basename('TS0001_AC_201501_1045.pdf')
      expect(result).to eq 'TS0001 AC 201501'
    end

    it 'returns TS%0001 AC 201501' do
      result = AccountingWorkflow::GroupDocument.basename('TS_0001_AC_201501_005.pdf')
      expect(result).to eq 'TS%0001 AC 201501'
    end

    it 'returns TS%0001 AC 201501' do
      result = AccountingWorkflow::GroupDocument.basename('TS_0001_AC_201501_1045.pdf')
      expect(result).to eq 'TS%0001 AC 201501'
    end

    it 'returns TS0001 AC 201501' do
      result = AccountingWorkflow::GroupDocument.basename('TS0001_AC_201501_003_001.pdf')
      expect(result).to eq 'TS0001 AC 201501'
    end

    it 'returns TS0001 AC 201501' do
      result = AccountingWorkflow::GroupDocument.basename('TS0001_AC_201501_1045_001.pdf')
      expect(result).to eq 'TS0001 AC 201501'
    end

    it 'returns TS%0001 AC 201501' do
      result = AccountingWorkflow::GroupDocument.basename('TS_0001_AC_201501_003_001.pdf')
      expect(result).to eq 'TS%0001 AC 201501'
    end

    it 'returns TS%0001 AC 201501' do
      result = AccountingWorkflow::GroupDocument.basename('TS_0001_AC_201501_1045_001.pdf')
      expect(result).to eq 'TS%0001 AC 201501'
    end

    it 'returns nil' do
      result = AccountingWorkflow::GroupDocument.basename('TS0001_AC_201501_005_001_001.pdf')
      expect(result).to be_nil
    end

    it 'returns nil' do
      result = AccountingWorkflow::GroupDocument.basename('TS0001_AC_2015T1_005_001_001.pdf')
      expect(result).to be_nil
    end

    it 'returns nil' do
      result = AccountingWorkflow::GroupDocument.basename('TS0001_AC_2015_005_001_001.pdf')
      expect(result).to be_nil
    end

    it 'returns nil' do
      result = AccountingWorkflow::GroupDocument.basename('TS0001_AC_201501_1005_001_001.pdf')
      expect(result).to be_nil
    end

    it 'returns nil' do
      result = AccountingWorkflow::GroupDocument.basename('TS0001_AC_2015T1_1005_001_001.pdf')
      expect(result).to be_nil
    end

    it 'returns nil' do
      result = AccountingWorkflow::GroupDocument.basename('TS0001_AC_2015_1005_001_001.pdf')
      expect(result).to be_nil
    end

    it 'returns nil' do
      result = AccountingWorkflow::GroupDocument.basename('TS_0001_AC_201501_005_001_001.pdf')
      expect(result).to be_nil
    end

    it 'returns nil' do
      result = AccountingWorkflow::GroupDocument.basename('TS_0001_AC_2015T1_005_001_001.pdf')
      expect(result).to be_nil
    end

    it 'returns nil' do
      result = AccountingWorkflow::GroupDocument.basename('TS_0001_AC_2015_005_001_001.pdf')
      expect(result).to be_nil
    end

    it 'returns nil' do
      result = AccountingWorkflow::GroupDocument.basename('TS_0001_AC_201501_1005_001_001.pdf')
      expect(result).to be_nil
    end

    it 'returns nil' do
      result = AccountingWorkflow::GroupDocument.basename('TS_0001_AC_2015T1_1005_001_001.pdf')
      expect(result).to be_nil
    end

    it 'returns nil' do
      result = AccountingWorkflow::GroupDocument.basename('TS_0001_AC_2015_1005_001_001.pdf')
      expect(result).to be_nil
    end
  end

  describe '.execute' do
    before(:all) do
      @result_file_path = Rails.root.join 'files', 'test', 'prepa_compta', 'grouping', 'result.xml'
      @errors_file_path = Rails.root.join 'files', 'test', 'prepa_compta', 'grouping', 'errors.txt'

      @user = FactoryGirl.create(:user, code: 'TS%0001')
      FactoryGirl.create(:journal_with_preassignment, user_id: @user.id, name: 'AC', description: '( Achat )')
    end

    before(:each) do
      base_path = Rails.root.join 'files', 'test', 'prepa_compta', 'grouping'
      FileUtils.mkdir_p base_path.join('scans')
      FileUtils.mkdir_p base_path.join('dematbox_scans')
      FileUtils.mkdir_p base_path.join('uploads')
      FileUtils.mkdir_p base_path.join('archives')

      @temp_pack = TempPack.find_or_create_by_name 'TS%0001 AC 201501 all'

      @file_with_2_pages_path = Rails.root.join('spec', 'support', 'files', '2pages.pdf')
      @file_with_3_pages_path = Rails.root.join('spec', 'support', 'files', '3pages.pdf')
      @file_with_5_pages_path = Rails.root.join('spec', 'support', 'files', '5pages.pdf')
    end

    after(:each) do
      @temp_pack.destroy
      FileUtils.remove_entry Rails.root.join('files', 'test', 'prepa_compta', 'grouping')
    end

    it 'does nothing' do
      AccountingWorkflow::GroupDocument.execute

      expect(File.exist?(@errors_file_path)).to be_falsy
    end

    context 'with errors' do
      it 'create file errors.txt and remove result.xml' do
        File.write(@result_file_path, 'invalid')
        File.utime(Time.local(2015,1,1), Time.local(2015,1,1), @result_file_path)

        Timecop.freeze(Time.local(2015,1,1))
        AccountingWorkflow::GroupDocument.execute

        expect(File.exist?(@result_file_path)).to be_truthy
        expect(File.exist?(@errors_file_path)).to be_falsy

        Timecop.freeze(Time.local(2015,1,1,0,1,0))
        AccountingWorkflow::GroupDocument.execute

        expect(File.read(@errors_file_path)).to eq 'The document has no document element.'
        expect(File.exist?(@result_file_path)).to be_falsy
      end

      it 'has invalid temp pack name' do
        data = '<?xml version="1.0" encoding="utf-8"?>
          <group_documents>
            <pack name="TS0001_AC_201501">
              <piece number="1" origin="scan">
                <file_name>TS0001_AC_201501_001.pdf</file_name>
                <file_name>TS0001_AC_201501_002.pdf</file_name>
              </piece>
            </pack>
          </group_documents>'
        File.write(@result_file_path, data)
        File.utime(Time.local(2015,1,1), Time.local(2015,1,1), @result_file_path)

        AccountingWorkflow::GroupDocument.execute

        expect(File.read(@errors_file_path)).to eq 'Pack name : "TS0001_AC_201501", unknown.'
      end

      it 'has invalid origin' do
        data = '<?xml version="1.0" encoding="utf-8"?>
          <group_documents>
            <pack name="TS%0001_AC_201501">
              <piece number="1" origin="fake">
                <file_name>TS_0001_AC_201501_001.pdf</file_name>
                <file_name>TS_0001_AC_201501_002.pdf</file_name>
              </piece>
            </pack>
          </group_documents>'
        File.write(@result_file_path, data)
        File.utime(Time.local(2015,1,1), Time.local(2015,1,1), @result_file_path)

        AccountingWorkflow::GroupDocument.execute

        expect(File.read(@errors_file_path)).to eq 'Piece origin : "fake", unknown.'
      end

      it 'does not match origin "scan"' do
        data = '<?xml version="1.0" encoding="utf-8"?>
          <group_documents>
            <pack name="TS%0001_AC_201501">
              <piece number="1" origin="scan">
                <file_name>TS_0001_AC_201501_002_001.pdf</file_name>
              </piece>
            </pack>
          </group_documents>'
        File.write(@result_file_path, data)
        File.utime(Time.local(2015,1,1), Time.local(2015,1,1), @result_file_path)

        AccountingWorkflow::GroupDocument.execute

        error_messages = "File name : \"TS_0001_AC_201501_002_001.pdf\", does not match origin : \"scan\"."
        expect(File.read(@errors_file_path)).to eq error_messages
      end

      it 'does not match origin "upload"' do
        data = '<?xml version="1.0" encoding="utf-8"?>
          <group_documents>
            <pack name="TS%0001_AC_201501">
              <piece number="1" origin="upload">
                <file_name>TS_0001_AC_201501_002.pdf</file_name>
              </piece>
            </pack>
          </group_documents>'
        File.write(@result_file_path, data)
        File.utime(Time.local(2015,1,1), Time.local(2015,1,1), @result_file_path)

        AccountingWorkflow::GroupDocument.execute

        error_messages = "File name : \"TS_0001_AC_201501_002.pdf\", does not match origin : \"upload\"."
        expect(File.read(@errors_file_path)).to eq error_messages
      end

      it 'basename match but position is unknown' do
        data = '<?xml version="1.0" encoding="utf-8"?>
          <group_documents>
            <pack name="TS%0001_AC_201501">
              <piece number="1" origin="scan">
                <file_name>TS_0001_AC_201501_001.pdf</file_name>
                <file_name>TS_0001_AC_201501_002.pdf</file_name>
              </piece>
            </pack>
          </group_documents>'
        File.write(@result_file_path, data)
        File.utime(Time.local(2015,1,1), Time.local(2015,1,1), @result_file_path)

        AccountingWorkflow::GroupDocument.execute

        error_messages = "File name : \"TS_0001_AC_201501_001.pdf\", unknown.\nFile name : \"TS_0001_AC_201501_002.pdf\", unknown."
        expect(File.read(@errors_file_path)).to eq error_messages
      end

      it 'basename does not match but position match' do
        temp_document = TempDocument.new
        temp_document.temp_pack      = @temp_pack
        temp_document.user           = @user
        temp_document.position       = 1
        temp_document.pages_number   = 2
        temp_document.is_an_original = true
        temp_document.is_a_cover     = false
        temp_document.state          = 'bundling'
        temp_document.save

        temp_document = TempDocument.new
        temp_document.temp_pack      = @temp_pack
        temp_document.user           = @user
        temp_document.position       = 2
        temp_document.pages_number   = 2
        temp_document.is_an_original = true
        temp_document.is_a_cover     = false
        temp_document.state          = 'bundling'
        temp_document.save

        data = '<?xml version="1.0" encoding="utf-8"?>
          <group_documents>
            <pack name="TS%0001_AC_201501">
              <piece number="1" origin="scan">
                <file_name>TS0001_AC_201501_001.pdf</file_name>
                <file_name>TS0001_AC_201501_002.pdf</file_name>
              </piece>
            </pack>
          </group_documents>'
        File.write(@result_file_path, data)
        File.utime(Time.local(2015,1,1), Time.local(2015,1,1), @result_file_path)

        AccountingWorkflow::GroupDocument.execute

        error_messages = "File name : \"TS0001_AC_201501_001.pdf\", unknown.\nFile name : \"TS0001_AC_201501_002.pdf\", unknown."
        expect(File.read(@errors_file_path)).to eq error_messages
      end

      it 'file not found' do
        temp_document = TempDocument.new
        temp_document.temp_pack      = @temp_pack
        temp_document.user           = @user
        temp_document.position       = 2
        temp_document.pages_number   = 2
        temp_document.delivered_by   = 'test'
        temp_document.delivery_type  = 'scan'
        temp_document.is_an_original = true
        temp_document.is_a_cover     = false
        temp_document.state          = 'bundling'
        temp_document.save

        data = '<?xml version="1.0" encoding="utf-8"?>
          <group_documents>
            <pack name="TS%0001_AC_201501">
              <piece number="1" origin="scan">
                <file_name>TS_0001_AC_201501_002.pdf</file_name>
              </piece>
            </pack>
          </group_documents>'
        File.write(@result_file_path, data)
        File.utime(Time.local(2015,1,1), Time.local(2015,1,1), @result_file_path)

        AccountingWorkflow::GroupDocument.execute

        error_messages = "File name : \"TS_0001_AC_201501_002.pdf\", not found."
        expect(File.read(@errors_file_path)).to eq error_messages
      end

      it 'has 1 duplicate' do
        data = '<?xml version="1.0" encoding="utf-8"?>
          <group_documents>
            <pack name="TS%0001_AC_201501">
              <piece number="1" origin="scan">
                <file_name>TS_0001_AC_201501_001.pdf</file_name>
                <file_name>TS_0001_AC_201501_002.pdf</file_name>
              </piece>
              <piece number="2" origin="scan">
                <file_name>TS_0001_AC_201501_002.pdf</file_name>
              </piece>
              <piece number="3" origin="scan">
                <file_name>TS_0001_AC_201501_003.pdf</file_name>
              </piece>
            </pack>
          </group_documents>'
        File.write(@result_file_path, data)
        File.utime(Time.local(2015,1,1), Time.local(2015,1,1), @result_file_path)

        AccountingWorkflow::GroupDocument.execute

        error_messages = "File name : 1 duplicate(s)."
        expect(File.read(@errors_file_path)).to eq error_messages
      end

      it 'is already grouped' do
        temp_document = TempDocument.new
        temp_document.temp_pack      = @temp_pack
        temp_document.user           = @user
        temp_document.position       = 2
        temp_document.pages_number   = 2
        temp_document.delivered_by   = 'test'
        temp_document.delivery_type  = 'scan'
        temp_document.is_an_original = true
        temp_document.is_a_cover     = false
        temp_document.state          = 'bundled'
        temp_document.save

        data = '<?xml version="1.0" encoding="utf-8"?>
          <group_documents>
            <pack name="TS%0001_AC_201501">
              <piece number="1" origin="scan">
                <file_name>TS_0001_AC_201501_002.pdf</file_name>
              </piece>
            </pack>
          </group_documents>'
        File.write(@result_file_path, data)
        File.utime(Time.local(2015,1,1), Time.local(2015,1,1), @result_file_path)

        AccountingWorkflow::GroupDocument.execute

        error_messages = "File name : \"TS_0001_AC_201501_002.pdf\", already grouped."
        expect(File.read(@errors_file_path)).to eq error_messages
      end
    end

    context 'without errors' do
      it 'successfully group scanned documents' do
        2.times do |i|
          temp_document = TempDocument.new
          temp_document.temp_pack      = @temp_pack
          temp_document.user           = @user
          temp_document.position       = 1+i
          temp_document.delivered_by   = 'test'
          temp_document.delivery_type  = 'scan'
          temp_document.pages_number   = 2
          temp_document.is_an_original = true
          temp_document.is_a_cover     = false
          temp_document.state          = 'bundling'
          temp_document.save
        end

        @temp_pack.update(position_counter: 2)

        base_path = Rails.root.join('files', 'test', 'prepa_compta', 'grouping', 'scans')
        FileUtils.cp @file_with_2_pages_path, base_path.join('TS_0001_AC_201501_001.pdf')
        FileUtils.cp @file_with_2_pages_path, base_path.join('TS_0001_AC_201501_002.pdf')

        data = '<?xml version="1.0" encoding="utf-8"?>
          <group_documents>
            <pack name="TS%0001_AC_201501">
              <piece number="1" origin="scan">
                <file_name>TS_0001_AC_201501_001.pdf</file_name>
                <file_name>TS_0001_AC_201501_002.pdf</file_name>
              </piece>
            </pack>
          </group_documents>'
        File.write(@result_file_path, data)
        File.utime(Time.local(2015,1,1), Time.local(2015,1,1), @result_file_path)

        AccountingWorkflow::GroupDocument.execute

        new_temp_document = @temp_pack.temp_documents.where(position: 3).first
        expect(File.exist?(@errors_file_path)).to be_falsy
        expect(@temp_pack.temp_documents.count).to eq 3
        expect(@temp_pack.temp_documents.bundled.count).to eq 2
        expect(@temp_pack.temp_documents.ready.count).to eq 1
        expect(DocumentTools.pages_number(new_temp_document.content.path)).to eq 4
        archive_path = Rails.root.join('files', 'test', 'prepa_compta', 'grouping', 'archives', '2015', '01', '01_1')
        expect(File.exist?(archive_path.join('TS_0001_AC_201501_001.pdf'))).to be_truthy
        expect(File.exist?(archive_path.join('TS_0001_AC_201501_002.pdf'))).to be_truthy
        expect(File.exist?(archive_path.join('result.xml'))).to be_truthy
      end

      it 'successfully group uploaded documents' do
        base_path = Rails.root.join('files', 'test', 'prepa_compta', 'grouping', 'uploads')

        [@file_with_3_pages_path, @file_with_5_pages_path].each_with_index do |file_path, index|
          temp_document = TempDocument.new
          temp_document.temp_pack      = @temp_pack
          temp_document.user           = @user
          temp_document.position       = 1+index
          temp_document.delivered_by   = 'test'
          temp_document.delivery_type  = 'upload'
          temp_document.is_an_original = true
          temp_document.is_a_cover     = false
          temp_document.state          = 'bundling'
          temp_document.save

          Pdftk.new.burst file_path, base_path, "TS_0001_AC_201501_00#{1+index}", AccountingWorkflow::TempPackProcessor::POSITION_SIZE
        end

        @temp_pack.update(position_counter: 2)

        data = '<?xml version="1.0" encoding="utf-8"?>
          <group_documents>
            <pack name="TS%0001_AC_201501">
              <piece number="1" origin="upload">
                <file_name>TS_0001_AC_201501_001_001.pdf</file_name>
                <file_name>TS_0001_AC_201501_001_002.pdf</file_name>
              </piece>
              <piece number="2" origin="upload">
                <file_name>TS_0001_AC_201501_001_003.pdf</file_name>
                <file_name>TS_0001_AC_201501_002_001.pdf</file_name>
                <file_name>TS_0001_AC_201501_002_002.pdf</file_name>
                <file_name>TS_0001_AC_201501_002_003.pdf</file_name>
              </piece>
              <piece number="3" origin="upload">
                <file_name>TS_0001_AC_201501_002_004.pdf</file_name>
                <file_name>TS_0001_AC_201501_002_005.pdf</file_name>
              </piece>
            </pack>
          </group_documents>'
        File.write(@result_file_path, data)
        File.utime(Time.local(2015,1,1), Time.local(2015,1,1), @result_file_path)

        AccountingWorkflow::GroupDocument.execute

        document_1 = @temp_pack.temp_documents.where(position: 3).first
        document_2 = @temp_pack.temp_documents.where(position: 4).first
        document_3 = @temp_pack.temp_documents.where(position: 5).first
        expect(File.exist?(@errors_file_path)).to be_falsy
        expect(@temp_pack.temp_documents.count).to eq 5
        expect(@temp_pack.temp_documents.bundled.count).to eq 2
        expect(@temp_pack.temp_documents.ready.count).to eq 3
        expect(DocumentTools.pages_number(document_1.content.path)).to eq 2
        expect(DocumentTools.pages_number(document_2.content.path)).to eq 4
        expect(DocumentTools.pages_number(document_3.content.path)).to eq 2
        archive_path = Rails.root.join('files', 'test', 'prepa_compta', 'grouping', 'archives', '2015', '01', '01_1')
        expect(File.exist?(archive_path.join('TS_0001_AC_201501_001_001.pdf'))).to be_truthy
        expect(File.exist?(archive_path.join('TS_0001_AC_201501_001_002.pdf'))).to be_truthy
        expect(File.exist?(archive_path.join('TS_0001_AC_201501_001_003.pdf'))).to be_truthy
        expect(File.exist?(archive_path.join('TS_0001_AC_201501_002_001.pdf'))).to be_truthy
        expect(File.exist?(archive_path.join('TS_0001_AC_201501_002_002.pdf'))).to be_truthy
        expect(File.exist?(archive_path.join('TS_0001_AC_201501_002_003.pdf'))).to be_truthy
        expect(File.exist?(archive_path.join('TS_0001_AC_201501_002_004.pdf'))).to be_truthy
        expect(File.exist?(archive_path.join('TS_0001_AC_201501_002_005.pdf'))).to be_truthy
        expect(File.exist?(archive_path.join('result.xml'))).to be_truthy
      end

      it 'successfully group uploaded documents with 4 digit numbering of files' do
        base_path = Rails.root.join('files', 'test', 'prepa_compta', 'grouping', 'uploads')

        [@file_with_3_pages_path, @file_with_5_pages_path].each_with_index do |file_path, index|
          temp_document = TempDocument.new
          temp_document.temp_pack      = @temp_pack
          temp_document.user           = @user
          temp_document.position       = 1001+index
          temp_document.delivered_by   = 'test'
          temp_document.delivery_type  = 'upload'
          temp_document.is_an_original = true
          temp_document.is_a_cover     = false
          temp_document.state          = 'bundling'
          temp_document.save

          Pdftk.new.burst file_path, base_path, "TS_0001_AC_201501_100#{1+index}", AccountingWorkflow::TempPackProcessor::POSITION_SIZE
        end

        @temp_pack.update(position_counter: 1002)

        data = '<?xml version="1.0" encoding="utf-8"?>
          <group_documents>
            <pack name="TS%0001_AC_201501">
              <piece number="1" origin="upload">
                <file_name>TS_0001_AC_201501_1001_001.pdf</file_name>
                <file_name>TS_0001_AC_201501_1001_002.pdf</file_name>
              </piece>
              <piece number="2" origin="upload">
                <file_name>TS_0001_AC_201501_1001_003.pdf</file_name>
                <file_name>TS_0001_AC_201501_1002_001.pdf</file_name>
                <file_name>TS_0001_AC_201501_1002_002.pdf</file_name>
                <file_name>TS_0001_AC_201501_1002_003.pdf</file_name>
              </piece>
              <piece number="3" origin="upload">
                <file_name>TS_0001_AC_201501_1002_004.pdf</file_name>
                <file_name>TS_0001_AC_201501_1002_005.pdf</file_name>
              </piece>
            </pack>
          </group_documents>'
        File.write(@result_file_path, data)
        File.utime(Time.local(2015,1,1), Time.local(2015,1,1), @result_file_path)

        AccountingWorkflow::GroupDocument.execute

        document_1 = @temp_pack.temp_documents.where(position: 1003).first
        document_2 = @temp_pack.temp_documents.where(position: 1004).first
        document_3 = @temp_pack.temp_documents.where(position: 1005).first
        expect(File.exist?(@errors_file_path)).to be_falsy
        expect(@temp_pack.temp_documents.count).to eq 5
        expect(@temp_pack.temp_documents.bundled.count).to eq 2
        expect(@temp_pack.temp_documents.ready.count).to eq 3
        expect(DocumentTools.pages_number(document_1.content.path)).to eq 2
        expect(DocumentTools.pages_number(document_2.content.path)).to eq 4
        expect(DocumentTools.pages_number(document_3.content.path)).to eq 2
        archive_path = Rails.root.join('files', 'test', 'prepa_compta', 'grouping', 'archives', '2015', '01', '01_1')
        expect(File.exist?(archive_path.join('TS_0001_AC_201501_1001_001.pdf'))).to be_truthy
        expect(File.exist?(archive_path.join('TS_0001_AC_201501_1001_002.pdf'))).to be_truthy
        expect(File.exist?(archive_path.join('TS_0001_AC_201501_1001_003.pdf'))).to be_truthy
        expect(File.exist?(archive_path.join('TS_0001_AC_201501_1002_001.pdf'))).to be_truthy
        expect(File.exist?(archive_path.join('TS_0001_AC_201501_1002_002.pdf'))).to be_truthy
        expect(File.exist?(archive_path.join('TS_0001_AC_201501_1002_003.pdf'))).to be_truthy
        expect(File.exist?(archive_path.join('TS_0001_AC_201501_1002_004.pdf'))).to be_truthy
        expect(File.exist?(archive_path.join('TS_0001_AC_201501_1002_005.pdf'))).to be_truthy
        expect(File.exist?(archive_path.join('result.xml'))).to be_truthy
      end

      it 'successfully group dematbox scanned documents' do
        base_path = Rails.root.join('files', 'test', 'prepa_compta', 'grouping', 'dematbox_scans')

        [@file_with_3_pages_path, @file_with_5_pages_path].each_with_index do |file_path, index|
          temp_document = TempDocument.new
          temp_document.temp_pack      = @temp_pack
          temp_document.user           = @user
          temp_document.position       = 1+index
          temp_document.delivered_by   = 'test'
          temp_document.delivery_type  = 'dematbox_scan'
          temp_document.is_an_original = true
          temp_document.is_a_cover     = false
          temp_document.state          = 'bundling'
          temp_document.save

          Pdftk.new.burst file_path, base_path, "TS_0001_AC_201501_00#{1+index}", AccountingWorkflow::TempPackProcessor::POSITION_SIZE
        end

        @temp_pack.update(position_counter: 2)

        data = '<?xml version="1.0" encoding="utf-8"?>
          <group_documents>
            <pack name="TS%0001_AC_201501">
              <piece number="1" origin="dematbox_scan">
                <file_name>TS_0001_AC_201501_001_001.pdf</file_name>
                <file_name>TS_0001_AC_201501_001_002.pdf</file_name>
                <file_name>TS_0001_AC_201501_001_003.pdf</file_name>
              </piece>
              <piece number="2" origin="dematbox_scan">
                <file_name>TS_0001_AC_201501_002_001.pdf</file_name>
                <file_name>TS_0001_AC_201501_002_002.pdf</file_name>
                <file_name>TS_0001_AC_201501_002_003.pdf</file_name>
              </piece>
              <piece number="3" origin="dematbox_scan">
                <file_name>TS_0001_AC_201501_002_004.pdf</file_name>
                <file_name>TS_0001_AC_201501_002_005.pdf</file_name>
              </piece>
            </pack>
          </group_documents>'
        File.write(@result_file_path, data)
        File.utime(Time.local(2015,1,1), Time.local(2015,1,1), @result_file_path)

        AccountingWorkflow::GroupDocument.execute

        document_1 = @temp_pack.temp_documents.where(position: 3).first
        document_2 = @temp_pack.temp_documents.where(position: 4).first
        document_3 = @temp_pack.temp_documents.where(position: 5).first
        expect(File.exist?(@errors_file_path)).to be_falsy
        expect(@temp_pack.temp_documents.count).to eq 5
        expect(@temp_pack.temp_documents.bundled.count).to eq 2
        expect(@temp_pack.temp_documents.ready.count).to eq 3
        expect(DocumentTools.pages_number(document_1.content.path)).to eq 3
        expect(DocumentTools.pages_number(document_2.content.path)).to eq 3
        expect(DocumentTools.pages_number(document_3.content.path)).to eq 2
        archive_path = Rails.root.join('files', 'test', 'prepa_compta', 'grouping', 'archives', '2015', '01', '01_1')
        expect(File.exist?(archive_path.join('TS_0001_AC_201501_001_001.pdf'))).to be_truthy
        expect(File.exist?(archive_path.join('TS_0001_AC_201501_001_002.pdf'))).to be_truthy
        expect(File.exist?(archive_path.join('TS_0001_AC_201501_001_003.pdf'))).to be_truthy
        expect(File.exist?(archive_path.join('TS_0001_AC_201501_002_001.pdf'))).to be_truthy
        expect(File.exist?(archive_path.join('TS_0001_AC_201501_002_002.pdf'))).to be_truthy
        expect(File.exist?(archive_path.join('TS_0001_AC_201501_002_003.pdf'))).to be_truthy
        expect(File.exist?(archive_path.join('TS_0001_AC_201501_002_004.pdf'))).to be_truthy
        expect(File.exist?(archive_path.join('TS_0001_AC_201501_002_005.pdf'))).to be_truthy
        expect(File.exist?(archive_path.join('result.xml'))).to be_truthy
      end

      it 'successfully group documents' do
        Timecop.freeze(Time.local(2015,1,2,0,1,0))
        2.times do |i|
          temp_document = TempDocument.new
          temp_document.temp_pack      = @temp_pack
          temp_document.user           = @user
          temp_document.position       = 1+i
          temp_document.delivered_by   = 'test'
          temp_document.delivery_type  = 'scan'
          temp_document.pages_number   = 2
          temp_document.is_an_original = true
          temp_document.is_a_cover     = false
          temp_document.state          = 'bundling'
          temp_document.save
        end
        base_path = Rails.root.join('files', 'test', 'prepa_compta', 'grouping', 'scans')
        FileUtils.cp @file_with_2_pages_path, base_path.join('TS_0001_AC_201501_001.pdf')
        FileUtils.cp @file_with_2_pages_path, base_path.join('TS_0001_AC_201501_002.pdf')

        base_path = Rails.root.join('files', 'test', 'prepa_compta', 'grouping', 'uploads')
        [@file_with_3_pages_path, @file_with_5_pages_path].each_with_index do |file_path, index|
          temp_document = TempDocument.new
          temp_document.temp_pack      = @temp_pack
          temp_document.user           = @user
          temp_document.position       = 3+index
          temp_document.delivered_by   = 'test'
          temp_document.delivery_type  = 'upload'
          temp_document.is_an_original = true
          temp_document.is_a_cover     = false
          temp_document.state          = 'bundling'
          temp_document.save
          Pdftk.new.burst file_path, base_path, "TS_0001_AC_201501_00#{3+index}", AccountingWorkflow::TempPackProcessor::POSITION_SIZE
        end

        base_path = Rails.root.join('files', 'test', 'prepa_compta', 'grouping', 'dematbox_scans')
        [@file_with_3_pages_path, @file_with_5_pages_path].each_with_index do |file_path, index|
          temp_document = TempDocument.new
          temp_document.temp_pack      = @temp_pack
          temp_document.user           = @user
          temp_document.position       = 5+index
          temp_document.delivered_by   = 'test'
          temp_document.delivery_type  = 'dematbox_scan'
          temp_document.is_an_original = true
          temp_document.is_a_cover     = false
          temp_document.state          = 'bundling'
          temp_document.save
          Pdftk.new.burst file_path, base_path, "TS_0001_AC_201501_00#{5+index}", AccountingWorkflow::TempPackProcessor::POSITION_SIZE
        end

        @temp_pack.update(position_counter: 6)

        data = '<?xml version="1.0" encoding="utf-8"?>
          <group_documents>
            <pack name="TS%0001_AC_201501">
              <piece number="1" origin="scan">
                <file_name>TS_0001_AC_201501_001.pdf</file_name>
                <file_name>TS_0001_AC_201501_002.pdf</file_name>
              </piece>
              <piece number="2" origin="upload">
                <file_name>TS_0001_AC_201501_003_001.pdf</file_name>
                <file_name>TS_0001_AC_201501_003_002.pdf</file_name>
                <file_name>TS_0001_AC_201501_003_003.pdf</file_name>
                <file_name>TS_0001_AC_201501_004_001.pdf</file_name>
              </piece>

              <piece number="3" origin="upload">
                <file_name>TS_0001_AC_201501_004_002.pdf</file_name>
                <file_name>TS_0001_AC_201501_004_003.pdf</file_name>
                <file_name>TS_0001_AC_201501_004_004.pdf</file_name>
                <file_name>TS_0001_AC_201501_004_005.pdf</file_name>
              </piece>
              <piece number="4" origin="dematbox_scan">
                <file_name>TS_0001_AC_201501_005_001.pdf</file_name>
                <file_name>TS_0001_AC_201501_005_002.pdf</file_name>
                <file_name>TS_0001_AC_201501_005_003.pdf</file_name>
                <file_name>TS_0001_AC_201501_006_001.pdf</file_name>
                <file_name>TS_0001_AC_201501_006_002.pdf</file_name>
                <file_name>TS_0001_AC_201501_006_003.pdf</file_name>
                <file_name>TS_0001_AC_201501_006_004.pdf</file_name>
                <file_name>TS_0001_AC_201501_006_005.pdf</file_name>
              </piece>
            </pack>
          </group_documents>'
        File.write(@result_file_path, data)
        File.utime(Time.local(2015,1,2), Time.local(2015,1,2), @result_file_path)
        FileUtils.mkdir_p Rails.root.join('files', 'test', 'prepa_compta', 'grouping', 'archives', '2015', '01', '01_1')

        AccountingWorkflow::GroupDocument.execute

        document_1 = @temp_pack.temp_documents.where(position: 7).first
        document_2 = @temp_pack.temp_documents.where(position: 8).first
        document_3 = @temp_pack.temp_documents.where(position: 9).first
        document_4 = @temp_pack.temp_documents.where(position: 10).first
        expect(File.exist?(@errors_file_path)).to be_falsy
        expect(@temp_pack.temp_documents.count).to eq 10
        expect(@temp_pack.temp_documents.bundled.count).to eq 6
        expect(@temp_pack.temp_documents.ready.count).to eq 4
        expect(DocumentTools.pages_number(document_1.content.path)).to eq 4
        expect(DocumentTools.pages_number(document_2.content.path)).to eq 4
        expect(DocumentTools.pages_number(document_3.content.path)).to eq 4
        expect(DocumentTools.pages_number(document_4.content.path)).to eq 8
        archive_path = Rails.root.join('files', 'test', 'prepa_compta', 'grouping', 'archives', '2015', '01', '02_1')
        expect(File.exist?(archive_path.join('TS_0001_AC_201501_001.pdf'))).to be_truthy
        expect(File.exist?(archive_path.join('TS_0001_AC_201501_002.pdf'))).to be_truthy
        expect(File.exist?(archive_path.join('TS_0001_AC_201501_003_001.pdf'))).to be_truthy
        expect(File.exist?(archive_path.join('TS_0001_AC_201501_003_002.pdf'))).to be_truthy
        expect(File.exist?(archive_path.join('TS_0001_AC_201501_003_003.pdf'))).to be_truthy
        expect(File.exist?(archive_path.join('TS_0001_AC_201501_004_001.pdf'))).to be_truthy
        expect(File.exist?(archive_path.join('TS_0001_AC_201501_004_002.pdf'))).to be_truthy
        expect(File.exist?(archive_path.join('TS_0001_AC_201501_004_003.pdf'))).to be_truthy
        expect(File.exist?(archive_path.join('TS_0001_AC_201501_004_004.pdf'))).to be_truthy
        expect(File.exist?(archive_path.join('TS_0001_AC_201501_004_005.pdf'))).to be_truthy
        expect(File.exist?(archive_path.join('TS_0001_AC_201501_005_001.pdf'))).to be_truthy
        expect(File.exist?(archive_path.join('TS_0001_AC_201501_005_002.pdf'))).to be_truthy
        expect(File.exist?(archive_path.join('TS_0001_AC_201501_005_003.pdf'))).to be_truthy
        expect(File.exist?(archive_path.join('TS_0001_AC_201501_006_001.pdf'))).to be_truthy
        expect(File.exist?(archive_path.join('TS_0001_AC_201501_006_002.pdf'))).to be_truthy
        expect(File.exist?(archive_path.join('TS_0001_AC_201501_006_003.pdf'))).to be_truthy
        expect(File.exist?(archive_path.join('TS_0001_AC_201501_006_004.pdf'))).to be_truthy
        expect(File.exist?(archive_path.join('TS_0001_AC_201501_006_005.pdf'))).to be_truthy
        expect(File.exist?(archive_path.join('result.xml'))).to be_truthy

        Timecop.return
      end
    end
  end
end
