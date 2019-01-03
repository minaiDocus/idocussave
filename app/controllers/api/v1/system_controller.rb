class Api::V1::SystemController < ApiController
  # POST /api/v1/system/my_customers
  def my_customers
    customers = if @current_user.collaborator?
                  collab = Collaborator.new(@current_user)
                  collab.customers.collect{|c| { code: c.code.gsub(/[%]/, '_'), email: c.email, organization_code: c.organization.code.gsub(/[%]/, '_') } }
                else
                  [ { code: @current_user.code.gsub(/[%]/, '_'), email: @current_user.email, organization_code: @current_user.organization.code.gsub(/[%]/, '_') } ]
                end
    render json: customers.to_json
  end
end