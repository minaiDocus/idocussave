class Bridge::GetBank
  def self.execute(bridge_bank_id)
    BridgeBankin::Bank.find(id: bridge_bank_id)
  end
end

