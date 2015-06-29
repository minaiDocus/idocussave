raise 'This patch is for mime-types v2.6.1, update it.' unless MIME::Type::VERSION == '2.6.1'

class MIME::Types
  # Overwriting method to silence warning. See : https://github.com/mime-types/ruby-mime-types/issues/84.
  def index_extensions(mime_type)
    index_extensions!(mime_type)
  end
end
