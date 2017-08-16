require 'spec_helper'

describe AccountingPlan do
  before(:all) do
    user = User.new(code: 'TS%0001')
    @accounting_plan = AccountingPlan.new
    @accounting_plan.user = user

    item = AccountingPlanItem.new
    item.third_party_name    = 'iDocus'
    item.third_party_account = '0IDOC'
    item.conterpart_account  = '1234'
    @accounting_plan.providers << item

    item = AccountingPlanItem.new
    item.third_party_name    = 'iDocus2'
    item.third_party_account = '0IDOC2'
    item.conterpart_account  = '5678'
    @accounting_plan.providers << item

    item = AccountingPlanItem.new
    item.third_party_name    = 'Virement'
    item.third_party_account = '0VIR'
    item.conterpart_account  = '9101'
    @accounting_plan.customers << item
  end

  it 'returns a XML' do
    data = "<?xml version=\"1.0\"?>
<data>
  <address>
    <name/>
    <contact/>
    <address_1/>
    <address_2/>
    <zip/>
    <city/>
    <country/>
    <country_code>FR</country_code>
  </address>
  <accounting_plans>
    <wsAccounts>
      <category>1</category>
      <associate>9101</associate>
      <name>Virement</name>
      <number>0VIR</number>
      <vat-account/>
    </wsAccounts>
    <wsAccounts>
      <category>2</category>
      <associate>1234</associate>
      <name>iDocus</name>
      <number>0IDOC</number>
      <vat-account/>
    </wsAccounts>
    <wsAccounts>
      <category>2</category>
      <associate>5678</associate>
      <name>iDocus2</name>
      <number>0IDOC2</number>
      <vat-account/>
    </wsAccounts>
  </accounting_plans>
</data>
"

    expect(@accounting_plan.to_xml).to eq(data)
  end

  it 'returns a CSV' do
    data = 'category,name,number,associate,customer_code
1,Virement,0VIR,9101,TS%0001
2,iDocus,0IDOC,1234,TS%0001
2,iDocus2,0IDOC2,5678,TS%0001'

    expect(@accounting_plan.to_csv).to eq(data)
  end
end
