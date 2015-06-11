# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe CustomFileNameService do
  describe '#execute' do
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
  end
end
