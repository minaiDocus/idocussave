# -*- encoding : UTF-8 -*-
class EventPresenter < BasePresenter
  presents :event
  delegate :id, :number, to: :event

  def created_at
    if event.created_at.today?
      h.l(event.created_at, format: '%H:%M:%S')
    elsif event.created_at.year == Time.now.year
      h.l(event.created_at, format: '%d %b %H:%M:%S')
    else
      h.l(event.created_at, format: '%d %b %Y %H:%M:%S')
    end
  end


  def user_code
    if event.user
      h.link_to event.user.code, [:admin, event.user]
    elsif event.user_code.present?
      event.user_code
    elsif event.action == 'visit'
      'Visiteur'
    else
      'iDocus'
    end
  end


  def action
    h.t("activerecord.models.event.actions.#{event.action}").downcase
  end


  def target_name
    if event.target_type.match('/')
      event.target_name.sub('/', ' / ')
    else
      event.target_name
    end
  end


  def target_type
    if event.target_type == 'page'
      'page'
    else
      event.target_type.split('/').map do |target_type|
        h.t("activerecord.models.#{target_type}.name").downcase
      end.join(' / ')
    end
  end
end
