class Request
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :requester, class_name: 'User', inverse_of: :requests
  belongs_to :requestable, polymorphic: true

  attr_accessor :no_sync

  field :action,            type: String, default: ''
  field :relation_action,   type: String, default: ''
  field :attribute_changes, type: Hash,   default: {}

  validates_inclusion_of :action,          in: ['', 'create', 'update', 'destroy']
  validates_inclusion_of :relation_action, in: ['', 'update']

  before_save :set_action_and_state

  def self.active
    any_of({ :action.in => ['create','update','destroy'] }, { :relation_action.in => ['update'] })
  end

  def with_sync
    no_sync.in? [nil, false]
  end

  def diff(attributes = self.attribute_changes)
    old_attributes = requestable.attributes
    requestable.assign_attributes(attributes)
    result = requestable.valid?
    added = requestable.changes.
                        reject { |_,v| v.nil? }.
                        inject({}) { |ops, (k,v)| ops[k] = v[1]; ops; }
    added = added.reject { |k,_| !k.to_sym.in?(requestable.requestable_on) }
    requestable.assign_attributes(old_attributes)
    [result, added]
  end

  def sync_with_requestable!
    if with_sync && self.action.in?(['', 'update'])
      update_attributes(attribute_changes: diff[1])
    end
  end

  def set_attributes(attributes = {}, options = {}, requester=nil)
    if self.action == 'create'
      self.no_sync = true
      requestable.update_attributes(attributes, options)
    elsif action.in?(['', 'update'])
      result, added = diff(attributes)
      if result
        added = added.reject { |k,_| k.match(/_ids/) }
        update_attributes(attribute_changes: added, requester_id: requester.try(:id))
      else
        false
      end
    end
  end

  def accept!
    if action == 'destroy' && requestable_type == 'AccountBookType'
      requestable.destroy && destroy
    else
      self.no_sync = true
      requestable.update_attributes(attribute_changes)
      reset_to_default!
      update_relation_action_status!
    end
  end

  def apply_attribute_changes
    requestable.assign_attributes self.attribute_changes
  end

  def reset_to_default
    assign_attributes(action: '', relation_action: '', attribute_changes: {}, requester_id: nil)
  end

  def reset_to_default!
    reset_to_default; save
  end

  def update_relation_action_status!
    if requestable_type == 'User'
      if requestable.account_book_type_ids.map(&:to_s).sort != requestable.requested_account_book_type_ids.map(&:to_s).sort
        update_attribute(:relation_action, 'update') unless self.relation_action == 'update'
      else
        update_attribute(:relation_action, '') unless self.relation_action == ''
      end
    elsif requestable_type == 'AccountBookType'
      if requestable.client_ids.map(&:to_s).sort != requestable.requested_client_ids.map(&:to_s).sort
        update_attribute(:relation_action, 'update') unless self.relation_action == 'update'
      else
        update_attribute(:relation_action, '') unless self.relation_action == ''
      end
    end
  end

  def status
    self.action.present? ? self.action : self.relation_action
  end

private

  def set_action_and_state
    if self.action.in?(%w(create destroy))
      self.attribute_changes = {}
    else
      if self.attribute_changes.any?
        self.action = 'update'
      elsif self.relation_action != 'update'
        reset_to_default
      end
    end
  end
end