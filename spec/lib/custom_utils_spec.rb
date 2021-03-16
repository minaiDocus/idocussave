# -*- encoding : UTF-8 -*-
require 'spec_helper'
Sidekiq::Testing.inline! #execute jobs immediatly

describe CustomUtils do
  it 'mktmpdir with remove entry true', :remove_entry_true do
    final_idr = CustomUtils.mktmpdir('test') do |dir|
      @dir         = dir
      @first_file  = File.join(@dir, '2pages.pdf')
      FileUtils.cp(Rails.root.join('spec', 'support', 'files', '2pages.pdf'), @first_file)

      @second_file = File.join(@dir, '5pages.pdf')
      FileUtils.cp(Rails.root.join('spec', 'support', 'files', '5pages.pdf'), @second_file)
    end

    expect(File.directory?(final_idr)).to eq false
  end


  it 'mktmpdir with remove entry false', :remove_entry_false do
    final_idr = CustomUtils.mktmpdir('test', nil, false) do |dir|
      @dir         = dir
      @first_file  = File.join(@dir, '2pages.pdf')
      FileUtils.cp(Rails.root.join('spec', 'support', 'files', '2pages.pdf'), @first_file)

      @second_file = File.join(@dir, '5pages.pdf')
      FileUtils.cp(Rails.root.join('spec', 'support', 'files', '5pages.pdf'), @second_file)
    end

    expect(File.directory?(final_idr)).to eq true

    FileUtils.remove_entry(final_idr, true)
  end
end