# -*- encoding : UTF-8 -*-
# Class to get formated pre assignments for admin dashboard
class PendingPreAssignmentService
  class << self
    def _pending(options = { sort: -1 })
      Pack::Piece.where(is_awaiting_pre_assignment: true).group(:pack_id).group(:pre_assignment_comment).order(created_at: :desc).includes(:pack)
    end


    def pending(options = { sort: -1 })
      _pending(options).map do |e|
        o = OpenStruct.new

        o.date           = e.created_at.try(:localtime)
        o.name           = e.pack.name.sub(/\s\d+\z/, '') if e.pack
        o.message        = e.pre_assignment_comment
        o.document_count = Pack::Piece.where(pack_id: e.pack_id, is_awaiting_pre_assignment: true).count

        o
      end
    end
  end
end
