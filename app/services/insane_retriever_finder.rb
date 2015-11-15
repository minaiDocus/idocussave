class InsaneRetrieverFinder
  def self.execute
    retrievers = FiduceoRetriever.scheduled
    retrievers.each do |retriever|
      new(retriever).execute
    end
    insane_retrievers = FiduceoRetriever.insane
    if insane_retrievers.count > 0
      addresses = Array(Settings.notify_errors_to)
      FiduceoRetrieverMailer.notify_insane_retrievers(addresses).deliver
    end
  end

  def initialize(retriever)
    @retriever = retriever
  end

  def execute
    if @retriever.bank?
      is_operations_working
    elsif @retriever.provider?
      is_documents_working
    end
  end

  def is_operations_working
    @retriever.is_sane = true
    @retriever.bank_accounts.configured.each do |bank_account|
      if @retriever.is_sane
        if bank_account.operations.count > 0
          if (Date.today - bank_account.operations.desc(:date).first.date).to_i > 7
            if has_stopped && other_has_operations
              @retriever.is_sane = false
            end
          end
        end
      end
    end
    @retriever.save
  end

  def is_documents_working
    @retriever.is_sane = true
    if @retriever.temp_documents.count > 0
      if (Date.today - @retriever.temp_documents.desc(:created_at).first.created_at.to_date).to_i > 7
        if has_stopped && other_has_documents
          @retriever.is_sane = false
        end
      end
    end
    @retriever.save
  end

  def has_stopped
    this_month = 0
    last_month = 0
    is_stopped = false
    if @retriever.bank?
      @retriever.bank_accounts.configured.each do |bank_account|
        unless is_stopped
          this_month += bank_account.operations.where(:date.lte => Date.today, :date.gte => Date.today - 1.month).count
          last_month += bank_account.operations.where(:date.lt => Date.today - 1.month, :date.gte => Date.today - 2.month).count
          is_stopped = true if (last_month - this_month) > last_month / 4
        end
      end
    elsif @retriever.provider?
      this_month = @retriever.temp_documents.where(:created_at.lte => Time.now, :created_at.gte => Time.now - 1.month).count
      last_month = @retriever.temp_documents.where(:created_at.lt => Time.now - 1.month, :created_at.gte => Time.now - 2.month).count
      is_stopped = true if (last_month - this_month) > last_month / 4
    end
    is_stopped
  end

  def other_has_operations
    bank_account_number = 0
    has_no_operations = 0
    same_retrievers = FiduceoRetriever.scheduled.where(service_name: @retriever.service_name) - [@retriever]
    same_retrievers.each do |same_retriever|
      same_retriever.bank_accounts.configured.each do |bank_account|
        bank_account_number += 1
        if bank_account.operations.count > 0
          if (Date.today - bank_account.operations.desc(:date).first.date).to_i > 7
            has_no_operations += 1
          end
        end
      end
    end
    (has_no_operations.to_f / bank_account_number.to_f) < 0.25
  end

  def other_has_documents
    has_no_documents = 0
    same_retrievers = FiduceoRetriever.scheduled.where(service_name: @retriever.service_name) - [@retriever]
    same_retrievers.each do |same_retriever|
      if same_retriever.temp_documents.count > 0
        if (Date.today - same_retriever.temp_documents.desc(:created_at).first.created_at.to_date).to_i > 7
          has_no_documents += 1
        end
      end
    end
    (has_no_documents.to_f / same_retrievers.count.to_f) < 0.5
  end
end
