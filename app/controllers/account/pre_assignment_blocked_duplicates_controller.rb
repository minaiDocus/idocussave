class Account::PreAssignmentBlockedDuplicatesController < Account::OrganizationController
  # GET /account/organizations/:organization_id/pre_assignment_blocked_duplicates
  def index
    @duplicates = Pack::Report::Preseizure
      .blocked_duplicates
      .where(user_id: customer_ids)
      .search(search_terms(params[:duplicate_contains]))
      .order("#{sort_real_column} #{sort_direction}")
      .page(params[:page])
      .per(params[:per_page])
  end

  # POST /account/organizations/:organization_id/pre_assignment_blocked_duplicates/update_multiple
  def update_multiple
    preseizures = Pack::Report::Preseizure.blocked_duplicates.where(user_id: customer_ids, id: params[:duplicate_ids])

    if preseizures.size > 0
      if params.keys.include?('unblock') && !params.keys.include?('approve_block')
        count = UnblockPreseizures.new(preseizures.map(&:id), @user).execute

        flash[:success] = '1 pré-affectation a été débloqué.' if count == 1
        flash[:success] ||= "#{count} pré-affectations ont été débloqués."
      elsif params.keys.include?('approve_block') && !params.keys.include?('unblock')
        count = preseizures.update_all(marked_as_duplicate_at: Time.now, marked_as_duplicate_by_user_id: @user.id)

        flash[:success] = '1 pré-affectation a été marqué comme étant un doublon.' if count == 1
        flash[:success] ||= "#{count} pré-affectations ont été marqués comme étant des doublons."
      end
    else
      flash[:error] = 'Vous devez sélectionner au moins une pré-affectation.'
    end

    redirect_to account_organization_pre_assignment_blocked_duplicates_path(@organization)
  end

  private

  def sort_column
    if params[:sort].in? %w(created_at piece_name piece_number third_party amount date)
      params[:sort]
    else
      'created_at'
    end
  end
  helper_method :sort_column

  def sort_real_column
    column = sort_column
    return 'pack_pieces.name' if column == 'piece_name'
    return 'cached_amount' if column == 'amount'
    column
  end

  def sort_direction
    if params[:direction].in? %w(asc desc)
      params[:direction]
    else
      'desc'
    end
  end
  helper_method :sort_direction
end