class UpdateJournalService
  def self.execute(autorized_customers, journal, params)
    if params[:client_ids].present?
      authorized_customer_ids = autorized_customers.map(&:id).map(&:to_s)
      unmodifiable_client_ids = journal.client_ids.map(&:to_s).select do |client_id|
        !client_id.in? authorized_customer_ids
      end
      updated_client_ids = params[:client_ids].select do |client_id|
        client_id.in? authorized_customer_ids
      end
      params[:client_ids] = unmodifiable_client_ids + updated_client_ids
    end
    journal.update_attributes(params)
  end
end
