# -*- encoding : UTF-8 -*-
class Account::Organization::RetrieversController < Account::OrganizationController
  before_filter :load_customer

  def index
  end

  def update
    @fiduceo_retriever = FiduceoRetriever.find params[:id]
    @fiduceo_retriever.update(fiduceo_retriever_params)
    @fiduceo_retriever.update(journal_name: @fiduceo_retriever.journal.try(:name))
    flash[:success] = 'Modifié avec succès.'
    redirect_to account_organization_customer_retrievers_path(@organization, @customer)
  end

private

  def fiduceo_retriever_params
    params.require(:fiduceo_retriever).permit(:journal_id)
  end

  def load_customer
    @customer = customers.find_by_slug! params[:customer_id]
    raise Mongoid::Errors::DocumentNotFound.new(User, slug: params[:customer_id]) unless @customer
  end
end
