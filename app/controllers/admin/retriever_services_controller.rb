# frozen_string_literal: true

class Admin::RetrieverServicesController < Admin::AdminController
  before_action :load_budgea_config

  def index; end

  private

  def load_budgea_config
    bi_config = {
      url: "https://#{Budgea.config.domain}/2.0",
      c_id: Budgea.config.client_id,
      c_ps: Budgea.config.client_secret,
      c_ky: Budgea.config.encryption_key ? Base64.encode64(Budgea.config.encryption_key.to_json.to_s) : '',
      proxy: Budgea.config.proxy
    }.to_json
    @bi_config = Base64.encode64(bi_config.to_s)
  end
end
