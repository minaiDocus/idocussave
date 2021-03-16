# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe DocumentTools do
  it '.pages_number returns 2' do
    file_path = File.join([Rails.root, 'spec/support/files/2pages.pdf'])
    expect(DocumentTools.pages_number(file_path)).to eq(2)
  end

  it '.pages_number returns 5' do
    file_path = File.join([Rails.root, 'spec/support/files/5pages.pdf'])
    expect(DocumentTools.pages_number(file_path)).to eq(5)
  end

  it '.pack_name returns TEST001 TS 201309 all' do
    expect(DocumentTools.pack_name('TEST001_TS_201309_001.pdf')).to eq('TEST001 TS 201309 all')
  end

  it '.pack_name returns TEST001 TS 201309 all' do
    expect(DocumentTools.pack_name('TEST001_TS_201309.pdf')).to eq('TEST001 TS 201309 all')
  end

  it '.pack_name returns TEST001 TS 201309 all' do
    expect(DocumentTools.pack_name('TEST001_TS_201309_001.PDF')).to eq('TEST001 TS 201309 all')
  end

  it '.pack_name returns TEST001 TS 2013 all' do
    expect(DocumentTools.pack_name('TEST001_TS_2013_001.pdf')).to eq('TEST001 TS 2013 all')
  end

  it '.pack_name returns TEST001 TS 2013 all' do
    expect(DocumentTools.pack_name('TEST001_TS_2013.pdf')).to eq('TEST001 TS 2013 all')
  end

  it '.pack_name returns TEST001 TS 2013 all' do
    expect(DocumentTools.pack_name('TEST001_TS_2013_001.PDF')).to eq('TEST001 TS 2013 all')
  end

  it '.need_ocr? returns true' do
    file_path = File.join([Rails.root, 'spec/support/files/without_text.pdf'])
    expect(DocumentTools.need_ocr?(file_path)).to be true
  end

  it '.need_ocr? returns false' do
    file_path = File.join([Rails.root, 'spec/support/files/with_text.pdf'])
    expect(DocumentTools.need_ocr?(file_path)).to eq false
  end

  it '.need_ocr? with space in file_path returns true' do
    file_path = File.join([Rails.root, 'spec/support/files/without text.pdf'])
    expect(DocumentTools.need_ocr?(file_path)).to be true
  end

  it '.need_ocr? with space in file_path returns false' do
    file_path = File.join([Rails.root, 'spec/support/files/with text.pdf'])
    expect(DocumentTools.need_ocr?(file_path)).to eq false
  end

  it '.completed? returns true' do
    file_path = File.join([Rails.root, 'spec/support/files/completed.pdf'])
    expect(DocumentTools.completed?(file_path)).to be true
  end

  it '.completed? returns false' do
    file_path = File.join([Rails.root, 'spec/support/files/corrupted.pdf'])
    expect(DocumentTools.completed?(file_path)).to be false
  end

  it '.completed? with space in file_path returns true' do
    file_path = File.join([Rails.root, 'spec/support/files/completed file.pdf'])
    expect(DocumentTools.completed?(file_path)).to be true
  end

  it '.completed? with space in file_path returns false' do
    file_path = File.join([Rails.root, 'spec/support/files/corrupted file.pdf'])
    expect(DocumentTools.completed?(file_path)).to be false
  end

  it '.corrupted? returns true' do
    file_path = File.join([Rails.root, 'spec/support/files/corrupted.pdf'])
    expect(DocumentTools.corrupted?(file_path)).to be true
  end

  it '.corrupted? returns false' do
    file_path = File.join([Rails.root, 'spec/support/files/completed.pdf'])
    expect(DocumentTools.corrupted?(file_path)).to be false
  end

  it '.modifiable? returns false' do
    file_path = File.join([Rails.root, 'spec/support/files/protected.pdf'])
    expect(DocumentTools.modifiable?(file_path)).to be false
  end

  describe '.printable?' do
    context 'when corrupted file supplied' do
      it 'returns false' do
        file_path = File.join([Rails.root, 'spec/support/files/corrupted.pdf'])
        expect(DocumentTools.printable?(file_path)).to eq(false)
      end
    end

    context 'when protected file supplied' do
      it 'returns false' do
        file_path = File.join([Rails.root, 'spec/support/files/protected.pdf'])
        expect(DocumentTools.printable?(file_path)).to eq(false)
      end
    end

    context 'when printable file supplied' do
      it 'returns true' do
        file_path = File.join([Rails.root, 'spec/support/files/printable.pdf'])
        expect(DocumentTools.printable?(file_path)).to be true
      end
    end
  end

  describe '.is_printable_only?' do
    context 'when corrupted file supplied' do
      it 'returns nil' do
        file_path = File.join([Rails.root, 'spec/support/files/corrupted.pdf'])
        expect(DocumentTools.is_printable_only?(file_path)).to be_nil
      end
    end

    context 'when protected file supplied' do
      it 'returns false' do
        file_path = File.join([Rails.root, 'spec/support/files/protected.pdf'])
        expect(DocumentTools.is_printable_only?(file_path)).to eq(false)
      end
    end

    context 'when normal file supplied' do
      it 'returns false' do
        file_path = File.join([Rails.root, 'spec/support/files/2pages.pdf'])
        expect(DocumentTools.is_printable_only?(file_path)).to eq(false)
      end
    end

    context 'when printable file supplied' do
      it 'returns true' do
        file_path = File.join([Rails.root, 'spec/support/files/printable.pdf'])
        expect(DocumentTools.is_printable_only?(file_path)).to be true
      end
    end
  end

  describe '.remove_pdf_security' do
    context 'when printable only file supplied' do
      it 'remove restriction' do
        file_path = File.join([Rails.root, 'spec/support/files/printable.pdf'])
        new_file_path = Tempfile.new('opened.pdf').path
        DocumentTools.remove_pdf_security(file_path, new_file_path)
        expect(DocumentTools.is_printable_only?(new_file_path)).to eq(false)
      end
    end
  end

  it '.name_with_position returns "TS0001 TS 201301 004"' do
    expect(DocumentTools.name_with_position('TS0001 TS 201301', 4)).to eq('TS0001 TS 201301 004')
  end

  it '.name_with_position returns "TS0001 TS 201301 04"' do
    expect(DocumentTools.name_with_position('TS0001 TS 201301', 4, 2)).to eq('TS0001 TS 201301 04')
  end

  it '.file_name returns TS0001_TS_201301_004.pdf' do
    expect(DocumentTools.file_name('TS0001 TS 201301 004')).to eq('TS0001_TS_201301_004.pdf')
  end

  describe '.stamp_name' do
    it 'should returns TS0001' do
      expect(DocumentTools.stamp_name(':code', 'TS0001 TS 201301 005', false)).to eq('TS0001')
    end

    it 'should returns TS' do
      expect(DocumentTools.stamp_name(':account_book', 'TS0001 TS 201301 005', false)).to eq('TS')
    end

    it 'should returns 201301' do
      expect(DocumentTools.stamp_name(':period', 'TS0001 TS 201301 005', false)).to eq('201301')
    end

    it 'should returns 005' do
      expect(DocumentTools.stamp_name(':piece_num', 'TS0001 TS 201301 005', false)).to eq('005')
    end

    it 'should returns PAP' do
      expect(DocumentTools.stamp_name(':origin', 'TS0001 TS 201301 005', 'scan')).to eq('PAP')
    end

    it 'should returns UPL' do
      expect(DocumentTools.stamp_name(':origin', 'TS0001 TS 201301 005', 'upload')).to eq('UPL')
    end

    it 'should returns "TS0001 TS 201301 005 PAP"' do
      expect(DocumentTools.stamp_name(':code :account_book :period :piece_num :origin', 'TS0001 TS 201301 005', 'scan')).to eq('TS0001 TS 201301 005 PAP')
    end

    it 'should returns "TS0001 TS 201301 005 UPL"' do
      expect(DocumentTools.stamp_name(':code :account_book :period :piece_num :origin', 'TS0001 TS 201301 005', 'upload')).to eq('TS0001 TS 201301 005 UPL')
    end

    it 'should returns "201301 TS 005 UPL"' do
      expect(DocumentTools.stamp_name(':period :account_book :piece_num :origin', 'TS0001 TS 201301 005', 'upload')).to eq('201301 TS 005 UPL')
    end
  end

  it '.to_period returns Date(2013-01-01)' do
    expect(DocumentTools.to_period('TS0001 TS 201301 all')).to eq(Date.new(2013, 1, 1))
  end

  it '.to_period returns Date(2013-03-01)' do
    expect(DocumentTools.to_period('TS0001 TS 201303 all')).to eq(Date.new(2013, 3, 1))
  end

  describe '.mimetype' do
    it 'returns application/pdf' do
      expect(DocumentTools.mimetype('TS0001_Ts_201501_001.pdf')).to eq 'application/pdf'
    end

    it 'returns text/csv' do
      expect(DocumentTools.mimetype('TS0001_Ts_201501_001.csv')).to eq 'text/csv'
    end

    it 'returns nil' do
      expect(DocumentTools.mimetype('TS0001_Ts_201501_001.png')).to be_nil
    end
  end

  context 'force correct pdf', :force_correct do
    before(:all) do
      CustomUtils.mktmpdir(nil, false) do |dir|
        @dir = dir
      end
    end

    after(:all) do
      FileUtils.remove_entry(@dir, true)
    end

    it 'return corrected pdf with 1 page document', :correct_corrupted do
      input_file_path = File.join(@dir, 'not_mergeable.pdf')
      FileUtils.cp(Rails.root.join('spec', 'support', 'files', 'not_mergeable.pdf'), input_file_path)

      corrected = DocumentTools.force_correct_pdf(input_file_path)[:corrected]

      output_file_name = input_file_path.to_s.gsub('.pdf','_corrected.pdf')
      file_jpg         = input_file_path.to_s.gsub('.pdf','_corrected.jpg')

      expect(corrected).to be true
      expect(DocumentTools.modifiable?(output_file_name)).to be true
    end

    it 'return corrected pdf with 5 pages document', :correct_5pages do
      input_file_path = File.join(@dir, '5pages.pdf')
      FileUtils.cp(Rails.root.join('spec', 'support', 'files', '5pages.pdf'), input_file_path)

      corrected = DocumentTools.force_correct_pdf(input_file_path)[:corrected]

      output_file_name = input_file_path.to_s.gsub('.pdf','_corrected.pdf')
      file_jpg1        = input_file_path.to_s.gsub('.pdf','_corrected-0.jpg')
      file_jpg2        = input_file_path.to_s.gsub('.pdf','_corrected-4.jpg')

      expect(corrected).to be true
      expect(DocumentTools.modifiable?(output_file_name)).to be true
    end
  end
end
