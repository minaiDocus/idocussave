# frozen_string_literal: true

class Admin::AdminController < ApplicationController
  before_action :login_user!
  before_action :verify_admin_rights

  layout 'admin'

  # GET /admin
  def index
    @new_provider_requests = NewProviderRequest.not_processed.order(created_at: :desc).includes(:user).limit(5)
    @unbillable_organizations = Organization.billed.select { |e| e.billing_address.nil? }
  end

  # GET /admin/ocr_needed_temp_packs
  def ocr_needed_temp_packs
    @ocr_needed_temp_packs = TempDocument.where(state: 'ocr_needed').group(:temp_pack_id).includes(:temp_pack).map do |data|
      object = OpenStruct.new
      object.date           = data.try(:updated_at).try(:localtime)
      object.name           = data.temp_pack.name.sub(/ all\z/, '')
      object.document_count = data.temp_pack.temp_documents.ocr_needed.count
      object.message        = false
      object
    end

    render partial: 'ocr_needed_temp_packs', locals: { collection: @ocr_needed_temp_packs }
  end

  # GET /admin/bundle_needed_temp_packs
  def bundle_needed_temp_packs
    @bundle_needed_temp_packs = TempPack.bundle_needed.map do |temp_pack|
      temp_documents = temp_pack.temp_documents.bundle_needed.by_position
      object = OpenStruct.new
      object.date           = temp_documents.last.try(:updated_at).try(:localtime)
      object.name           = temp_pack.name.sub(/ all\z/, '')
      object.document_count = temp_documents.count
      object.message        = temp_documents.map(&:delivery_type).uniq.join(', ')
      object
    end.sort_by { |o| [o.date ? 0 : 1, o.date] }.reverse

    render partial: 'bundle_needed_temp_packs', locals: { collection: @bundle_needed_temp_packs }
  end

  # GET /admin/processing_temp_packs
  def processing_temp_packs
    @processing_temp_packs = TempPack.not_processed.map do |temp_pack|
      temp_documents = temp_pack.temp_documents.ready.by_position
      object = OpenStruct.new
      object.date           = temp_documents.last.try(:updated_at).try(:localtime)
      object.name           = temp_pack.name.sub(/ all\z/, '')
      object.document_count = temp_documents.count
      object.message        = temp_documents.map(&:delivery_type).uniq.join(', ')
      object
    end.sort_by { |o| [o.date ? 0 : 1, o.date] }.reverse

    render partial: 'processing_temp_packs', locals: { collection: @processing_temp_packs }
  end

  # GET /admin/currently_being_delivered_packs
  def currently_being_delivered_packs
    pack_ids = RemoteFile.not_processed.retryable.pluck(:pack_id)
    @currently_being_delivered_packs = Pack.where(id: pack_ids).map do |pack|
      Rails.cache.fetch ['pack', pack.id.to_s, 'remote_files', 'retryable', pack.remote_files_updated_at] do
        remote_files = pack.remote_files.not_processed.retryable.order(created_at: :asc)
        data = remote_files.map do |remote_file|
          name = remote_file.user.try(:my_code) || remote_file.group.try(:name) || remote_file.organization.try(:name)
          [name, remote_file.service_name].join(' : ')
        end.uniq

        object = OpenStruct.new
        object.date           = remote_files.last.try(:created_at).try(:localtime)
        object.name           = pack.name.sub(/ all\z/, '')
        object.document_count = remote_files.count
        object.message        = data.join(', ')
        object
      end
    end.sort_by { |o| [o.date ? 0 : 1, o.date] }.reverse

    render partial: 'currently_being_delivered_packs', locals: { collection: @currently_being_delivered_packs }
  end

  # GET /admin/failed_packs_delivery
  def failed_packs_delivery
    pack_ids = RemoteFile.not_processed.not_retryable.where('created_at >= ?', 6.months.ago).pluck(:pack_id)

    error_messages = []

    @failed_packs_delivery = Pack.where(id: pack_ids).map do |pack|
      Rails.cache.fetch ['pack', pack.id.to_s, 'remote_files', 'not_retryable', pack.remote_files_updated_at] do
        remote_files = pack.remote_files.not_processed.not_retryable.order(created_at: :asc)
        data = remote_files.map do |remote_file|
          name = remote_file.user.try(:my_code) || remote_file.group.try(:name) || remote_file.organization.try(:name)
          error_messages << remote_file.error_message
          [name, remote_file.service_name].join(' : ')
        end.uniq

        object = OpenStruct.new
        object.date           = remote_files.last.try(:created_at).try(:localtime)
        object.name           = pack.name.sub(/ all\z/, '')
        object.document_count = remote_files.count
        object.message        = data.join(', ')
        object.error_message  = error_messages.uniq.join(', ')
        object
      end
    end.sort_by { |o| [o.date ? 0 : 1, o.date] }.reverse
    render partial: 'failed_packs_delivery', locals: { collection: @failed_packs_delivery }
  end

  # GET /admin/blocked_pre_assignments
  def blocked_pre_assignments
    @blocked_pre_assignments = PreAssignment::Pending.unresolved.select { |e| e.message.present? }
    render partial: 'blocked_pre_assignments', locals: { collection: @blocked_pre_assignments }
  end

  # GET /admin/awaiting_pre_assignments
  def awaiting_pre_assignments
    @awaiting_pre_assignments = PreAssignment::Pending.unresolved.select { |e| (e.message.blank? || e.pre_assignment_state == 'force_processing') }

    render partial: 'awaiting_pre_assignments', locals: { collection: @awaiting_pre_assignments }
  end

  # GET /admin/awaiting_supplier_recognition
  def awaiting_supplier_recognition
    @awaiting_supplier_recognition = Pack::Piece.pre_assignment_supplier_recognition.group(:pack_id).group(:pre_assignment_comment).order(created_at: :desc).includes(:pack).map do |e|
        object = OpenStruct.new
        object.date           = e.created_at.try(:localtime)
        object.name           = e.pack.name.sub(/\s\d+\z/, '').sub(' all', '') if e.pack
        object.document_count = Pack::Piece.pre_assignment_supplier_recognition.where(pack_id: e.pack_id).count
        object
    end

    render partial: 'awaiting_supplier_recognition', locals: { collection: @awaiting_supplier_recognition }
  end

  # GET /admin/reports_delivery
  def reports_delivery
    @reports_delivery = Pack::Report.locked.order(updated_at: :desc).map do |report|
      object = OpenStruct.new
      object.date           = report.updated_at.try(:localtime)
      object.name           = report.name.sub(/ all\z/, '')
      object.document_count = report.preseizures.locked.count
      object.message        = false
      object
    end

    render partial: 'reports_delivery', locals: { collection: @reports_delivery }
  end

  # GET /admin/failed_reports_delivery
  def failed_reports_delivery
    @failed_reports_delivery = Pack::Report.failed_delivery(nil, 200)

    render partial: 'failed_reports_delivery', locals: { collection: @failed_reports_delivery }
  end

  private

  def verify_admin_rights
    redirect_to root_url unless current_user.is_admin
  end
end
