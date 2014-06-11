class UserObserver < Mongoid::Observer
  def before_validation(user)
    if user.email_code.blank? && !user.is_prescriber
      user.email_code = user.get_new_email_code
    end
  end

  def after_create(user)
    request = Request.new
    request.requestable = user
    request.no_sync = true
    request.save
  end

  def before_save(user)
    # FIXME use another way
    user.set_timestamps_of_addresses
    user.format_name
    user.set_inactive_at
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
