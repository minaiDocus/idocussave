# -*- encoding : UTF-8 -*-
module AdminHelper
  def array_of_backup_function
    NeobeApi::METHOD_LIST.map{|m| [m,m.sub(/\(.*\)/,'')]}
  end

  def last_used_backup_function
    if params[:function_name]
      name = NeobeApi::METHOD_LIST.select{ |m| m.match(/#{params[:function_name]}.*/) }.first rescue ""
      [name,name.sub(/\(.*\)/,'')]
    else
      []
    end
  end

  def users_to_tokeninput_field(users)
    users.map{ |user| "{id: \"#{user.id}\", name: \"#{user.email}\"}"}.join(',')
  end

  def user_codes_to_tokeninput_field users
    users.sort { |a,b|
            if a.code and b.code.blank?
              -1
            elsif a.code.blank? and b.code
              1
            elsif a.code and b.code
              a.code <=> b.code
            end
          }.
          map{ |user| "{id: \"#{user.id}\", name: \"#{user.code.presence || user.email}\"}"}.
          join(',')
  end

  def organization_link(user)
    if user.organization
      link_to user.organization.try(:name), account_organization_path(user.organization)
    else
      nil
    end
  end

  def organization_status(user)
    if user.organization
      if user.organization.leader == user
        t('mongoid.models.organization.attributes.status.admin')
      elsif user.is_prescriber
        t('mongoid.models.organization.attributes.status.collaborator')
      else
        t('mongoid.models.organization.attributes.status.client')
      end
    else
      nil
    end
  end

  def email_state(email)
    klass = 'label'
    klass += ' label-success'   if email.state == 'processed'
    klass += ' label-important' if email.state.in? %w(error unprocessable)
    content_tag 'span', Email.state_machine.states[email.state].human_name, class: klass
  end

  def pre_assignment_delivery_state(delivery)
    klass = 'label'
    klass += ' label-success'   if delivery.state == 'sent'
    klass += ' label-important' if delivery.state == 'error'
    content_tag 'span', PreAssignmentDelivery.state_machine.states[delivery.state].human_name, class: klass
  end

  def file_size(size_in_octet)
    "%0.3f" % ((size_in_octet * 1.0) / 1048576.0)
  end

  def subscription_action_names_for_select
    EvaluateSubscriptionService::ACTIONS.map do |action|
      [t('subscription.actions.'+action.to_s), action]
    end
  end
end
