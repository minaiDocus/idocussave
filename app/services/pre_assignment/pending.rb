# -*- encoding : UTF-8 -*-
# Class to get formated pre assignments for admin dashboard
class PreAssignment::Pending
  class << self
    def awaiting(options = { sort: -1 })
      Pack::Piece.awaiting_preassignment.group(:pack_id).group(:pre_assignment_comment).order(created_at: :desc).includes(:pack)
    end

    def unresolved(options = { sort: -1 })
      awaiting(options).map do |e|
        o = OpenStruct.new

        o.date           = e.created_at.try(:localtime)
        o.name           = e.pack.name.sub(/\s\d+\z/, '').sub(' all', '') if e.pack
        o.message        = e.pre_assignment_comment
        o.pre_assignment_state = e.pre_assignment_state
        o.document_count = Pack::Piece.awaiting_preassignment.where(pack_id: e.pack_id).count

        o
      end
    end
  end
end
