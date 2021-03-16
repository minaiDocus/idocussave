# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe 'Pdftk' do
  context 'Merge' do
    before(:each) do
      CustomUtils.mktmpdir('pdftk_test', nil, false) do |dir|
        @dir         = dir
        @first_file  = File.join(@dir, '2pages.pdf')
        FileUtils.cp(Rails.root.join('spec', 'support', 'files', '2pages.pdf'), @first_file)

        @second_file = File.join(@dir, '5pages.pdf')
        FileUtils.cp(Rails.root.join('spec', 'support', 'files', '5pages.pdf'), @second_file)

        @destination_file = File.join(@dir, 'spec_merge.pdf')
      end
    end

    after(:each) do
      FileUtils.remove_entry(@dir, true)
    end

    it 'merge with mergeable file', :default do
      is_merged = Pdftk.new.merge([@first_file, @second_file], @destination_file)

      expect(is_merged).to be true
    end

    it 'force merge when file is unmergeable', :force_merge do
      @second_file = File.join(@dir, 'not_mergeable.pdf')
      FileUtils.cp(Rails.root.join('spec', 'support', 'files', 'not_mergeable.pdf'), @second_file)

      # expect(DocumentTools).to receive(:force_correct_pdf).with(any_args).exactly(:once)
      is_merged = Pdftk.new.merge([@first_file, @second_file], @destination_file)

      expect(is_merged).to be true
    end
  end
end