# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe ReminderEmail do
  before(:each) do
    DatabaseCleaner.start
  end

  after(:each) do
    DatabaseCleaner.clean
  end

  context "simple" do
    before(:each) do
      ReminderEmail.destroy_all
      User.destroy_all

      @user1 = FactoryBot.create(:prescriber)
      @user1.options = UserOptions.create(user_id: @user1.id, is_upload_authorized: true)
      @user1.create_notify
      @organization = Organization.create(leader_id: @user1.id, name: 'iDocus', code: 'IDOC')
      @user2 = FactoryBot.create(:user)
      @user2.options = UserOptions.create(user_id: @user2.id, is_upload_authorized: true)
      @user2.create_notify
      @user3 = FactoryBot.create(:user)
      @user3.options = UserOptions.create(user_id: @user3.id, is_upload_authorized: true)
      @user3.create_notify

      @organization.customers << @user1
      @organization.customers << @user2
      @organization.customers << @user3

      @user2.find_or_create_subscription
      @user3.find_or_create_subscription

      @reminder_email = ReminderEmail.new(name: 'test_email1', subject: 'sujet 1', content: 'contenu1', organization_id: @organization.id)
      @reminder_email.save
    end

    it "#deliver" do
      @reminder_email.deliver
      expect(@reminder_email.delivered_user_ids).not_to be_empty
      expect(@reminder_email.processed_user_ids).not_to be_empty
      expect(@reminder_email.delivered_at.day).to eq(Time.now.day)
    end

    it "#deliver_if_its_time : now" do
      @reminder_email.delivery_day = Time.now.day
      @reminder_email.deliver_if_its_time
      expect(@reminder_email.processed_user_ids).not_to be_empty
      expect(@reminder_email.delivered_user_ids).not_to be_empty
    end

    it "#deliver_if_its_time : now + 1 " do
      @reminder_email.delivery_day = Time.now.day + 1
      @reminder_email.deliver_if_its_time
      expect(@reminder_email.processed_user_ids).to be_empty
      expect(@reminder_email.delivered_user_ids).to be_empty
    end
  end
end
