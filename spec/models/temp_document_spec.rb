# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe TempDocument do
  it '#file_name_with_position return TS_0001_TS_201301_002.pdf' do
    temp_document = TempDocument.new
    temp_document.delivery_type = 'upload'
    temp_document.position = 2

    CustomUtils.mktmpdir do |dir|
      original_file_path = File.join(Rails.root, 'spec/support/files/completed.pdf')
      file_path = File.join(dir, 'TS%0001_TS_201301.pdf')
      FileUtils.cp original_file_path, file_path
      # temp_document.content = open file_path
      temp_document.cloud_content.attach(io: File.open(file_path), filename: File.basename(file_path)) if temp_document.save
    end

    expect(temp_document.file_name_with_position).to eq('TS_0001_TS_201301_002.pdf')
  end

  it '#file_name_with_position return TS_0001_TS_201301_002.pdf' do
    temp_document = TempDocument.new
    temp_document.delivery_type = 'scan'
    temp_document.position = 2

    CustomUtils.mktmpdir do |dir|
      original_file_path = File.join(Rails.root, 'spec/support/files/completed.pdf')
      file_path = File.join(dir, 'TS%0001_TS_201301_001.pdf')
      FileUtils.cp original_file_path, file_path
      # temp_document.content = open file_path
      temp_document.cloud_content.attach(io: File.open(file_path), filename: File.basename(file_path)) if temp_document.save
    end

    expect(temp_document.file_name_with_position).to eq('TS_0001_TS_201301_002.pdf')
  end

  it '#is_a_cover return true' do
    temp_document = TempDocument.new
    temp_document.delivery_type = 'scan'
    temp_document.original_file_name = 'TS0001_TS_201301_000.pdf'

    CustomUtils.mktmpdir do |dir|
      original_file_path = File.join(Rails.root, 'spec/support/files/completed.pdf')
      file_path = File.join(dir, 'TS0001_TS_201301_000.pdf')
      FileUtils.cp original_file_path, file_path
      # temp_document.content = open file_path
      temp_document.cloud_content.attach(io: File.open(file_path), filename: File.basename(file_path)) if temp_document.save
    end

    expect(temp_document.is_a_cover?).to be true
  end

  it '#is_a_cover return true' do
    temp_document = TempDocument.new
    temp_document.delivery_type = 'scan'
    temp_document.original_file_name = 'TS0001 TS 201301 000.pdf'

    CustomUtils.mktmpdir do |dir|
      original_file_path = File.join(Rails.root, 'spec/support/files/completed.pdf')
      file_path = File.join(dir, 'TS0001_TS_201301_000.pdf')
      FileUtils.cp original_file_path, file_path
      # temp_document.content = open file_path
      temp_document.cloud_content.attach(io: File.open(file_path), filename: File.basename(file_path)) if temp_document.save
    end

    expect(temp_document.is_a_cover?).to be true
  end

  it '#is_a_cover return true' do
    temp_document = TempDocument.new
    temp_document.delivery_type = 'scan'
    temp_document.original_file_name = 'TS0001_TS_201301_001.pdf'

    CustomUtils.mktmpdir do |dir|
      original_file_path = File.join(Rails.root, 'spec/support/files/completed.pdf')
      file_path = File.join(dir, 'TS0001_TS_201301_000.pdf')
      FileUtils.cp original_file_path, file_path
      # temp_document.content = open file_path
      temp_document.cloud_content.attach(io: File.open(file_path), filename: File.basename(file_path)) if temp_document.save
    end

    expect(temp_document.is_a_cover?).to be false
  end

  it '#is_a_cover return true' do
    temp_document = TempDocument.new
    temp_document.delivery_type = 'scan'
    temp_document.original_file_name = 'TS0001 TS 201301 001.pdf'

    CustomUtils.mktmpdir do |dir|
      original_file_path = File.join(Rails.root, 'spec/support/files/completed.pdf')
      file_path = File.join(dir, 'TS0001_TS_201301_000.pdf')
      FileUtils.cp original_file_path, file_path
      # temp_document.content = open file_path
      temp_document.cloud_content.attach(io: File.open(file_path), filename: File.basename(file_path)) if temp_document.save
    end

    expect(temp_document.is_a_cover?).to be false
  end
end
