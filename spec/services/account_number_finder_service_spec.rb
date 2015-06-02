# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe AccountNumberFinderService do
  describe '#execute' do
    before(:all) do
      @organization = create(:organization)
      @user = create(:user)
      @organization.members << @user
      @accounting_plan = [
        ['GOOGLE', '0GOO'],
        ['SLIMPAY', '0SLIM'],
        ['FIDUCEO', '0FID'],
        ['IBIZA /NS', '0IBI'],
        ['CA', '0CA'],
        ['CARTE', '0CAR']
      ]
    end

    context 'without rules and without accounting plan' do
      it 'returns 0TEMP' do
        allow(AccountNumberFinderService).to receive(:get_accounting_plan).and_return([])

        result = AccountNumberFinderService.new(@user, '0TEMP').execute('Prlv GoogleDrive $10.00')

        expect(result).to eq('0TEMP')
      end
    end

    context 'with accounting plan' do
      it 'returns 0GOO' do
        allow(AccountNumberFinderService).to receive(:get_accounting_plan).and_return(@accounting_plan)

        result = AccountNumberFinderService.new(@user, '0TEMP').execute('Prlv GoogleDrive $10.00')

        expect(result).to eq('0GOO')
      end

      it 'returns 0SLIM' do
        allow(AccountNumberFinderService).to receive(:get_accounting_plan).and_return(@accounting_plan)

        result = AccountNumberFinderService.new(@user, '0TEMP').execute('Prlv Slimpay Janvier 2015')

        expect(result).to eq('0SLIM')
      end

      it 'returns 0CAR based on scores' do
        allow(AccountNumberFinderService).to receive(:get_accounting_plan).and_return(@accounting_plan)

        result = AccountNumberFinderService.new(@user, '0TEMP').execute('paiement par carte €20.00')

        expect(result).to eq('0CAR')
      end
    end

    context 'with match rules' do
      before(:all) do
        @rule = AccountNumberRule.new
        @rule.organization = @organization
        @rule.name = 'Orange'
        @rule.affect = 'organization'
        @rule.rule_type = 'match'
        @rule.content = 'ORANGE'
        @rule.priority = 0
        @rule.third_party_account = '0ORA'
        @rule.save
      end

      after(:all) do
        @rule.destroy
      end

      it 'returns 0ORA' do
        allow(AccountNumberFinderService).to receive(:get_accounting_plan).and_return([])

        result = AccountNumberFinderService.new(@user, '0TEMP').execute('Prlv Orange Janvier 2015')

        expect(result).to eq('0ORA')
      end
    end

    context 'with truncate rules' do
      before(:all) do
        @rule = AccountNumberRule.new
        @rule.organization = @organization
        @rule.name = '/NS'
        @rule.affect = 'organization'
        @rule.rule_type = 'truncate'
        @rule.content = '/NS'
        @rule.priority = 0
        @rule.save
      end

      after(:all) do
        @rule.destroy
      end

      it 'returns 0IBI' do
        allow(AccountNumberFinderService).to receive(:get_accounting_plan).and_return(@accounting_plan)

        result = AccountNumberFinderService.new(@user, '0TEMP').execute('Prlv Ibiza $150.0')

        expect(result).to eq('0IBI')
      end
    end

    context 'with match rules and with accounting plan' do
      before(:all) do
        @rule = AccountNumberRule.new
        @rule.organization = @organization
        @rule.name = 'Google'
        @rule.affect = 'organization'
        @rule.rule_type = 'match'
        @rule.content = 'Google'
        @rule.priority = 0
        @rule.third_party_account = '0GOG'
        @rule.save
      end

      after(:all) do
        @rule.destroy
      end

      it 'returns 0GOG based on rules' do
        allow(AccountNumberFinderService).to receive(:get_accounting_plan).and_return(@accounting_plan)

        result = AccountNumberFinderService.new(@user, '0TEMP').execute('Prlv GoogleDrive $10.00')

        expect(result).to eq('0GOG')
      end
    end
  end
end
