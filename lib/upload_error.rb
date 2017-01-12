module UploadError
  class Error < RuntimeError
    attr_accessor :message

    def initialize(message = '')
      @message = message
    end
  end

  class CorruptedFile < Error
  end


  class UnprocessableEntity < Error
  end


  class ProtectedFile < Error
  end


  class InvalidFormat < Error
  end


  class NotAuthorised < Error
  end
end
