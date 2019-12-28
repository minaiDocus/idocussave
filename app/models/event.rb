# -*- encoding : UTF-8 -*-
class Event < ApplicationRecord
  serialize :target_attributes

  belongs_to :user, optional: true
  belongs_to :organization, optional: true

  before_create :set_user_code

  def target
    if target_id
      target_type.split('/').each_with_index.map do |klass, i|
        begin
          klass.camelcase.constantize.find(target_id.split('/')[i])
        rescue
          nil
        end
      end.compact
    end
  end


  def self.search(contains)
    events = Event.all

    if contains[:user_contains] && contains[:user_contains][:code].present?
      if contains[:user_contains][:code].downcase.in?(%w(visiteur visitor))
        events = events.where(user_id: nil)
      else
        user = User.where(code: contains[:user_contains][:code]).first

        events = events.where(user_id: user.id) if user
      end
    end

    if contains[:created_at].present?
      contains[:created_at].each do |operator, value|
        events = events.where("created_at #{operator} ?", value) if operator.in?(['>=', '<='])
      end
    end

    events = events.where(id:          contains[:id])          if contains[:id].present?
    events = events.where(action:      contains[:action])      if contains[:action].present?
    events = events.where(target_type: contains[:target_type]) if contains[:target_type].present?
    events = events.where("target_name LIKE ?", "%#{contains[:target_name]}%") if contains[:target_name].present?

    events
  end

  private

  def set_user_code
    self.user_code ||= user.try(:code)
  end
end
