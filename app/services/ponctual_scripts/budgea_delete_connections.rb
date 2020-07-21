class PonctualScripts::BudgeaDeleteConnections < PonctualScripts::PonctualScript
  def self.execute    
    new().run
  end

  def self.rollback
    new().rollback
  end

  private

  def execute
    delete_users_budgea
    delete_retrievers_budgea    
  end

  def delete_users_budgea
    users = UsersBudgeaNotPresentIdocus.all
  end
end