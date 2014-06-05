class UserObserver < Mongoid::Observer
  def before_create(user)
    user.email_code = user.get_new_email_code unless user.is_prescriber
  end

  def after_create(user)
    request = Request.new
    request.requestable = user
    request.no_sync = true
    request.save
  end

  def after_save(user)
    if user.persisted?
      user.reload
      user.request.sync_with_requestable!
    end
  end

  def before_destroy(user)
    FiduceoUser.new(user, false).destroy rescue nil
  end
end
