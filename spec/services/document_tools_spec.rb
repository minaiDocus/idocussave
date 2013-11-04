# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe DocumentTools do
  it '.page_number return 2' do
    file_path = File.join([Rails.root, 'spec/support/files/2pages.pdf'])
    expect(DocumentTools.pages_number(file_path)).to eq(2)
  end

  it '.page_number return 5' do
    file_path = File.join([Rails.root, 'spec/support/files/5pages.pdf'])
    expect(DocumentTools.pages_number(file_path)).to eq(5)
  end

  it '.pack_name return TEST001 TS 201309 all' do
    expect(DocumentTools.pack_name('TEST001_TS_201309_001.pdf')).to eq('TEST001 TS 201309 all')
  end

  it '.pack_name return TEST001 TS 201309 all' do
    expect(DocumentTools.pack_name('TEST001_TS_201309.pdf')).to eq('TEST001 TS 201309 all')
  end

  it '.pack_name return TEST001 TS 201309 all' do
    expect(DocumentTools.pack_name('TEST001_TS_201309_001.PDF')).to eq('TEST001 TS 201309 all')
  end

  it '.need_ocr? return true' do
    file_path = File.join([Rails.root, 'spec/support/files/without_text.pdf'])
    expect(DocumentTools.need_ocr?(file_path)).to be_true
  end

  it '.need_ocr? return false' do
    file_path = File.join([Rails.root, 'spec/support/files/with_text.pdf'])
    expect(DocumentTools.need_ocr?(file_path)).to be_false
  end

  it '.completed? return true' do
    file_path = File.join([Rails.root, 'spec/support/files/completed.pdf'])
    expect(DocumentTools.completed?(file_path)).to be_true
  end

  it '.completed? return false' do
    file_path = File.join([Rails.root, 'spec/support/files/corrupted.pdf'])
    expect(DocumentTools.completed?(file_path)).to be_false
  end

  it '.corrupted? return true' do
    file_path = File.join([Rails.root, 'spec/support/files/corrupted.pdf'])
    expect(DocumentTools.corrupted?(file_path)).to be_true
  end

  it '.corrupted? return false' do
    file_path = File.join([Rails.root, 'spec/support/files/completed.pdf'])
    expect(DocumentTools.corrupted?(file_path)).to be_false
  end

  it '.modifiable? return false' do
    file_path = File.join([Rails.root, 'spec/support/files/protected.pdf'])
    expect(DocumentTools.modifiable?(file_path)).to be_false
  end

  it '.name_with_position return "TS0001 TS 201301 004"' do
    expect(DocumentTools.name_with_position('TS0001 TS 201301', 4)).to eq('TS0001 TS 201301 004')
  end

  it '.name_with_position return "TS0001 TS 201301 04"' do
    expect(DocumentTools.name_with_position('TS0001 TS 201301', 4, 2)).to eq('TS0001 TS 201301 04')
  end

  it '.file_name return TS0001_TS_201301_004.pdf' do
    expect(DocumentTools.file_name('TS0001 TS 201301 004')).to eq('TS0001_TS_201301_004.pdf')
  end

  describe '.stamp_name' do
    it 'should return TS0001' do
      expect(DocumentTools.stamp_name(':code', 'TS0001 TS 201301 005', false)).to eq('TS0001')
    end

    it 'should return TS' do
      expect(DocumentTools.stamp_name(':account_book', 'TS0001 TS 201301 005', false)).to eq('TS')
    end

    it 'should return 201301' do
      expect(DocumentTools.stamp_name(':period', 'TS0001 TS 201301 005', false)).to eq('201301')
    end

    it 'should return 005' do
      expect(DocumentTools.stamp_name(':piece_num', 'TS0001 TS 201301 005', false)).to eq('005')
    end

    it 'should return PAP' do
      expect(DocumentTools.stamp_name(':origin', 'TS0001 TS 201301 005', 'scan')).to eq('PAP')
    end

    it 'should return UPL' do
      expect(DocumentTools.stamp_name(':origin', 'TS0001 TS 201301 005', 'upload')).to eq('UPL')
    end

    it 'should return "TS0001 TS 201301 005 PAP"' do
      expect(DocumentTools.stamp_name(':code :account_book :period :piece_num :origin', 'TS0001 TS 201301 005', 'scan')).to eq('TS0001 TS 201301 005 PAP')
    end

    it 'should return "TS0001 TS 201301 005 UPL"' do
      expect(DocumentTools.stamp_name(':code :account_book :period :piece_num :origin', 'TS0001 TS 201301 005', 'upload')).to eq('TS0001 TS 201301 005 UPL')
    end

    it 'should return "201301 TS 005 UPL"' do
      expect(DocumentTools.stamp_name(':period :account_book :piece_num :origin', 'TS0001 TS 201301 005', 'upload')).to eq('201301 TS 005 UPL')
    end
  end
end
