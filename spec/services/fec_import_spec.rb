# -*- encoding : UTF-8 -*-
require 'spec_helper'
require 'spec_module'

describe FecImport do
  before(:all) do
    SpecModule.create_tmp_dir
    @file = SpecModule.new.use_file("#{Rails.root}/spec/support/files/import_fec_file.txt")
  end

  after(:all) do
    SpecModule.remove_tmp_dir
    AccountingPlanItem.destroy_all
  end

  context 'FEC import' do
    it 'parsing metadata' do
      params_fec = FecImport.new(@file).parse_metadata

      expect(params_fec[:head_list_fec][0]).to eq 'JournalCode'
      expect(params_fec[:journal_on_fec][0]).to eq 'AN'
      expect(params_fec[:journal_on_fec][1]).to eq 'BQ'
    end

    it 'import when it is completed' do
      customer = FactoryBot.create(:user)
      params = { journal: {"BQ"=>"on", "CS"=>"on", "OI"=>"on", "VT"=>"on"}, piece_ref: "2" }

      allow(customer).to receive_message_chain('accounting_plan.id').and_return(1)

      expect_any_instance_of(FecImport).to receive(:import_txt).and_call_original
      expect_any_instance_of(FecImport).to receive(:import_processing).and_call_original

      FecImport.new(@file).execute(customer, params)

      expect(AccountingPlanItem.first.id).not_to eq nil
      expect(AccountingPlanItem.first.third_party_account).to eq '411AGIRH'
      expect(AccountingPlanItem.first.third_party_name).to eq 'AGIRH'
      expect(AccountingPlanItem.first.conterpart_account).to eq '708002'
      expect(AccountingPlanItem.first.accounting_plan_itemable_id).to eq 1
    end
  end
end