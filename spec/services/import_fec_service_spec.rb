# -*- encoding : UTF-8 -*-
require 'spec_helper'
require 'spec_module'

describe ImportFecService do
  before(:all) do
    SpecModule.create_tmp_dir
    @file = SpecModule.new.use_file("#{Rails.root}/spec/support/files/import_fec_file.txt")
  end

  after(:all) do
    SpecModule.remove_tmp_dir
    AccountingPlanItem.destroy_all
  end

  context 'for the FEC import' do
    it  'try before processing' do
      params_fec = ImportFecService.new(@file).before_processing

      expect(params_fec[:head_list_fec]).not_to eq nil
      expect(params_fec[:journal_on_fec]).not_to eq nil
    end

    it 'try import when it is completed' do
      customer = FactoryBot.create(:user)
      params = {}
      params = { journal: {"BQ"=>"on", "CS"=>"on", "OI"=>"on", "VT"=>"on"}, piece_ref: "2" }

      allow(customer).to receive_message_chain('accounting_plan.id').and_return(1)

      expect_any_instance_of(ImportFecService).to receive(:import_txt).and_call_original
      expect_any_instance_of(ImportFecService).to receive(:import_processing).and_call_original

      ImportFecService.new(@file).execute(customer, params)

      expect(AccountingPlanItem.first.id).not_to eq nil
      expect(AccountingPlanItem.first.third_party_account).not_to eq nil
      expect(AccountingPlanItem.first.third_party_name).not_to eq nil
      expect(AccountingPlanItem.first.conterpart_account).not_to eq nil
      expect(AccountingPlanItem.first.accounting_plan_itemable_id).to eq 1
    end
  end
end