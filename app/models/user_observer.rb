class UserObserver < Mongoid::Observer
  def before_validation(user)
    if user.email_code.blank? && !user.is_prescriber
      user.email_code = user.get_new_email_code
    end
  end

  def before_save(user)
    # FIXME use another way
    user.set_timestamps_of_addresses
    user.format_name
    user.set_inactive_at
  end

  def before_destroy(user)
    FiduceoUser.new(user, false).destroy if user.fiduceo_id.present?
  end
end
