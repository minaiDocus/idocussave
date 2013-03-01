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
      
      @prescriber = FactoryGirl.create(:user, first_name: 'admin', is_prescriber: true)

      @prescriber.clients << @user
      @prescriber.clients << @user2
      @prescriber.save
      
      @subscription = Scan::Subscription.new
      @subscription.user = @prescriber
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
      @prescriber.clients.should_not be_empty
    end
    
    it "#find_or_create_scan_subscription should use find" do
      @prescriber.find_or_create_scan_subscription.should eq (@subscription)
    end
    
    it "#find_or_create_scan_subscription should use create" do
      @user3.scan_subscriptions << @user3.find_or_create_scan_subscription
      @user3.scan_subscriptions.should_not be_empty  
    end
  end

  context 'prescribers' do
    before(:each) do
      User.destroy_all

      @prescriber = FactoryGirl.create(:prescriber)
      @fake_prescriber = FactoryGirl.create(:fake_prescriber)
    end

    it 'should find fake prescribers' do
      User.fake_prescribers.entries.should eq([@fake_prescriber])
    end

    it 'should not find true prescribers' do
      User.fake_prescribers.entries.should_not include([@prescriber])
    end

    it 'should find not fake prescribers' do
      User.not_fake_prescribers.entries.should eq([@prescriber])
    end

    it 'should not find not fake prescribers' do
      User.not_fake_prescribers.entries.should_not include([@fake_prescriber])
    end
  end

  context "features" do
    it 'should propagate successfully stamp name' do
      prescriber = FactoryGirl.create(:prescriber)
      client1 = FactoryGirl.create(:user)
      client2 = FactoryGirl.create(:user)
      prescriber.clients << client1
      prescriber.clients << client2
      prescriber.save

      prescriber.update_attribute(:stamp_name, ':period')
      prescriber.propagate_stamp_name

      prescriber.reload
      client1.reload
      client2.reload
      prescriber.stamp_name.should eq(':period')
      client1.stamp_name.should eq(':period')
      client2.stamp_name.should eq(':period')
    end
  end
end
