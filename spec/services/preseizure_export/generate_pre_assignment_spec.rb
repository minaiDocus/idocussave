# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe PreseizureExport::GeneratePreAssignment do
  def allow_any_instance_of_object
    allow_any_instance_of(PreAssignmentExport).to receive(:base_path).and_return("#{Rails.root}/spec/support/files/")
    allow_any_instance_of(User).to receive_message_chain('options.pre_assignment_date_computed?').and_return(false)
  end

  before(:all) do
    DatabaseCleaner.start

    @organization = FactoryBot.create :organization, code: 'IDO', is_coala_used: true, is_cegid_used: true, is_quadratus_used: true, is_csv_descriptor_used: true
    @user         = FactoryBot.create :user, code: 'IDO%LEAD', organization_id: @organization.id
    @report       = FactoryBot.create :report, user: @user, organization: @organization
    pack          = FactoryBot.create :pack, owner: @user, organization: @organization , name: (@report.name + ' all')
    @piece        = FactoryBot.create :piece, pack: pack, user: @user, organization: @organization, name: (@report.name + ' 001')
    @piece.cloud_content_object.attach(File.open("#{Rails.root}/spec/support/files/2019090001.pdf"), '2019090001.pdf')
    @piece.save
    @preseizures  = FactoryBot.create :preseizure, user: @user, organization: @organization, report_id: @report.id, piece: @piece, third_party: 'Google', piece_number: 'G001', date: Time.now, cached_amount: 10.0

    accounts  = Pack::Report::Preseizure::Account.create([
      { type: 1, number: '601109', preseizure_id: @preseizures.id },
      { type: 2, number: '471000', preseizure_id: @preseizures.id },
      { type: 3, number: '471001', preseizure_id: @preseizures.id },
    ])
    entries  = Pack::Report::Preseizure::Entry.create([
      { type: 1, number: '1', amount: 1213.48, preseizure_id: @preseizures.id, account_id: accounts[0].id },
      { type: 2, number: '1', amount: 1011.23, preseizure_id: @preseizures.id, account_id: accounts[1].id },
      { type: 2, number: '1', amount: 202.25, preseizure_id: @preseizures.id, account_id: accounts[2].id },
    ])
  end

  after(:all) do
    DatabaseCleaner.clean
  end

  context 'software coala', :coala_spec do
    before(:each) do
      @report.reload.pre_assignment_exports.each(&:destroy)
      @user.reload.softwares.destroy if @user.reload.softwares
    end

    it 'generates coala successfully' do
      allow_any_instance_of_object

      @user.reload.create_or_update_software({is_coala_used: true, is_coala_auto_deliver: 1})
      @user.reload.softwares.reload
      @report.reload

      PreseizureExport::GeneratePreAssignment.new(@preseizures.reload).execute

      pre_assignment_export = @report.reload.pre_assignment_exports.try(:last)

      expect(pre_assignment_export.state).to eq 'generated'
      expect(pre_assignment_export.for).to eq 'coala'
      expect(pre_assignment_export.file_name).to match "#{@report.name.tr(' ', '_')}_"
      expect(File.exist?(pre_assignment_export.file_path)).to be true
    end

    it 'doesn\'t generates coala when not auto deliver' do
      @user.reload.create_or_update_software({is_coala_used: true, is_coala_auto_deliver: 0})
      @user.reload.softwares.reload
      @report.reload

      PreseizureExport::GeneratePreAssignment.new(@preseizures.reload).execute

      pre_assignment_export = @report.reload.pre_assignment_exports.try(:last)

      expect(pre_assignment_export).to be nil
    end

    it 'got coala error when errors occure' do
      @user.reload.create_or_update_software({is_coala_used: true, is_coala_auto_deliver: 1})
      @user.reload.softwares.reload
      @report.reload

      allow_any_instance_of(PreseizureExport::Software::Coala).to receive(:execute).and_raise("file unzip error")
      PreseizureExport::GeneratePreAssignment.new(@preseizures.reload).execute

      pre_assignment_export = @report.reload.pre_assignment_exports.try(:last)

      expect(pre_assignment_export.state).to eq 'error'
      expect(pre_assignment_export.for).to eq 'coala'
      expect(pre_assignment_export.error_message).to match "file unzip error"
      expect(pre_assignment_export.file_name).to eq nil
    end
  end

  context 'software quadratus', :quadratus_spec do
    before(:each) do
      @report.reload.pre_assignment_exports.each(&:destroy)
      @user.reload.softwares.destroy if @user.reload.softwares
    end

    it 'generates quadratus successfully' do
      allow_any_instance_of_object

      @user.reload.create_or_update_software({is_quadratus_used: true, is_quadratus_auto_deliver: 1})
      @user.reload.softwares.reload
      @report.reload

      PreseizureExport::GeneratePreAssignment.new(@preseizures.reload).execute

      pre_assignment_export = @report.reload.pre_assignment_exports.try(:last)

      expect(pre_assignment_export.state).to eq 'generated'
      expect(pre_assignment_export.for).to eq 'quadratus'
      expect(pre_assignment_export.file_name).to match "#{@report.name.tr(' ', '_')}_"
      expect(File.exist?(pre_assignment_export.file_path)).to be true
    end

    it 'doesn\'t generates quadratus when not auto deliver' do
      @user.reload.create_or_update_software({is_quadratus_used: true, is_quadratus_auto_deliver: 0})
      @user.reload.softwares.reload
      @report.reload

      PreseizureExport::GeneratePreAssignment.new(@preseizures.reload).execute

      pre_assignment_export = @report.reload.pre_assignment_exports.try(:last)

      expect(pre_assignment_export).to be nil
    end

    it 'got quadratus error when errors occure' do
      @user.reload.create_or_update_software({is_quadratus_used: true, is_quadratus_auto_deliver: 1})
      @user.reload.softwares.reload
      @report.reload

      allow_any_instance_of(PreseizureExport::Software::Quadratus).to receive(:execute).and_raise("file unzip error")
      PreseizureExport::GeneratePreAssignment.new(@preseizures.reload).execute

      pre_assignment_export = @report.reload.pre_assignment_exports.try(:last)

      expect(pre_assignment_export.state).to eq 'error'
      expect(pre_assignment_export.for).to eq 'quadratus'
      expect(pre_assignment_export.error_message).to match "file unzip error"
      expect(pre_assignment_export.file_name).to eq nil
    end
  end

  context 'software cegid', :cegid_spec do
    before(:each) do
      @report.reload.pre_assignment_exports.each(&:destroy)
      @user.reload.softwares.destroy if @user.reload.softwares
    end

    it 'generates cegid successfully' do
      allow_any_instance_of_object

      @user.reload.create_or_update_software({is_cegid_used: true, is_cegid_auto_deliver: 1})
      @user.build_softwares
      @user.reload.softwares.reload
      @report.reload

      accounting_plan = AccountingPlan.new
      accounting_plan.user = @user
      accounting_plan.save

      PreseizureExport::GeneratePreAssignment.new(@preseizures.reload).execute

      pre_assignment_export = @report.reload.pre_assignment_exports.try(:last)

      expect(pre_assignment_export.state).to eq 'generated'
      expect(pre_assignment_export.for).to eq 'cegid'
      expect(pre_assignment_export.file_name).to match "#{@report.name.tr(' ', '_')}_"
      expect(File).to exist pre_assignment_export.file_path
    end

    it 'doesn\'t generates cegid when not auto deliver' do
      @user.reload.create_or_update_software({is_cegid_used: true, is_cegid_auto_deliver: 0})
      @user.reload.softwares.reload
      @report.reload

      PreseizureExport::GeneratePreAssignment.new(@preseizures.reload).execute

      pre_assignment_export = @report.reload.pre_assignment_exports.try(:last)

      expect(pre_assignment_export).to be nil
    end

    it 'got cegid error when errors occure' do
      @user.reload.create_or_update_software({is_cegid_used: true, is_cegid_auto_deliver: 1})
      @user.reload.softwares.reload
      @report.reload

      allow_any_instance_of(PreseizureExport::Software::Cegid).to receive(:execute).and_raise("file unzip error")
      PreseizureExport::GeneratePreAssignment.new(@preseizures.reload).execute

      pre_assignment_export = @report.reload.pre_assignment_exports.try(:last)

      expect(pre_assignment_export.state).to eq 'error'
      expect(pre_assignment_export.for).to eq 'cegid'
      expect(pre_assignment_export.error_message).to match "file unzip error"
      expect(pre_assignment_export.file_name).to eq nil
    end
  end

  context 'software csv_descriptor', :csv_descriptor_spec do
    before(:each) do
      @report.reload.pre_assignment_exports.each(&:destroy)
      @user.reload.softwares.destroy if @user.reload.softwares
    end

    it 'generates csv csv_descriptor successfully' do
      allow_any_instance_of_object

      @user.reload.create_or_update_software({is_csv_descriptor_used: true, is_csv_descriptor_auto_deliver: 1})
      @user.reload.softwares.reload
      @report.reload

      PreseizureExport::GeneratePreAssignment.new(@preseizures.reload).execute

      pre_assignment_export = @report.reload.pre_assignment_exports.try(:last)

      expect(pre_assignment_export.state).to eq 'generated'
      expect(pre_assignment_export.for).to eq 'csv_descriptor'
      expect(pre_assignment_export.file_name).to match "#{@report.name.tr(' ', '_')}_"
      expect(File).to exist pre_assignment_export.file_path
    end

    it 'doesn\'t generates csv csv_descriptor when not auto deliver' do
      @user.reload.create_or_update_software({is_csv_descriptor_used: true, is_csv_descriptor_auto_deliver: 0})
      @user.reload.softwares.reload
      @report.reload

      PreseizureExport::GeneratePreAssignment.new(@preseizures.reload).execute

      pre_assignment_export = @report.reload.pre_assignment_exports.try(:last)

      expect(pre_assignment_export).to be nil
    end

    it 'got csv_descriptor error when errors occure' do
      @user.reload.create_or_update_software({is_csv_descriptor_used: true, is_csv_descriptor_auto_deliver: 1})
      @user.reload.softwares.reload
      @report.reload

      allow_any_instance_of(PreseizureExport::PreseizuresToCsv).to receive(:execute).and_raise("file copy error")
      PreseizureExport::GeneratePreAssignment.new(@preseizures.reload).execute

      pre_assignment_export = @report.reload.pre_assignment_exports.try(:last)

      expect(pre_assignment_export.state).to eq 'error'
      expect(pre_assignment_export.for).to eq 'csv_descriptor'
      expect(pre_assignment_export.error_message).to match "file copy error"
      expect(pre_assignment_export.file_name).to eq nil
    end
  end
end