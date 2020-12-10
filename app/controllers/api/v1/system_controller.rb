# frozen_string_literal: true

class Api::V1::SystemController < ApiController
  skip_before_action :authenticate_current_user, only: ['piece_url']
  skip_before_action :verify_rights, only: ['piece_url']

  # POST /api/v1/system/my_customers
  def my_customers
    customers = if @current_user.collaborator?
                  collab = Collaborator.new(@current_user)
                  collab.customers.collect { |c| { code: c.code.gsub(/[%]/, '_'), email: c.email, organization_code: c.organization.code.gsub(/[%]/, '_') } }
                else
                  [{ code: @current_user.code.gsub(/[%]/, '_'), email: @current_user.email, organization_code: @current_user.organization.code.gsub(/[%]/, '_') }]
                end
    render json: customers.to_json
  end

  def piece_url
    params_list = params[:pieces_name].to_s.tr('[]"\'', '').split(',').map{ |el| el.strip }
    list_url = {}

    Pack::Piece.where(name: params_list).each do |piece|
      list_url["#{piece.name}"] = Domains::BASE_URL + piece.try(:get_access_url)
    end

    render json: { list_url: list_url }, status: 200
  end
end
