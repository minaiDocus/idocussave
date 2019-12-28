# -*- encoding : utf-8 -*-
require 'spec_helper'

describe User do
  context 'customer' do
    before(:each) do
      User.destroy_all
      Subscription.destroy_all

      @user = FactoryBot.create(:user, first_name: 'user1', code: 'TS0001')
    end

    it ".create" do
      expect(@user).to be_persisted
    end

    it "#name" do
      expect(@user.name).to eq('User1 TEST')
    end

    it "#info" do
      expect(@user.info).to eq('TS0001 - TeSt - User1 TEST')
    end

    it "#format_name" do
      expect(@user.first_name).to eq('User1')
      expect(@user.last_name).to eq('TEST')
    end
  end

  context 'prescriber' do
    before(:each) do
      User.destroy_all

      @prescriber = FactoryBot.create(:prescriber)
      @fake_prescriber = FactoryBot.create(:fake_prescriber)
    end

    it 'should find fake prescribers' do
      expect(User.fake_prescribers.entries).to eq([@fake_prescriber])
    end

    it 'should not find true prescribers' do
      expect(User.fake_prescribers.entries).not_to include([@prescriber])
    end

    it 'should find not fake prescribers' do
      expect(User.not_fake_prescribers.entries).to eq([@prescriber])
    end

    it 'should not find not fake prescribers' do
      expect(User.not_fake_prescribers.entries).not_to include([@fake_prescriber])
    end
  end
end
