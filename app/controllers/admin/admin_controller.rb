# -*- encoding : UTF-8 -*-
class Admin::AdminController < ApplicationController
  before_filter :login_user!
  before_filter :verify_admin_rights

  layout 'admin'

  private

  def verify_admin_rights
    redirect_to root_url unless current_user.is_admin
  end

  def nil_layout
    nil
  end

  def load_organization
    @organization = Organization.find_by_slug params[:organization_id]
    raise Mongoid::Errors::DocumentNotFound.new(Organization, params[:organization_id]) unless @organization
    @organization
  end

  public

  def index
    @ocr_needed_temp_packs = TempDocument.collection.group(
      key: [:temp_pack_id],
      cond: { state: 'ocr_needed' },
      initial: { updated_at: 0, count: 0 },
      reduce: "function(current, result) { result.count++; result.updated_at = current.updated_at; return result; }"
    ).map do |temp_pack|
      object = OpenStruct.new
      object.date           = temp_pack['updated_at'].try(:localtime)
      object.name           = TempPack.find(temp_pack['temp_pack_id']).name.sub(/ all$/,'')
      object.document_count = temp_pack['count'].to_i
      object.message        = false
      object
    end.sort! do |a,b|
      b.date <=> a.date
    end

    @bundle_needed_temp_packs = TempPack.desc(:updated_at).bundle_needed.map do |temp_pack|
      object = OpenStruct.new
      object.date           = temp_pack.temp_documents.bundle_needed.by_position.first.updated_at
      object.name           = temp_pack.name.sub(/ all$/,'')
      object.document_count = temp_pack.temp_documents.bundle_needed.count
      object.message        = false
      object
    end

    @bundling_temp_packs = TempPack.desc(:updated_at).bundling.map do |temp_pack|
      object = OpenStruct.new
      object.date           = temp_pack.temp_documents.bundling.by_position.first.updated_at
      object.name           = temp_pack.name.sub(/ all$/,'')
      object.document_count = temp_pack.temp_documents.bundling.count
      object.message        = false
      object
    end

    @processing_temp_packs = TempDocument.collection.group(
      key: [:temp_pack_id],
      cond: { state: 'ready', is_locked: false },
      initial: { updated_at: 0, count: 0 },
      reduce: "function(current, result) { result.count++; result.updated_at = current.updated_at; return result; }"
    ).map do |temp_pack|
      object = OpenStruct.new
      object.date           = temp_pack['updated_at'].try(:localtime)
      object.name           = TempPack.find(temp_pack['temp_pack_id']).name.sub(/ all$/,'')
      object.document_count = temp_pack['count'].to_i
      object.message        = false
      object
    end.sort! do |a,b|
      b.date <=> a.date
    end

    pack_ids = RemoteFile.not_processed.retryable.distinct(:pack_id)
    @currently_being_delivered_packs = Pack.where(:_id.in => pack_ids).desc(:updated_at).map do |pack|
      object = OpenStruct.new
      object.date           = pack.updated_at
      object.name           = pack.name.sub(/ all$/,'')
      object.document_count = pack.remote_files.not_processed.retryable.count
      object.message        = false
      object
    end

    pack_ids = RemoteFile.not_processed.not_retryable.distinct(:pack_id)
    @failed_packs_delivery = Pack.where(:_id.in => pack_ids).desc(:updated_at).map do |pack|
      object = OpenStruct.new
      object.date           = pack.updated_at
      object.name           = pack.name.sub(/ all$/,'')
      object.document_count = pack.remote_files.not_processed.not_retryable.count
      object.message        = false
      object
    end

    pending_pre_assignments   = PreAssignmentService._pending.map do |pre_assignment|
      object = OpenStruct.new
      object.date           = pre_assignment['date'].to_time.localtime
      object.name           = pre_assignment['pack_name']
      object.document_count = pre_assignment['piece_counts'].to_i
      object.message        = pre_assignment['comment'].present? ? pre_assignment['comment'] : false
      object
    end.sort! do |a,b|
      b.date <=> a.date
    end
    @blocked_pre_assignments  = pending_pre_assignments.select { |e| e.message.present? }
    @awaiting_pre_assignments = pending_pre_assignments.select { |e| e.message.blank? }

    @reports_delivery = Pack::Report.locked.desc(:updated_at).map do |report|
      object = OpenStruct.new
      object.date           = report.updated_at
      object.name           = report.name.sub(/ all$/,'')
      object.document_count = report.preseizures.locked.count
      object.message        = false
      object
    end

    @failed_reports_delivery = Pack::Report::Preseizure.collection.group(
      key: [:report_id, :delivery_message],
      cond: { delivery_message: { '$ne' => '', '$exists' => true } },
      initial: { failed_at: 0, count: 0 },
      reduce: "function(current, result) { result.count++; result.failed_at = current.delivery_tried_at; return result; }"
    ).map do |delivery|
      object = OpenStruct.new
      object.date           = delivery['failed_at'].try(:localtime)
      object.name           = Pack::Report.find(delivery['report_id']).name
      object.document_count = delivery['count'].to_i
      object.message        = delivery['delivery_message']
      object
    end.sort! do |a,b|
      b.date <=> a.date
    end

    @emails                      = Email.desc(:created_at).limit(10)
    @provider_wishes             = FiduceoProviderWish.desc(:created_at).limit(5).entries
    @document_retrievers         = FiduceoRetriever.providers.desc(:created_at).limit(5).entries
    @operation_retrievers        = FiduceoRetriever.banks.desc(:created_at).limit(5).entries
    @failed_document_retrievers  = FiduceoRetriever.providers.error.desc(:updated_at)
    @failed_operation_retrievers = FiduceoRetriever.banks.error.desc(:updated_at)
  end
end
