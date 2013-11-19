class UserObserver < Mongoid::Observer
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
