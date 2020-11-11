class UserSerializer
  include FastJsonapi::ObjectSerializer
  attributes :id, :jefacture_account_id, :jefacture_api_key, :code
end