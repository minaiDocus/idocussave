# -*- encoding : UTF-8 -*-
class UpdatedPackPresenter
  def initialize(pack, start_at, end_at)
    @pack     = pack
    @start_at = start_at
    @end_at   = end_at
  end

  def new_pages
    @pack.pages.where("created_at >= ? AND created_at <= ?", @start_at, @end_at)
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
    @new_auto_retrieved_pages_count ||= new_pages.retrieved.count
  end
end
