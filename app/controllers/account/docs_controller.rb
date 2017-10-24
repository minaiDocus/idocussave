class Account::DocsController < Account::AccountController
  def download
    raise_not_found unless @user.is_prescriber

    dir = Rails.root.join('files', Rails.env, 'miscellaneous_docs')
    list = Dir.chdir(dir) { Dir["*"] }

    raise_not_found unless params[:name].in?(list)

    filepath = File.join dir, params[:name]
    mime_type = MIME::Types.type_for(filepath).first.content_type

    send_file filepath, type: mime_type, filename: params[:name], x_sendfile: true, disposition: 'inline'
  end

  private

  def raise_not_found
    raise ActionController::RoutingError.new('Not Found')
  end
end
