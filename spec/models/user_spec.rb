# -*- encoding : utf-8 -*-
require 'spec_helper'

describe User do
  context "simple" do
    before(:each) do
      User.destroy_all
      Scan::Subscription.destroy_all
      
      @user = FactoryGirl.create(:user, first_name: 'user1', code: 'TS0001')
      @user2 = FactoryGirl.create(:user, first_name: 'user2', code: 'TS0002')
      
      @user3 = FactoryGirl.create(:user, first_name: 'User3', last_name: 'TEST', is_prescriber: true)
      @user3.save
      
      @prescripteur = FactoryGirl.create(:user, first_name: 'admin', is_prescriber: true)
      
      @prescripteur.clients << @user
      @prescripteur.clients << @user2
      @prescripteur.save
      
      @subscription = Scan::Subscription.new
      @subscription.user = @prescripteur
      @subscription.save
    end
      
    it ".create" do
      @user.should be_persisted
    end
   
    it "#name" do
      @user.name.should eq('User1 TEST') 
    end
    
    it "#info" do
      @user.info.should eq('TS0001 - TeSt - User1 TEST')
    end
    
    it "#format_name" do
      @user.first_name.should eq('User1')
      @user.last_name.should eq('TEST')
    end
    
    it "#update_clients" do 
      @prescripteur.clients.should_not be_empty
    end
    
    it "#find_or_create_scan_subscription should use find" do
      @prescripteur.find_or_create_scan_subscription.should eq (@subscription)
    end
    
    it "#find_or_create_scan_subscription should use create" do
      @user3.scan_subscriptions << @user3.find_or_create_scan_subscription
      @user3.scan_subscriptions.should_not be_empty  
    end    
  end
    
end
