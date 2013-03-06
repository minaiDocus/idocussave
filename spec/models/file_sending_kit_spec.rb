require "spec_helper"

describe FileSendingKit do
  it ".by_position" do
    organization = Organization.new
    f1 = FactoryGirl.create(:file_sending_kit, organization_id: organization.id, position: 3)
    f2 = FactoryGirl.create(:file_sending_kit, organization_id: organization.id, position: 5)
    f3 = FactoryGirl.create(:file_sending_kit, organization_id: organization.id, position: 1)
    results = FileSendingKit.by_position.entries
    results[0].title.should eq(f3.title)
    results[1].title.should eq(f1.title)
    results[2].title.should eq(f2.title)
  end
end
