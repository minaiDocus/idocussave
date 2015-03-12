# -*- encoding : utf-8 -*-
require 'spec_helper'

describe User do
  context 'customer' do
    before(:each) do
      User.destroy_all
      Subscription.destroy_all

      @user = FactoryGirl.create(:user, first_name: 'user1', code: 'TS0001')
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
  end

  context 'prescriber' do
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
end
