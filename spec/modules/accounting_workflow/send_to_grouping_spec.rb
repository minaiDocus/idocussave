# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe AccountingWorkflow::SendToGrouping do
  before(:all) do
    Timecop.freeze(Time.local(2015,1,1))
  end

  after(:all) do
    Timecop.return
  end

  describe '.execute' do
    before(:all) do
      base_path = Rails.root.join('files', 'test', 'prepa_compta', 'grouping')
      FileUtils.mkdir_p base_path.join('scans')
      FileUtils.mkdir_p base_path.join('dematbox_scans')
      FileUtils.mkdir_p base_path.join('uploads')
      FileUtils.mkdir_p base_path.join('archives')

      @user = FactoryBot.create(:user, code: 'TS0001')
      FactoryBot.create(:journal_with_preassignment, user_id: @user.id, name: 'TS', description: 'TEST')
      file_with_2_pages = Rails.root.join('spec', 'support', 'files', '2pages.pdf')
      file_with_3_pages = Rails.root.join('spec', 'support', 'files', '3pages.pdf')

      Dir.mktmpdir do |dir|
        @temp_pack = TempPack.find_or_create_by_name 'TS0001 TS 201501 all'
        2.times do |i|
          file_name = "TS0001_TS_201501_%03d.pdf" % (i+1)
          file_path = File.join dir, file_name
          FileUtils.cp file_with_2_pages, file_path
          options = {
            original_file_name: file_name,
            delivered_by: 'test',
            delivery_type: 'scan',
            is_content_file_valid: true
          }
          AddTempDocumentToTempPack.execute(@temp_pack, open(file_path), options)
        end

        file_name = 'TS0001_TS_201501.pdf'
        file_path = File.join dir, file_name
        FileUtils.cp file_with_3_pages, file_path
        options = {
          original_file_name: file_name,
          delivered_by: 'test',
          delivery_type: 'upload',
          is_content_file_valid: true
        }
        AddTempDocumentToTempPack.execute(@temp_pack, open(file_path), options)

        options = {
          delivered_by:          'test',
          delivery_type:         'dematbox_scan',
          dematbox_doc_id:       'doc_id',
          dematbox_box_id:       'box_id',
          dematbox_service_id:   'service_id',
          dematbox_text:         'text',
          is_content_file_valid: true
        }
        AddTempDocumentToTempPack.execute(@temp_pack, open(file_path), options)
      end

      Timecop.freeze(Time.local(2015,1,1,0,15,1))

      TempDocument.all.each do |temp_document|
        AccountingWorkflow::SendToGrouping.new(temp_document).execute
      end
    end

    after(:all) do
      FileUtils.remove_entry Rails.root.join('files', 'test', 'prepa_compta', 'grouping')
    end

    it 'create file TS0001_TS_201501_001.pdf in files/test/prepa_compta/grouping/scans' do
      path = Rails.root.join('files', 'test', 'prepa_compta', 'grouping', 'scans', 'TS0001_TS_201501_001.pdf')
      expect(File.exist?(path)).to be true
    end

    it 'create file TS0001_TS_201501_002.pdf in files/test/prepa_compta/grouping/scan' do
      path = Rails.root.join('files', 'test', 'prepa_compta', 'grouping', 'scans', 'TS0001_TS_201501_002.pdf')
      expect(File.exist?(path)).to be true
    end

    it 'does not create file TS0001_TS_201501_003.pdf in files/test/prepa_compta/grouping/scan' do
      path = Rails.root.join('files', 'test', 'prepa_compta', 'grouping', 'scans', 'TS0001_TS_201501_003.pdf')
      expect(File.exist?(path)).to be false
    end

    it 'create file TS0001_TS_201501_003_001.pdf in files/test/prepa_compta/grouping/upload' do
      path = Rails.root.join('files', 'test', 'prepa_compta', 'grouping', 'uploads', 'TS0001_TS_201501_003_001.pdf')
      expect(File.exist?(path)).to be true
    end

    it 'create file TS0001_TS_201501_003_002.pdf in files/test/prepa_compta/grouping/upload' do
      path = Rails.root.join('files', 'test', 'prepa_compta', 'grouping', 'uploads', 'TS0001_TS_201501_003_002.pdf')
      expect(File.exist?(path)).to be true
    end

    it 'create file TS0001_TS_201501_003_003.pdf in files/test/prepa_compta/grouping/upload' do
      path = Rails.root.join('files', 'test', 'prepa_compta', 'grouping', 'uploads', 'TS0001_TS_201501_003_003.pdf')
      expect(File.exist?(path)).to be true
    end

    it 'does not create file TS0001_TS_201501_003_004.pdf in files/test/prepa_compta/grouping/upload' do
      path = Rails.root.join('files', 'test', 'prepa_compta', 'grouping', 'uploads', 'TS0001_TS_201501_003_004.pdf')
      expect(File.exist?(path)).to be false
    end

    it 'create file TS0001_TS_201501_004_001.pdf in files/test/prepa_compta/grouping/dematbox_scan' do
      path = Rails.root.join('files', 'test', 'prepa_compta', 'grouping', 'dematbox_scans', 'TS0001_TS_201501_004_001.pdf')
      expect(File.exist?(path)).to be true
    end

    it 'create file TS0001_TS_201501_004_002.pdf in files/test/prepa_compta/grouping/dematbox_scan' do
      path = Rails.root.join('files', 'test', 'prepa_compta', 'grouping', 'dematbox_scans', 'TS0001_TS_201501_004_002.pdf')
      expect(File.exist?(path)).to be true
    end

    it 'create file TS0001_TS_201501_004_003.pdf in files/test/prepa_compta/grouping/dematbox_scan' do
      path = Rails.root.join('files', 'test', 'prepa_compta', 'grouping', 'dematbox_scans', 'TS0001_TS_201501_004_003.pdf')
      expect(File.exist?(path)).to be true
    end

    it 'does not create file TS0001_TS_201501_004_004.pdf in files/test/prepa_compta/grouping/dematbox_scan' do
      path = Rails.root.join('files', 'test', 'prepa_compta', 'grouping', 'dematbox_scans', 'TS0001_TS_201501_004_004.pdf')
      expect(File.exist?(path)).to be false
    end

    it 'change all temp_documents states to bundle_needed' do
      expect(@temp_pack.temp_documents.pluck(:state).uniq).to eq ['bundle_needed']
    end
  end
end
