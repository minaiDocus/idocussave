# -*- encoding : UTF-8 -*-
class Account::Organization::OrganizationRetrieversController < Account::Organization::FiduceoController
  def update
    @fiduceo_retriever = FiduceoRetriever.find params[:id]
    @fiduceo_retriever = FiduceoRetrieverService.update(@fiduceo_retriever, fiduceo_retriever_params)
    if @fiduceo_retriever.valid?
      flash[:success] = 'Modifié avec succès.'
    else
      flash[:error] = 'Une erreur est survenue lors de la modification.'
    end
    redirect_to account_organization_customer_path(@organization, @customer, tab: 'retrievers')
  end

private

  def fiduceo_retriever_params
    params.require(:fiduceo_retriever).permit(:journal_id)
  end
end
