require 'spec_helper'

describe Log::Visit do
  describe 'specifications' do
    # validations
    it { should validate_presence_of(:path)}
    it { should validate_presence_of(:number)}

    # fields
    it { should have_field(:path).of_type(String) }
    it { should have_field(:number).of_type(Integer) }
    it { should have_field(:created_at).of_type(Time) }

    # association
    it { should belong_to(:user).of_type(User).as_inverse_of(:log_visits) }
  end

  describe 'features' do
    before(:each) do
      @user1 = FactoryGirl.create(:user)
      @user2 = FactoryGirl.create(:user)
      @visit2 = Log::Visit.new(path: '/', user_id: @user2.id)
      @visit3 = Log::Visit.new(path: '/account/profile', user_id: @user1.id)
      @visit1 = Log::Visit.new(path: '/pages/ocr', user_id: @user1.id)
      @visit2.save
      @visit3.save
      @visit1.save
    end

    describe '.by_number' do
      subject(:visits) { Log::Visit.by_number.entries.map { |visit| visit.path } }

      it { subject[0].should eq(@visit1.path) }
      it { subject[1].should eq(@visit3.path) }
      it { subject[2].should eq(@visit2.path) }
    end

    describe '.for_user' do
      subject(:visits) { Log::Visit.for_user(@user1).entries.map { |visit| visit.path } }

      it { subject.count.should eq(2) }
      it { subject[0].should eq(@visit3.path) }
      it { subject[1].should eq(@visit1.path) }
    end
  end
end
