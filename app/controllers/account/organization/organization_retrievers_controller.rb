# -*- encoding : UTF-8 -*-
class Account::Organization::OrganizationRetrieversController < Account::Organization::FiduceoController
  def update
    @fiduceo_retriever = FiduceoRetriever.find params[:id]
    @fiduceo_retriever.update(fiduceo_retriever_params)
    @fiduceo_retriever.update(journal_name: @fiduceo_retriever.journal.try(:name))
    flash[:success] = 'Modifié avec succès.'
    redirect_to account_organization_customer_path(@organization, @customer, tab: 'retrievers')
  end

private

  def fiduceo_retriever_params
    params.require(:fiduceo_retriever).permit(:journal_id)
  end
end
