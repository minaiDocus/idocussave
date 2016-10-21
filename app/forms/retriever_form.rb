# -*- encoding : UTF-8 -*-
class RetrieverForm
  def initialize(retriever)
    @retriever = retriever
  end

  def submit(params)
    @retriever.assign_attributes(params)
    if @retriever.valid?
      @retriever.dyn_attr_name = dyn_attr['name']
      @retriever.dyn_attr_type = dyn_attr['type']
      @retriever.save
    else
      false
    end
  end

private

  def dyn_attr
    if @dyn_attr
      @dyn_attr
    else
      retriever_provider = RetrieverProvider.new
      if @retriever.provider?
        list = retriever_provider.providers
        id = @retriever.provider_id
      else
        list = retriever_provider.banks
        id = @retriever.bank_id
      end
      provider = list.select { |e| e['id'] == id }.first
      @dyn_attr = provider['fields'].select do |f|
        !f['name'].in?(['login', 'password'])
      end.first
    end
  end
end
