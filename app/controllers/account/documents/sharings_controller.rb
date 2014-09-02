# -*- encoding : UTF-8 -*-
class Account::Documents::SharingsController < Account::AccountController
  def create
    users = User.find_by_emails(params[:email].split()) - [@user]

    packs = Pack.find(params[:pack_ids].split()).select { |p| p['owner_id'] == @user.id }

    packs.each do |pack|
      users.each do |user|
        unless user.packs.include?(pack)
          user.packs << pack
          pack.users << user
        end
      end
    end

    respond_to do |format|
      format.json{ render :json => {}, :status => :ok }
    end
  end

  def destroy_multiple
    own_pack_ids = @user.own_packs.distinct(:_id).map(&:to_s)
    pack_ids = @user.packs.distinct(:_id).map(&:to_s)
    clean_pack_ids = params[:pack_ids].select { |e| e.in?(pack_ids) && !e.in?(own_pack_ids) }
    packs = Pack.any_in(_id: clean_pack_ids)

    Pack.observers.disable :all do
      packs.each do |pack|
        @user['pack_ids'] = @user['pack_ids'] - [pack.id]
        pack['user_ids'] = pack['user_ids'] - [@user.id]
        pack.save
      end
    end
    @user.save

    respond_to do |format|
      format.json{ render :json => {}, :status => :ok }
    end
  end
end
