# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe PrepaCompta::DocumentBundler do
  before(:all) do
    Timecop.freeze(Time.local(2013,1,1))
  end

  after(:all) do
    Timecop.return
  end

  describe '.current_folder_name' do
    it 'return 2013-01-01' do
      Dir.stub('glob') { [] }
      expect(PrepaCompta::DocumentBundler.current_folder_name).to eq('2013-01-01')
    end

    it 'return 2013-01-01_2' do
      Dir.stub('glob') { ['2013-01-01'] }
      expect(PrepaCompta::DocumentBundler.current_folder_name).to eq('2013-01-01_2')
    end

    it 'return 2013-01-01_3' do
      Dir.stub('glob') { ['2013-01-01', '2013-01-01_2'] }
      expect(PrepaCompta::DocumentBundler.current_folder_name).to eq('2013-01-01_3')
    end

    context 'with unordered list' do
      it 'return 2013-01-01_3' do
        Dir.stub('glob') { ['2013-01-01_2', '2013-01-01'] }
        expect(PrepaCompta::DocumentBundler.current_folder_name).to eq('2013-01-01_3')
      end
    end

    context 'with only last folder' do
      it 'return 2013-01-01_3' do
        Dir.stub('glob') { ['2013-01-01_2'] }
        expect(PrepaCompta::DocumentBundler.current_folder_name).to eq('2013-01-01_3')
      end
    end
  end

  describe '.prepare' do
    before(:all) do
      @user = FactoryGirl.create(:user, code: 'TS0001')
      @user.account_book_types.create(name: 'TS', description: 'TEST', entry_type: 2)
      file_with_2_pages = File.open File.join(Rails.root, 'spec', 'support', 'files', '2pages.pdf'), 'r'
      Dir.mktmpdir do |dir|
        temp_pack = TempPack.find_or_create_by_name 'TS0001 TS 201301 all'
        2.times do |i|
          file_name = "TS0001_TS_201301_%03d.pdf" % (i+1)
          file_path = File.join(dir, file_name)
          FileUtils.cp file_with_2_pages, file_path

          options = {
            original_file_name: file_name,
            delivered_by: 'test',
            delivery_type: 'scan',
            is_content_file_valid: true
          }

          temp_pack.add open(file_path), options
        end
      end
      file_with_2_pages.close

      Timecop.return
      Timecop.freeze(Time.local(2013,1,1,0,5,1))
      PrepaCompta::DocumentBundler.prepare
    end

    after(:all) do
      path = File.join(Rails.root, 'files', 'test', 'prepacompta', '2013-01-01')
      # FileUtils.remove_entry(path)
    end

    it 'should create files/test/prepacompta/2013-01-01/regroupments folder' do
      expect(File.exist?(File.join(Rails.root, 'files', 'test', 'prepacompta', '2013-01-01', 'regroupments'))).to be_true
    end

    it 'should create file info.csv in files/test/prepacompta/2013-01-01/regroupments' do
      path = File.join(Rails.root, 'files', 'test', 'prepacompta', '2013-01-01', 'regroupments', 'info.csv')
      expect(File.exist?(path)).to be_true
    end

    it 'should create file TS0001_TS_201301_001.pdf in files/test/prepacompta/2013-01-01/regroupments/scan' do
      path = File.join(Rails.root, 'files', 'test', 'prepacompta', '2013-01-01', 'regroupments', 'scan', 'TS0001_TS_201301_001.pdf')
      expect(File.exist?(path)).to be_true
    end

    it 'should create file TS0001_TS_201301_002.pdf in files/test/prepacompta/2013-01-01/regroupments/scan' do
      path = File.join(Rails.root, 'files', 'test', 'prepacompta', '2013-01-01', 'regroupments', 'scan', 'TS0001_TS_201301_002.pdf')
      expect(File.exist?(path)).to be_true
    end
  end
end
