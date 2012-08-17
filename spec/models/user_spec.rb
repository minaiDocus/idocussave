# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe User do
  context "simple" do
    before(:each) do
      User.destroy_all
      Scan::Subscription.destroy_all
    end
      
    it ".create" do
      user = User.new(email: 'test@example.com', password: 'secret', password_confirmation: 'secret')
      user.should be_valid
      user.save
      user.should be_persisted
    end
   
    it "#name" do
      user = User.new(first_name: 'bob', last_name: 'alice', email: 'test@example.com')
      user.name.should eq('bob alice') 
    end
    
    it "#info" do
      user = User.new(first_name: 'Alice', last_name: 'Bob', code: 'SW001', company: 'StarWar')
      user.info.should eq('SW001 - StarWar - Alice Bob')
    end
    
    it "#format_name" do
      user = User.new(email: 'test@example.com', first_name: 'claude', last_name: 'jean', password: 'secret', password_confirmation: 'secret')
      user.save
      user.first_name.should eq('Claude')
      user.last_name.should eq('JEAN')
    end
    
    it "#update_clients" do
      user = User.new(email: 'test@example.com', first_name: 'Jean', last_name: 'CLAUDE', password: 'secret', password_confirmation: 'secret')
      user2 = User.new(email: 'test2@example.com', first_name: 'Julie', last_name: 'leboeuf', password: 'secret', password_confirmation: 'secret')
      
      prescripteur = User.new(email: 'admin@example.com', first_name: 'dupont', last_name: 'Dupond', password: 'secret', password_confirmation: 'secret', is_prescriber: 'true')
      user.save
      user2.save
      prescripteur.save
      
      prescripteur.clients << user
      prescripteur.clients << user2
      
      prescripteur.clients.should_not be_empty
    end
    
    it "#find_or_create_scan_subscription should use find" do
      user = User.new(email: 'test@example.com', first_name: 'Jean', last_name: 'CLAUDE', password: 'secret', password_confirmation: 'secret', is_prescriber: true)
      subscription = Scan::Subscription.new
      user.save
      subscription.user = user
      subscription.prescriber = user
      subscription.save
      user.find_or_create_scan_subscription.should eq (subscription)
    end
    
    it "#find_or_create_scan_subscription should use create" do
      user = User.new(email: 'test@example.com', first_name: 'Jean', last_name: 'CLAUDE', password: 'secret', password_confirmation: 'secret', is_prescriber: true)
      user.save
      user.scan_subscriptions << user.find_or_create_scan_subscription
      user.scan_subscriptions.should_not be_empty
    
    end    
  end
    
end
