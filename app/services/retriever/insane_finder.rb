# TODO to be reworked
class Retriever::InsaneFinder
  def self.execute
    retrievers = Retriever.ready
    retrievers.each do |retriever|
      new(retriever).execute
    end
    insane_retrievers = Retriever.insane
    if insane_retrievers.count > 0
      addresses = Array(Settings.first.notify_errors_to)
      RetrieverMailer.notify_insane_retrievers(addresses).deliver
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
    operations = Operation.where(bank_account_id: @retriever.bank_accounts.used.pluck(:id))
    if operations.count > 0
      if (Date.today - operations.order(date: :desc).first.date).to_i > 7
        @retriever.is_sane = false if has_stopped && other_has_operations
      end
    end
    @retriever.save
  end

  def is_documents_working
    @retriever.is_sane = true
    if @retriever.temp_documents.count > 0
      if (Date.today - @retriever.temp_documents.order(created_at: :desc).first.created_at.to_date).to_i > 7
        @retriever.is_sane = false if has_stopped && other_has_documents
      end
    end
    @retriever.save
  end

  def has_stopped
    this_month = 0
    last_month = 0
    is_stopped = false
    if @retriever.bank?
      operations = Operation.where(bank_account_id: @retriever.bank_accounts.used.pluck(:id))
      this_month += operations.where("date <= ? AND date >= ?", Date.today, Date.today - 1.month).count
      last_month += operations.where("date < ? AND date >= ?", Date.today - 1.month, Date.today - 2.month).count
      is_stopped = true if (last_month - this_month) > last_month.to_f / 4
    elsif @retriever.provider?
      this_month = @retriever.temp_documents.where("created_at <= ? AND created_at >= ?", Time.now, Time.now - 1.month).count
      last_month = @retriever.temp_documents.where("created_at < ? AND created_at >= ?", Time.now - 1.month, Time.now - 2.month).count
      is_stopped = true if (last_month - this_month) > last_month.to_f / 4
    end
    is_stopped
  end

  def other_has_operations
    has_no_operations = 0
    same_retrievers = Retriever.ready.where(service_name: @retriever.service_name) - [@retriever]
    same_retrievers.each do |same_retriever|
      operations = Operation.where(bank_account_id: same_retriever.bank_accounts.used.pluck(:id))
      next unless operations.count > 0
      if (Date.today - operations.order(date: :desc).first.date).to_i > 7
        has_no_operations += 1
      end
    end
    (has_no_operations.to_f / same_retrievers.count.to_f) < 0.25
  end

  def other_has_documents
    has_no_documents = 0
    same_retrievers = Retriever.ready.where(service_name: @retriever.service_name) - [@retriever]
    same_retrievers.each do |same_retriever|
      next unless same_retriever.temp_documents.count > 0
      if (Date.today - same_retriever.temp_documents.order(created_at: :desc).first.created_at.to_date).to_i > 7
        has_no_documents += 1
      end
    end
    (has_no_documents.to_f / same_retrievers.count.to_f) < 0.5
  end
end
