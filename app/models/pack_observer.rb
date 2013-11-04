class PackObserver < Mongoid::Observer
  def after_save(pack)
    Reporting.update(pack)
  end
end
