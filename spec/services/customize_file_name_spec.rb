# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe CustomizeFileName do
  describe '#execute' do
    it 'returns TS%0001_AC_201501_001.pdf' do
      options = {
        user_code: 'TS%0001',
        journal: 'AC',
        period: '201501',
        piece_number: '001',
        extension: '.pdf'
      }
      policy = FileNamingPolicy.new
      result = CustomizeFileName.new(policy).execute(options)

      expect(result).to eq('TS%0001_AC_201501_001.pdf')
    end

    it 'returns TS%0001_AC_201501_001_Google.pdf' do
      options = {
        user_code: 'TS%0001',
        user_company: 'iDocus',
        journal: 'AC',
        period: '201501',
        piece_number: '001',
        third_party: 'Google',
        extension: '.pdf'
      }
      policy = FileNamingPolicy.new(is_third_party_used: true)
      result = CustomizeFileName.new(policy).execute(options)

      expect(result).to eq('TS%0001_AC_201501_001_Google.pdf')
    end

    it 'returns TS%0001_AC_201501_001_DIVERS_TEST.pdf' do
      options = {
        user_code: 'TS%0001',
        user_company: 'iDocus',
        journal: 'AC',
        period: '201501',
        piece_number: '001',
        third_party: 'DIVERS / TEST',
        extension: '.pdf'
      }
      policy = FileNamingPolicy.new(is_third_party_used: true)
      result = CustomizeFileName.new(policy).execute(options)

      expect(result).to eq('TS%0001_AC_201501_001_DIVERS_TEST.pdf')
    end

    it 'returns TS%0001_AC_201501_001_A_B.pdf' do
      options = {
        user_code: 'TS%0001',
        user_company: 'iDocus',
        journal: 'AC',
        period: '201501',
        piece_number: '001',
        third_party: 'A & B',
        extension: '.pdf'
      }
      policy = FileNamingPolicy.new(is_third_party_used: true)
      result = CustomizeFileName.new(policy).execute(options)

      expect(result).to eq('TS%0001_AC_201501_001_A_B.pdf')
    end

    it 'returns TS%0001-AC-201501-001-DIVERS-TEST.pdf' do
      options = {
        user_code: 'TS%0001',
        user_company: 'iDocus',
        journal: 'AC',
        period: '201501',
        piece_number: '001',
        third_party: 'DIVERS|TEST',
        extension: '.pdf'
      }
      policy = FileNamingPolicy.new(
        separator: '-',
        is_third_party_used: true
      )
      result = CustomizeFileName.new(policy).execute(options)

      expect(result).to eq('TS%0001-AC-201501-001-DIVERS-TEST.pdf')
    end

    it 'returns TS%0001_AC_201501_001_DIVERS_Google_001002_2015-01-02.pdf' do
      options = {
        user_code: 'TS%0001',
        user_company: 'iDocus',
        journal: 'AC',
        period: '201501',
        piece_number: '001',
        third_party: 'Google',
        invoice_number: '001002',
        invoice_date: '2015-01-02',
        extension: '.pdf'
      }
      policy = FileNamingPolicy.new(
        is_third_party_used: true,
        is_invoice_number_used: true,
        is_invoice_date_used: true
      )
      result = CustomizeFileName.new(policy).execute(options)

      expect(result).to eq('TS%0001_AC_201501_001_Google_001002_2015-01-02.pdf')
    end

    it 'returns TS%0001_AC_201501_001_TEST_CO_test.pdf' do
      options = {
        user_code: 'TS%0001',
        user_company: 'iDocus',
        journal: 'AC',
        period: '201501',
        piece_number: '001',
        third_party: 'TEST&CO : test',
        extension: '.pdf'
      }
      policy = FileNamingPolicy.new(is_third_party_used: true)
      result = CustomizeFileName.new(policy).execute(options)

      expect(result).to eq('TS%0001_AC_201501_001_TEST_CO_test.pdf')
    end
  end
end
