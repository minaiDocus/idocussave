# -*- encoding : UTF-8 -*-
class DematboxDocumentPresenter
  def initialize(dematbox_document)
    @dematbox_document = dematbox_document
  end

  def response
    if @dematbox_document.valid?
      @response = '200:OK'
    else
      @response = '600:Argument value invalid'
    end
  end
end
