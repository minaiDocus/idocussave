require "spec_helper"

describe FileSendingKit do
  it ".by_position" do
    f1 = FactoryGirl.create(:file_sending_kit, position: 3)
    f2 = FactoryGirl.create(:file_sending_kit, position: 5)
    f3 = FactoryGirl.create(:file_sending_kit, position: 1)
    results = FileSendingKit.by_position.entries
    expect(results[0].title).to eq(f3.title)
    expect(results[1].title).to eq(f1.title)
    expect(results[2].title).to eq(f2.title)
  end
end
