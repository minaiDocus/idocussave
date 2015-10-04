# -*- encoding : UTF-8 -*-
class Admin::AdminController < ApplicationController
  before_filter :login_user!
  before_filter :verify_admin_rights

  layout 'admin'

  def index
    @provider_wishes = FiduceoProviderWish.not_processed.desc(:created_at).limit(5).entries

    @unbillable_organizations = Organization.billed.
                                  where('addresses.is_for_billing' => { '$nin' => [true] }).
                                  select { |o| o.customers.active.centralized.count > 0 }
    @unbillable_customers = User.customers.
                              not_centralized.
                              where('addresses.is_for_billing' => { '$nin' => [true] }).
                              includes(:organization)
  end

  def ocr_needed_temp_packs
    @ocr_needed_temp_packs = TempDocument.collection.aggregate(
      { '$match' => { 'state' => 'ocr_needed' } },
      { '$group' => {
          '_id'        => '$temp_pack_id',
          'count'      => { '$sum' => 1 },
          'updated_at' => { '$max' => '$updated_at' }
        }
      },
      { '$sort' => { 'updated_at' => -1 } }
    ).map do |data|
      object = OpenStruct.new
      object.date           = data['updated_at'].try(:localtime)
      object.name           = TempPack.find(data['_id']).name.sub(/ all\z/,'')
      object.document_count = data['count'].to_i
      object.message        = false
      object
    end
    render partial: 'process', locals: { collection: @ocr_needed_temp_packs }
  end

  def bundle_needed_temp_packs
    @bundle_needed_temp_packs = TempPack.bundle_needed.map do |temp_pack|
      temp_documents = temp_pack.temp_documents.bundle_needed.by_position.entries
      object = OpenStruct.new
      object.date           = temp_documents.last.try(:updated_at)
      object.name           = temp_pack.name.sub(/ all\z/,'')
      object.document_count = temp_documents.count
      object.message        = temp_documents.map(&:delivery_type).uniq.join(', ')
      object
    end.sort_by{ |o| [o.date ? 0 : 1, o.date] }.reverse
    render partial: 'process', locals: { collection: @bundle_needed_temp_packs }
  end

  def bundling_temp_packs
    @bundling_temp_packs = TempPack.bundling.map do |temp_pack|
      temp_documents = temp_pack.temp_documents.bundling.by_position.entries
      object = OpenStruct.new
      object.date           = temp_documents.last.try(:updated_at)
      object.name           = temp_pack.name.sub(/ all\z/,'')
      object.document_count = temp_documents.count
      object.message        = temp_documents.map(&:delivery_type).uniq.join(', ')
      object
    end.sort_by{ |o| [o.date ? 0 : 1, o.date] }.reverse
    render partial: 'process', locals: { collection: @bundling_temp_packs }
  end

  def processing_temp_packs
    @processing_temp_packs = TempPack.not_processed.map do |temp_pack|
      temp_documents = temp_pack.temp_documents.ready.by_position.entries
      object = OpenStruct.new
      object.date           = temp_documents.last.try(:updated_at)
      object.name           = temp_pack.name.sub(/ all\z/,'')
      object.document_count = temp_documents.count
      object.message        = temp_documents.map(&:delivery_type).uniq.join(', ')
      object
    end.sort_by{ |o| [o.date ? 0 : 1, o.date] }.reverse
    render partial: 'process', locals: { collection: @processing_temp_packs }
  end

  def currently_being_delivered_packs
    pack_ids = RemoteFile.not_processed.retryable.distinct(:pack_id)
    @currently_being_delivered_packs = Pack.where(:_id.in => pack_ids).map do |pack|
      remote_files = pack.remote_files.not_processed.retryable.asc(:created_at).entries
      object = OpenStruct.new
      object.date           = remote_files.last.try(:created_at)
      object.name           = pack.name.sub(/ all\z/,'')
      object.document_count = remote_files.count
      object.message        = remote_files.map(&:service_name).uniq.join(', ')
      object
    end.sort_by{ |o| [o.date ? 0 : 1, o.date] }.reverse
    render partial: 'process', locals: { collection: @currently_being_delivered_packs }
  end

  def failed_packs_delivery
    pack_ids = RemoteFile.not_processed.not_retryable.distinct(:pack_id)
    @failed_packs_delivery = Pack.where(:_id.in => pack_ids).map do |pack|
      remote_files = pack.remote_files.not_processed.not_retryable.asc(:created_at)
      object = OpenStruct.new
      object.date           = remote_files.last.try(:created_at)
      object.name           = pack.name.sub(/ all\z/,'')
      object.document_count = remote_files.count
      object.message        = remote_files.map(&:service_name).uniq.join(', ')
      object
    end.sort_by{ |o| [o.date ? 0 : 1, o.date] }.reverse
    render partial: 'process', locals: { collection: @failed_packs_delivery }
  end

  def blocked_pre_assignments
    @blocked_pre_assignments  = PreAssignmentService.pending.select { |e| e.message.present? }
    render partial: 'process', locals: { collection: @blocked_pre_assignments }
  end

  def awaiting_pre_assignments
    @awaiting_pre_assignments = PreAssignmentService.pending.select { |e| e.message.blank? }.
      each { |e| e.message = false }
    render partial: 'process', locals: { collection: @awaiting_pre_assignments }
  end

  def reports_delivery
    @reports_delivery = Pack::Report.locked.desc(:updated_at).map do |report|
      object = OpenStruct.new
      object.date           = report.updated_at
      object.name           = report.name.sub(/ all\z/,'')
      object.document_count = report.preseizures.locked.count
      object.message        = false
      object
    end
    render partial: 'process', locals: { collection: @reports_delivery }
  end

  def failed_reports_delivery
    @failed_reports_delivery = Pack::Report.failed_delivery
    render partial: 'process', locals: { collection: @failed_reports_delivery }
  end

private

  def verify_admin_rights
    redirect_to root_url unless current_user.is_admin
  end

  def nil_layout
    nil
  end

  def load_organization
    @organization = Organization.find_by_slug! params[:organization_id]
    raise Mongoid::Errors::DocumentNotFound.new(Organization, slug: params[:organization_id]) unless @organization
    @organization
  end
end
