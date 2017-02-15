class UpdateRetriever
  def initialize(retriever, params)
    @retriever = retriever
    @params    = params
  end

  def execute
    @retriever.name       = @params[:name]
    @retriever.journal_id = @params[:journal_id]

    if (@retriever.name_changed? || @retriever.journal_id_changed?) && !dyn_params_changed?
      @retriever.save
    else
      @retriever.confirm_dyn_params = true
      if @retriever.update(@params)
        @retriever.configure_connection
      end
    end
  end

private

  def dyn_params_changed?
    is_dyn_params_changed = false

    5.times.each do |i|
      param_name = "param#{i+1}"

      param = @retriever.send(param_name)
      new_param = @params[param_name]

      if new_param.present?
        if param.nil?
          is_dyn_params_changed = new_param[:value].present?
        elsif param['name'] != new_param[:name] || param['value'] != new_param[:value]
          is_dyn_params_changed = true
        end
      end

      break if is_dyn_params_changed
    end

    is_dyn_params_changed
  end
end
