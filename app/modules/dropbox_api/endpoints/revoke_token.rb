module DropboxApi::Endpoints
  class RevokeToken < DropboxApi::Endpoints::Rpc
    Method     = :post
    Path       = "/2/auth/token/revoke".freeze
    ResultType = DropboxApi::Results::VoidResult
    ErrorType  = nil

    # Disables the access token used to authenticate the call.
    add_endpoint :revoke_token do
      perform_request nil
    end
  end
end
