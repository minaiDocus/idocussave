# -*- encoding : UTF-8 -*-
class CreateDematboxDocumentPresenter
  def initialize(dematbox_document)
    @dematbox_document = dematbox_document
  end


  def response
    @response = if @dematbox_document.valid?
                        '200:OK'
                      else
                        '600:Argument value invalid'
                      end
  end
end
