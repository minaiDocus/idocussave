# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe ReminderEmail do
  context "simple" do
    before(:each) do
      ReminderEmail.destroy_all
      User.destroy_all
      
      @user1 = FactoryGirl.create(:prescriber)
      @organization = Organization.create(leader_id: @user1.id, name: 'iDocus', code: 'IDOC')
      @user2 = FactoryGirl.create(:user)
      @user3 = FactoryGirl.create(:user)

      @organization.members << @user1
      @organization.members << @user2
      @organization.members << @user3

      @user2.find_or_create_scan_subscription
      @user3.find_or_create_scan_subscription
      
      @reminder_email = ReminderEmail.new(name: 'test_email1', subject: 'sujet 1', content: 'contenu1', organization_id: @organization.id)
      @reminder_email.save
    end
    
    it "#deliver" do
      @reminder_email.deliver
      @reminder_email.delivered_user_ids.should_not be_empty
      @reminder_email.processed_user_ids.should_not be_empty
      @reminder_email.delivered_at.day.should eq(Time.now.day)    
    end
    
    it "#deliver_if_its_time : now" do
      @reminder_email.delivery_day = Time.now.day
      @reminder_email.deliver_if_its_time
      @reminder_email.processed_user_ids.should_not be_empty
      @reminder_email.delivered_user_ids.should_not be_empty
    end
    
    it "#deliver_if_its_time : now + 1 " do
      @reminder_email.delivery_day = Time.now.day + 1
      @reminder_email.deliver_if_its_time
      @reminder_email.processed_user_ids.should be_empty
      @reminder_email.delivered_user_ids.should be_empty
    end
    
  end
  
end