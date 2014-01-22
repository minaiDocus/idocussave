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
    @bundle_needed_temp_packs = TempPack.desc(:updated_at).bundle_needed
    @bundling_temp_packs      = TempPack.desc(:updated_at).bundling
    @processing_temp_packs    = TempDocument.collection.group(
      key: [:temp_pack_id],
      cond: { state: 'ready', is_locked: false },
      initial: { updated_at: 0, count: 0 },
      reduce: "function(current, result) { result.count++; result.updated_at = current.updated_at; return result; }"
    ).each do |temp_pack|
      temp_pack['name'] = TempPack.find(temp_pack['temp_pack_id']).name
      temp_pack['count'] = temp_pack['count'].to_i
    end.sort! do |a,b|
      b['updated_at'] <=> a['updated_at']
    end
    @last_packs               = Pack.desc(:updated_at).limit(15)
    @awaiting_pre_assignments = Pack::Piece.collection.group(
      keyf: "function(x) { name = x.name.split(' '); name.pop(); name = name.join(' '); return { name: name }; }",
      cond: { is_awaiting_pre_assignment: true },
      initial: { count: 0 },
      reduce: "function(current, result) { return result.count++; }"
    )
    @reports_delivery         = Pack::Report.locked.asc(:updated_at)
    @failed_reports_delivery  = Pack::Report::Preseizure.collection.group(
      key: [:report_id, :delivery_message],
      cond: { delivery_message: { '$ne' => '', '$exists' => true } },
      initial: { failed_at: 0, count: 0 },
      reduce: "function(current, result) { result.count++; result.failed_at = current.delivery_tried_at; return result; }"
    ).each do |delivery|
      delivery['name'] = Pack::Report.find(delivery['report_id']).name
      delivery['count'] = delivery['count'].to_i
    end.sort! do |a,b|
      b['failed_at'] <=> a['failed_at']
    end
  end
end
