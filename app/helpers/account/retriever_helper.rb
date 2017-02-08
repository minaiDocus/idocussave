module Account::RetrieverHelper
  def retriever_dyn_attrs(retriever)
    hsh = {}
    5.times do |i|
      param_name = "param#{i+1}"
      data = retriever.send(param_name)
      if data
        data = data.dup # data is frozen due to encryption so we use a duplicate
        data['error'] = retriever.errors[param_name].first
        data['value'] = nil if data['type'] == 'password'
        hsh[param_name] = data
      end
    end
    hsh.to_json
  end
end
