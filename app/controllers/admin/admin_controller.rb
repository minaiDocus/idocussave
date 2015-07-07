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
    @organization = Organization.find_by_slug! params[:organization_id]
    raise Mongoid::Errors::DocumentNotFound.new(Organization, slug: params[:organization_id]) unless @organization
    @organization
  end

  public

  def index
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

    @bundle_needed_temp_packs = TempPack.bundle_needed.map do |temp_pack|
      object = OpenStruct.new
      object.date           = temp_pack.temp_documents.bundle_needed.by_position.last.try(:updated_at)
      object.name           = temp_pack.name.sub(/ all\z/,'')
      object.document_count = temp_pack.temp_documents.bundle_needed.count
      object.message        = temp_pack.temp_documents.bundle_needed.distinct('delivery_type').join(', ')
      object
    end.sort_by{ |o| [o.date ? 0 : 1, o.date] }.reverse

    @bundling_temp_packs = TempPack.bundling.map do |temp_pack|
      object = OpenStruct.new
      object.date           = temp_pack.temp_documents.bundling.by_position.last.try(:updated_at)
      object.name           = temp_pack.name.sub(/ all\z/,'')
      object.document_count = temp_pack.temp_documents.bundling.count
      object.message        = temp_pack.temp_documents.bundling.distinct('delivery_type').join(', ')
      object
    end.sort_by{ |o| [o.date ? 0 : 1, o.date] }.reverse

    @processing_temp_packs = TempPack.not_processed.map do |temp_pack|
      object = OpenStruct.new
      object.date           = temp_pack.temp_documents.ready.by_position.last.try(:updated_at)
      object.name           = temp_pack.name.sub(/ all\z/,'')
      object.document_count = temp_pack.temp_documents.ready.count
      object.message        = temp_pack.temp_documents.ready.distinct('delivery_type').join(', ')
      object
    end.sort_by{ |o| [o.date ? 0 : 1, o.date] }.reverse

    pack_ids = RemoteFile.not_processed.retryable.distinct(:pack_id)
    @currently_being_delivered_packs = Pack.where(:_id.in => pack_ids).map do |pack|
      object = OpenStruct.new
      object.date           = pack.remote_files.not_processed.retryable.asc(:created_at).last.try(:created_at)
      object.name           = pack.name.sub(/ all\z/,'')
      object.document_count = pack.remote_files.not_processed.retryable.count
      object.message        = pack.remote_files.not_processed.retryable.distinct(:service_name).join(', ')
      object
    end.sort_by{ |o| [o.date ? 0 : 1, o.date] }.reverse

    pack_ids = RemoteFile.not_processed.not_retryable.distinct(:pack_id)
    @failed_packs_delivery = Pack.where(:_id.in => pack_ids).map do |pack|
      object = OpenStruct.new
      object.date           = pack.remote_files.not_processed.not_retryable.asc(:created_at).last.try(:created_at)
      object.name           = pack.name.sub(/ all\z/,'')
      object.document_count = pack.remote_files.not_processed.not_retryable.count
      object.message        = pack.remote_files.not_processed.not_retryable.distinct(:service_name).join(', ')
      object
    end.sort_by{ |o| [o.date ? 0 : 1, o.date] }.reverse

    pending_pre_assignments   = PreAssignmentService.pending
    @blocked_pre_assignments  = pending_pre_assignments.select { |e| e.message.present? }
    @awaiting_pre_assignments = pending_pre_assignments.select { |e| e.message.blank? }.
      each { |e| e.message = false }

    @reports_delivery = Pack::Report.locked.desc(:updated_at).map do |report|
      object = OpenStruct.new
      object.date           = report.updated_at
      object.name           = report.name.sub(/ all\z/,'')
      object.document_count = report.preseizures.locked.count
      object.message        = false
      object
    end

    @failed_reports_delivery = Pack::Report.failed_delivery

    @emails          = Email.desc(:created_at).limit(10)
    @provider_wishes = FiduceoProviderWish.desc(:created_at).limit(5).entries

    @unbillable_organizations = Organization.billed.
                                  where('addresses.is_for_billing' => { '$nin' => [true] }).
                                  select { |o| o.customers.active.centralized.count > 0 }
    @unbillable_customers = User.customers.
                              not_centralized.
                              where('addresses.is_for_billing' => { '$nin' => [true] }).
                              includes(:organization)
  end
end
