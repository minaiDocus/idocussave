# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe GeneratePreAssignmentExportService do
  before(:all) do
    DatabaseCleaner.start

    @organization = FactoryGirl.create :organization, code: 'IDO', is_coala_used: true, is_quadratus_used: true, is_csv_descriptor_used: true
    @user = FactoryGirl.create :user, code: 'IDO%LEAD', organization_id: @organization.id
    @report = FactoryGirl.create :report, user: @user, organization: @organization
    @preseizures = FactoryGirl.create :preseizure, user: @user, organization: @organization, report_id: @report.id
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
      @user.reload.create_or_update_software({is_coala_used: true, is_coala_auto_deliver: 1})
      @user.reload.softwares.reload
      @report.reload

      GeneratePreAssignmentExportService.new(@preseizures.reload).execute

      pre_assignment_export = @report.reload.pre_assignment_exports.try(:last)

      expect(pre_assignment_export.state).to eq 'generated'
      expect(pre_assignment_export.for).to eq 'coala'
      expect(pre_assignment_export.file_name).to match "#{@report.name.tr(' ', '_')}_"
      expect(File).to exist pre_assignment_export.file_path
    end

    it 'doesn\'t generates coala when not auto deliver' do
      @user.reload.create_or_update_software({is_coala_used: true, is_coala_auto_deliver: 0})
      @user.reload.softwares.reload
      @report.reload

      GeneratePreAssignmentExportService.new(@preseizures.reload).execute

      pre_assignment_export = @report.reload.pre_assignment_exports.try(:last)

      expect(pre_assignment_export).to be nil
    end

    it 'got coala error when errors occure' do
      @user.reload.create_or_update_software({is_coala_used: true, is_coala_auto_deliver: 1})
      @user.reload.softwares.reload
      @report.reload

      allow_any_instance_of(CoalaZipService).to receive(:execute).and_raise("file unzip error")
      GeneratePreAssignmentExportService.new(@preseizures.reload).execute

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
      @user.reload.create_or_update_software({is_quadratus_used: true, is_quadratus_auto_deliver: 1})
      @user.reload.softwares.reload
      @report.reload

      GeneratePreAssignmentExportService.new(@preseizures.reload).execute

      pre_assignment_export = @report.reload.pre_assignment_exports.try(:last)

      expect(pre_assignment_export.state).to eq 'generated'
      expect(pre_assignment_export.for).to eq 'quadratus'
      expect(pre_assignment_export.file_name).to match "#{@report.name.tr(' ', '_')}_"
      expect(File).to exist pre_assignment_export.file_path
    end

    it 'doesn\'t generates quadratus when not auto deliver' do
      @user.reload.create_or_update_software({is_quadratus_used: true, is_quadratus_auto_deliver: 0})
      @user.reload.softwares.reload
      @report.reload

      GeneratePreAssignmentExportService.new(@preseizures.reload).execute

      pre_assignment_export = @report.reload.pre_assignment_exports.try(:last)

      expect(pre_assignment_export).to be nil
    end

    it 'got quadratus error when errors occure' do
      @user.reload.create_or_update_software({is_quadratus_used: true, is_quadratus_auto_deliver: 1})
      @user.reload.softwares.reload
      @report.reload

      allow_any_instance_of(QuadratusZipService).to receive(:execute).and_raise("file unzip error")
      GeneratePreAssignmentExportService.new(@preseizures.reload).execute

      pre_assignment_export = @report.reload.pre_assignment_exports.try(:last)

      expect(pre_assignment_export.state).to eq 'error'
      expect(pre_assignment_export.for).to eq 'quadratus'
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
      @user.reload.create_or_update_software({is_csv_descriptor_used: true, is_csv_descriptor_auto_deliver: 1})
      @user.reload.softwares.reload
      @report.reload

      GeneratePreAssignmentExportService.new(@preseizures.reload).execute

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

      GeneratePreAssignmentExportService.new(@preseizures.reload).execute

      pre_assignment_export = @report.reload.pre_assignment_exports.try(:last)

      expect(pre_assignment_export).to be nil
    end

    it 'got csv_descriptor error when errors occure' do
      @user.reload.create_or_update_software({is_csv_descriptor_used: true, is_csv_descriptor_auto_deliver: 1})
      @user.reload.softwares.reload
      @report.reload

      allow_any_instance_of(PreseizuresToCsv).to receive(:execute).and_raise("file copy error")
      GeneratePreAssignmentExportService.new(@preseizures.reload).execute

      pre_assignment_export = @report.reload.pre_assignment_exports.try(:last)

      expect(pre_assignment_export.state).to eq 'error'
      expect(pre_assignment_export.for).to eq 'csv_descriptor'
      expect(pre_assignment_export.error_message).to match "file copy error"
      expect(pre_assignment_export.file_name).to eq nil
    end
  end
end