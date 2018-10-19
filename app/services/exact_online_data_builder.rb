class ExactOnlineDataBuilder
  def initialize(delivery)
    @preseizures  = delivery.preseizures
    @organization = delivery.organization
    @user         = delivery.user
  end

  def execute
    response = { data_built: true }
    response[:data] = {
                        "JournalCode":  journal,
                        "GeneralJournalEntryLines":  [
                          {
                            "Account":   "12dfde12-8f68-433c-a10a-2f2b42985596",
                            "AmountFC":  "1",
                            "Date":      "2015-12-10",
                            "GLAccount": "4ccac6cd-01b4-4b4d-a0d4-90eef58a7b09"
                          }
                        ]
                      }.to_json.to_s
    response
  end

  #private

  def journal
    exact_online.refresh_session_if_needed
    exact_online.clear_client
    p exact_online.client.journals
  end

  def exact_online
    @exact_online ||= @organization.exact_online
  end

end
