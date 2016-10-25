module Account::RetrieverHelper
  def retriever_dyn_attrs(retriever)
    hsh = {}
    4.times do |i|
      param_name = "param#{i+1}"
      data = retriever.send(param_name)
      if data
        data['error'] = retriever.errors[param_name].first
        data['value'] = nil if data['type'] == 'password'
        hsh[param_name] = data
      end
    end
    hsh.to_json
  end
end
