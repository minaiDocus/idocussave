# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe Ftp::Fetcher do
  it ".ready_dirs returns ['2013-01-01_ready', '2013-01-01_2_ready']" do
    dirs = ['2013-01-01_ready', '2013-01-01_2_ready', '2013-01-01_3']
    expect(Ftp::Fetcher.ready_dirs(dirs)).to eq(['2013-01-01_ready', '2013-01-01_2_ready'])
  end

  it '.grouped_packs returns hash with pack_names for keys and file_names for values' do
    file_names = [
      'TS0001_TS_201301_001.pdf',
      'TS0001 TS 201301 002.PDF',
      'TS0002 TS 201301 001.pdf',
      'TS0002_TS_201301_002.PDF',
      'TS0003 TS 2013 001.pdf',
      'TS0003_TS_2013_002.PDF'
    ]
    expect(Ftp::Fetcher.grouped_packs(file_names)).to eq({
      'TS0001_TS_201301' => ['TS0001_TS_201301_001.pdf', 'TS0001 TS 201301 002.PDF'],
      'TS0002_TS_201301' => ['TS0002 TS 201301 001.pdf', 'TS0002_TS_201301_002.PDF'],
      'TS0003_TS_2013' => ['TS0003 TS 2013 001.pdf', 'TS0003_TS_2013_002.PDF']
    })
  end

  it '.fetched_dir returns 2013-01-01_fetched' do
    dir = '2013-01-01_ready'
    expect(Ftp::Fetcher.fetched_dir(dir)).to eq('2013-01-01_fetched')
  end

  it '.clean_file_name returns TS0001_TS_201301_001.pdf' do
    dirty_file_name = 'TS0001 TS 201301 001.PDF'
    expect(Ftp::Fetcher.clean_file_name(dirty_file_name)).to eq('TS0001_TS_201301_001.pdf')
  end

  it '.clean_file_name returns TS0001_TS_2013_001.pdf' do
    dirty_file_name = 'TS0001 TS 2013 001.PDF'
    expect(Ftp::Fetcher.clean_file_name(dirty_file_name)).to eq('TS0001_TS_2013_001.pdf')
  end

  # TODO : check file naming pattern
  it ".valid_file_names returns ['TS0001_TS_201301_001.PDF', 'TS0001 TS 201301 002.pdf', 'TS0002 TS 2013 001.pdf']" do
    file_names = ['TS0001_TS_201301_page001.PDF', 'TS0001 TS 201301 page002.pdf', 'TS0002 TS 2013 page001.pdf', 'invalid_file_name.pdf']
    expect(Ftp::Fetcher.valid_file_names(file_names)).to eq(['TS0001_TS_201301_page001.PDF', 'TS0001 TS 201301 page002.pdf', 'TS0002 TS 2013 page001.pdf'])
  end
end
