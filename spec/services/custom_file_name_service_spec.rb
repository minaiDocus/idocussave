# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe CustomFileNameService do
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
      result = CustomFileNameService.new(policy).execute(options)

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
      result = CustomFileNameService.new(policy).execute(options)

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
      result = CustomFileNameService.new(policy).execute(options)

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
      result = CustomFileNameService.new(policy).execute(options)

      expect(result).to eq('TS%0001_AC_201501_001_A_B.pdf')
    end

    it 'returns 001_201501_AC_iDocus_TS%0001.tiff' do
      options = {
        user_code: 'TS%0001',
        user_company: 'iDocus',
        journal: 'AC',
        period: '201501',
        piece_number: '001',
        extension: '.tiff'
      }
      policy = FileNamingPolicy.new(
        first_user_identifier_position: 4,
        second_user_identifier: 'company',
        second_user_identifier_position: 3,
        journal_position: 2,
        period_position: 1,
        piece_number_position: 0
      )
      result = CustomFileNameService.new(policy).execute(options)

      expect(result).to eq('001_201501_AC_iDocus_TS%0001.tiff')
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
      result = CustomFileNameService.new(policy).execute(options)

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
      result = CustomFileNameService.new(policy).execute(options)

      expect(result).to eq('TS%0001_AC_201501_001_Google_001002_2015-01-02.pdf')
    end

    it 'returns TS%0001_AC_DIVERS_201501_001_TEST_CO.pdf' do
      options = {
        user_code: 'TS%0001',
        user_company: 'iDocus',
        journal: 'AC: DIVERS',
        period: '201501',
        piece_number: '001',
        third_party: 'TEST&CO',
        extension: '.pdf'
      }
      policy = FileNamingPolicy.new(is_third_party_used: true)
      result = CustomFileNameService.new(policy).execute(options)

      expect(result).to eq('TS%0001_AC_DIVERS_201501_001_TEST_CO.pdf')
    end
  end
end
