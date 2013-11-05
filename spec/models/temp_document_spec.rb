# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe TempDocument do
  it '#file_name_with_arrival_position return TS0001_TS_201301_002.pdf' do
    temp_document = TempDocument.new
    temp_document.delivery_type = 'scan'
    temp_document.position = 2
    Dir.mktmpdir do |dir|
      original_file_path = File.join(Rails.root, 'spec/support/files/completed.pdf')
      file_path = File.join(dir, 'TS0001_TS_201301.pdf')
      FileUtils.cp original_file_path, file_path
      temp_document.content = open file_path
      temp_document.save
    end
    expect(temp_document.file_name_with_position).to eq('TS0001_TS_201301_002.pdf')
  end

  it '#file_name_with_position return TS0001_TS_201301_003.pdf' do
    temp_document = TempDocument.new
    temp_document.delivery_type = 'scan'
    temp_document.position = 3
    Dir.mktmpdir do |dir|
      original_file_path = File.join(Rails.root, 'spec/support/files/completed.pdf')
      file_path = File.join(dir, 'TS0001_TS_201301.pdf')
      FileUtils.cp original_file_path, file_path
      temp_document.content = open file_path
      temp_document.save
    end
    expect(temp_document.file_name_with_position).to eq('TS0001_TS_201301_003.pdf')
  end

  it '#file_name_with_position return TS0001_TS_201301_003.pdf' do
    temp_document = TempDocument.new
    temp_document.delivery_type = 'scan'
    temp_document.position = 3
    Dir.mktmpdir do |dir|
      original_file_path = File.join(Rails.root, 'spec/support/files/completed.pdf')
      file_path = File.join(dir, 'TS0001_TS_201301_001.pdf')
      FileUtils.cp original_file_path, file_path
      temp_document.content = open file_path
      temp_document.save
    end
    expect(temp_document.file_name_with_position).to eq('TS0001_TS_201301_003.pdf')
  end

  it '#is_a_cover return true' do
    temp_document = TempDocument.new
    temp_document.delivery_type = 'scan'
    temp_document.original_file_name = 'TS0001_TS_201301_000.pdf'
    Dir.mktmpdir do |dir|
      original_file_path = File.join(Rails.root, 'spec/support/files/completed.pdf')
      file_path = File.join(dir, 'TS0001_TS_201301_000.pdf')
      FileUtils.cp original_file_path, file_path
      temp_document.content = open file_path
      temp_document.save
    end
    expect(temp_document.is_a_cover?).to be_true
  end

  it '#is_a_cover return true' do
    temp_document = TempDocument.new
    temp_document.delivery_type = 'scan'
    temp_document.original_file_name = 'TS0001 TS 201301 000.pdf'
    Dir.mktmpdir do |dir|
      original_file_path = File.join(Rails.root, 'spec/support/files/completed.pdf')
      file_path = File.join(dir, 'TS0001_TS_201301_000.pdf')
      FileUtils.cp original_file_path, file_path
      temp_document.content = open file_path
      temp_document.save
    end
    expect(temp_document.is_a_cover?).to be_true
  end

  it '#is_a_cover return true' do
    temp_document = TempDocument.new
    temp_document.delivery_type = 'scan'
    temp_document.original_file_name = 'TS0001_TS_201301_001.pdf'
    Dir.mktmpdir do |dir|
      original_file_path = File.join(Rails.root, 'spec/support/files/completed.pdf')
      file_path = File.join(dir, 'TS0001_TS_201301_000.pdf')
      FileUtils.cp original_file_path, file_path
      temp_document.content = open file_path
      temp_document.save
    end
    expect(temp_document.is_a_cover?).to be_false
  end

  it '#is_a_cover return true' do
    temp_document = TempDocument.new
    temp_document.delivery_type = 'scan'
    temp_document.original_file_name = 'TS0001 TS 201301 001.pdf'
    Dir.mktmpdir do |dir|
      original_file_path = File.join(Rails.root, 'spec/support/files/completed.pdf')
      file_path = File.join(dir, 'TS0001_TS_201301_000.pdf')
      FileUtils.cp original_file_path, file_path
      temp_document.content = open file_path
      temp_document.save
    end
    expect(temp_document.is_a_cover?).to be_false
  end
end
