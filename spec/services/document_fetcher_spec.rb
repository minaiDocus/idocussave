# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe DocumentFetcher do
  it ".ready_dirs return ['2013-01-01_ready', '2013-01-01_2_ready']" do
    dirs = ['2013-01-01_ready', '2013-01-01_2_ready', '2013-01-01_3']
    expect(DocumentFetcher.ready_dirs(dirs)).to eq(['2013-01-01_ready', '2013-01-01_2_ready'])
  end

  it '.grouped_packs return hash with pack_names for keys and file_names for values' do
    file_names = [
      'TS0001_TS_201301_001.pdf',
      'TS0001 TS 201301 002.PDF',
      'TS0002 TS 201301 001.pdf',
      'TS0002_TS_201301_002.PDF'
    ]
    expect(DocumentFetcher.grouped_packs(file_names)).to eq({
      'TS0001_TS_201301' => ['TS0001_TS_201301_001.pdf', 'TS0001 TS 201301 002.PDF'],
      'TS0002_TS_201301' => ['TS0002 TS 201301 001.pdf', 'TS0002_TS_201301_002.PDF']
    })
  end

  it '.fetched_dir return 2013-01-01_fetched' do
    dir = '2013-01-01_ready'
    expect(DocumentFetcher.fetched_dir(dir)).to eq('2013-01-01_fetched')
  end

  it '.clean_file_name return TS0001_TS_201301_001.pdf' do
    dirty_file_name = 'TS0001 TS 201301 001.PDF'
    expect(DocumentFetcher.clean_file_name(dirty_file_name)).to eq('TS0001_TS_201301_001.pdf')
  end

  it ".valid_file_names return ['TS0001_TS_201301_001.PDF', 'TS0001 TS 201301 002.pdf']" do
    file_names = ['TS0001_TS_201301_001.PDF', 'TS0001 TS 201301 002.pdf', 'invalid_file_name.pdf']
    expect(DocumentFetcher.valid_file_names(file_names)).to eq(['TS0001_TS_201301_001.PDF', 'TS0001 TS 201301 002.pdf'])
  end
end
