# -*- encoding : UTF-8 -*-
class DataVerificator::DataVerificator
  def self.execute
    new().execute
  end

  def initialize
    @mail_infos = []
  end

  def execute
    @mail_infos << DataVerificator::IbizaErrors.new().execute

    @mail_infos << DataVerificator::TempDocumentUnreadable.new().execute

    @mail_infos << DataVerificator::PieceWithoutTempDocument.new().execute

    @mail_infos << DataVerificator::PieceWithPageNumberZero.new().execute

    @mail_infos << DataVerificator::TempPackWithoutTempDocument.new().execute

    @mail_infos << DataVerificator::PackOrTempPackDuplicatedName.new().execute

    @mail_infos << DataVerificator::UpdateAccountingPlanIsUpdatingTrueError.new().execute

    @mail_infos << DataVerificator::RemoteFileServiceNameSynchronization.new().execute

    @mail_infos << DataVerificator::TempDocumentUploadedByApiName.new().execute

    @mail_infos << DataVerificator::PieceReadyTempPackPreAssignmentNeeded.new().execute

    @mail_infos << DataVerificator::IbizaboxFolderStateProcessing.new().execute

    @mail_infos << DataVerificator::TempDocumentDuplicated.new().execute

    @mail_infos << DataVerificator::ErrorScriptMailerInfo.new().execute

    @mail_infos << DataVerificator::UpdateMcfSettingsToken.new().execute

    daily_mail
  end

  def daily_mail
    log_content = {
      name: "DataVerificator",
      date_scan: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
      details: @mail_infos
    }

    DataVerificatorMailer.notify(log_content).deliver
  end
end