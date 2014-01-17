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
    @last_packs = Pack.desc(:created_at).limit(10)
    @awaiting_pre_assignments = Pack::Piece.collection.group keyf: "function(x) { name = x.name.split(' '); name.pop(); name = name.join(' '); return { name: name }; }",
                                                             cond: { is_awaiting_pre_assignment: true },
                                                             initial: { count: 0 },
                                                             reduce: "function(current, result) { return result.count++; }"
  end
end
