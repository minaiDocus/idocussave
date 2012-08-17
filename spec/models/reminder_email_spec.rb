# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe ReminderEmail do
  context "simple" do
    before(:each) do
      ReminderEmail.destroy_all
      User.destroy_all
      
      @user1 = FactoryGirl.create(:user)
      @user2 = FactoryGirl.create(:user)
      @user3 = FactoryGirl.create(:user)
      
      @user1.is_prescriber = true
      @user1.clients << @user2
      @user1.clients << @user3
      
      @user1.save
      
      @reminder_email = ReminderEmail.new(name: 'test_email1', subject: 'sujet 1', content: 'contenu1', user_id: @user1.id)
      @reminder_email.save
      
    end
    
    it "#deliver" do
      @reminder_email.deliver
      @reminder_email.delivered_user_ids.should_not be_empty
      @reminder_email.processed_user_ids.should_not be_empty
      @reminder_email.delivered_at.day.should eq(Time.now.day)    
    end
    
    it "#deliver_if_its_time : now" do
      @reminder_email.delivered_at = Time.now
      @reminder_email.deliver_if_its_time
      @reminder_email.processed_user_ids.should_not be_empty
      @reminder_email.delivered_user_ids.should_not be_empty
    end
    
    it "#deliver_if_its_time : now + 1 " do
      @reminder_email.delivered_at = Time.now + 1.day
      @reminder_email.deliver_if_its_time
      @reminder_email.processed_user_ids.should be_empty
      @reminder_email.delivered_user_ids.should be_empty
    end
    
  end
  
end