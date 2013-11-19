# -*- encoding : UTF-8 -*-
class FiduceoRetrieverObserver < Mongoid::Observer
  def before_save(fiduceo_retriever)
    if fiduceo_retriever.type == 'provider'
      fiduceo_retriever.bank_id = nil
    else
      fiduceo_retriever.provider_id = nil
    end
  end
end
