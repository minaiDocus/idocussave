# -*- encoding : UTF-8 -*-
class UpdatedPackPresenter
  def initialize(pack, time)
    @pack       = pack
    @time       = time
    @start_time = time.beginning_of_day
    @end_time   = time.end_of_day
  end

  def new_pages
    @pack.pages.where(:created_at.gte => @start_time, :created_at.lte => @end_time)
  end

  def new_pages_count
    new_pages.count
  end

  def new_scanned_pages_count
    @new_scanned_pages_count ||= new_pages.scanned.count
  end

  def new_uploaded_pages_count
    @new_uploaded_pages_count ||= new_pages.uploaded.count
  end

  def new_dematbox_scanned_pages_count
    @new_dematbox_scanned_pages_count ||= new_pages.dematbox_scanned.count
  end

  def new_auto_retrieved_pages_count
    @new_auto_retrieved_pages_count ||= new_pages.fiduceo.count
  end
end
