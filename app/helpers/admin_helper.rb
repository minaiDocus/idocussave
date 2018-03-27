# -*- encoding : UTF-8 -*-
# FIXME : whole check on file
module AdminHelper
  def users_to_tokeninput_field(users)
    users.map { |user| "{id: \"#{user.id}\", name: \"#{user.email}\"}" }.join(',')
  end


  def user_codes_to_tokeninput_field(users)
    users.sort do |a, b|
      if a.code && b.code.blank?
        -1
      elsif a.code.blank? && b.code
        1
      elsif a.code && b.code
        a.code <=> b.code
      end
    end.map { |user| "{id: \"#{user.id}\", name: \"#{user.code.presence || user.email}\"}" } .join(',')
  end

  def organization_status(user, organization)
    status = if organization.admins.include?(user)
      'admin'
    elsif user.collaborator?
      'collaborator'
    else
      'customer'
    end

    t('activerecord.models.organization.attributes.status.' + status)
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
    '%0.3f' % ((size_in_octet * 1.0) / 1_048_576.0)
  end

  def news_target_audience_options
    News::TARGET_AUDIENCES.map do |target_audience|
      [t('simple_form.labels.news.target_audiences.' + target_audience), target_audience]
    end
  end
end
