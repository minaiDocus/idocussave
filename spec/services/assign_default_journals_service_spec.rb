# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe AssignDefaultJournalsService do
  describe '#execute' do
    before(:all) do
      @user = FactoryGirl.create(:user, code: 'TS%0001')
      @user.options = UserOptions.create(user_id: @user.id)
      @collaborator = FactoryGirl.create(:prescriber, code: 'TS%C001')
      @organization = Organization.create(name: 'TEST', code: 'TS')
      @organization.members << @user
      @organization.members << @collaborator
    end

    context 'given 3 default journals' do
      before(:all) do
        @journal1 = AccountBookType.create(name: 'AC', description: '(Achat)',  is_default: true)
        @journal2 = AccountBookType.create(name: 'BQ', description: '(Banque)', is_default: true)
        @journal3 = AccountBookType.create(name: 'VT', description: '(Vente)',  is_default: true)
        @organization.account_book_types << @journal1
        @organization.account_book_types << @journal2
        @organization.account_book_types << @journal3
      end

      after(:all) do
        @journal1.destroy
        @journal2.destroy
        @journal3.destroy
      end

      context 'when maximum authorized is 1' do
        before(:all) do
          @user.options.update_attribute(:max_number_of_journals, 1)

          AssignDefaultJournalsService.new(@user, @collaborator).execute
        end

        after(:all) do
          @user.account_book_types.destroy_all
          @user.reload
          Event.destroy_all
        end

        it 'copy 1 journal' do
          expect(@user.account_book_types.entries.count).to eq 1
        end

        it 'copy journal AC' do
          expect(@user.account_book_types.first.name).to eq 'AC'
        end

        it 'create 1 event' do
          expect(Event.count).to eq 1
        end
      end

      context 'when maximum authorized is 2' do
        before(:all) do
          @user.options.update_attribute(:max_number_of_journals, 2)

          AssignDefaultJournalsService.new(@user, @collaborator).execute
        end

        after(:all) do
          @user.account_book_types.destroy_all
          @user.reload
          Event.destroy_all
        end

        it 'copy 2 journals' do
          expect(@user.account_book_types.size).to eq 2
        end

        it 'copy journal AC' do
          expect(@user.account_book_types.order(name: :asc).first.name).to eq 'AC'
        end

        it 'copy journal BQ' do
          expect(@user.account_book_types.order(name: :asc).last.name).to eq 'BQ'
        end

        it 'create 2 events' do
          expect(Event.count).to eq 2
        end
      end
    end

    context 'given 1 default journal with pre assignment' do
      before(:all) do
        @journal = FactoryGirl.build(:journal_with_preassignment)
        @journal.name        = 'AC'
        @journal.description = '(Achat)'
        @journal.is_default  = true
        @journal.save
        @organization.account_book_types << @journal
      end

      after(:all) do
        @journal.destroy
      end

      context 'when pre assignment is not authorized' do
        before(:all) do
          @user.options.update_attribute(:is_preassignment_authorized, false)

          AssignDefaultJournalsService.new(@user, @collaborator).execute
        end

        after(:all) do
          @user.account_book_types.destroy_all
          @user.reload
          Event.destroy_all
        end

        it 'does not copy journal' do
          expect(@user.account_book_types.size).to eq 0
        end

        it 'does not create event' do
          expect(Event.count).to eq 0
        end
      end

      context 'when pre assignment is authorized' do
        before(:all) do
          @user.options.update_attribute(:is_preassignment_authorized, true)

          AssignDefaultJournalsService.new(@user, @collaborator).execute
        end

        after(:all) do
          @user.account_book_types.destroy_all
          @user.reload
          Event.destroy_all
        end

        it 'copy 1 journal' do
          expect(@user.account_book_types.size).to eq 1
        end

        it 'copy journal AC' do
          expect(@user.account_book_types.order(name: :asc).first.name).to eq 'AC'
        end

        it 'create 1 event' do
          expect(Event.count).to eq 1
        end
      end
    end

    context 'when user already have journal AC' do
      before(:all) do
        @journal1 = AccountBookType.create(name: 'AC', description: '(Achat)', is_default: true)
        @organization.account_book_types << @journal1
        @journal2 = AccountBookType.create(name: 'AC', description: '(Achat)')
        @user.account_book_types << @journal2

        AssignDefaultJournalsService.new(@user, @collaborator).execute
      end

      after(:all) do
        @journal1.destroy
        @journal2.destroy
        @user.account_book_types.destroy_all
        @user.reload
        Event.destroy_all
      end

      it 'does not copy journal AC' do
        expect(@user.account_book_types.count).to eq 1
      end

      it 'create 0 event' do
        expect(Event.count).to eq 0
      end
    end

    context 'given 3 default journals, 1 without pre assignment and 2 with' do
      before(:all) do
        @journal1 = AccountBookType.create(name: 'BQ', description: '(Banque)', is_default: true)

        @journal2 = FactoryGirl.build(:journal_with_preassignment)
        @journal2.name = 'AC'
        @journal2.description = '(Achat)'
        @journal2.entry_type = 2
        @journal2.is_default = true
        @journal2.save

        @journal3 = FactoryGirl.build(:journal_with_preassignment)
        @journal3.name = 'VT'
        @journal3.description = '(Vente)'
        @journal3.entry_type = 3
        @journal3.is_default = true
        @journal3.save

        @organization.account_book_types << @journal1
        @organization.account_book_types << @journal2
        @organization.account_book_types << @journal3
      end

      after(:all) do
        @journal1.save
        @journal2.save
        @journal3.save
      end

      context 'when pre assignment is authorized and 1 slot available' do
        before(:all) do
          @user.options.update(
            is_preassignment_authorized: true,
            max_number_of_journals: 1
          )
          AssignDefaultJournalsService.new(@user, @collaborator).execute
        end

        after(:all) do
          @user.account_book_types.destroy_all
          @user.reload
          Event.destroy_all
        end

        it 'copy 1 journal' do
          expect(@user.account_book_types.count).to eq 1
        end

        it 'copy journal AC' do
          expect(@user.account_book_types.first.name).to eq 'AC'
        end

        it 'create 1 event' do
          expect(Event.count).to eq 1
        end
      end
    end
  end
end
