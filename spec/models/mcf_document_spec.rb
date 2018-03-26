require 'spec_helper'

describe McfDocument do
  let(:params) { {code: 'CAP%ABC', journal: 'VTJ', file64: 'abcdefgh', access_token: '123456789'} }

  it 'Should belongs to a user', :belongs_to_user do
    allow(User).to receive(:find_by_code).and_return( User.create({ id:1, code:'CAP%ABC' }) )

    mcf_doc = McfDocument.find_or_create(params)

    expect(mcf_doc.user).to be_an_instance_of(User)
    expect(mcf_doc.user.code).to eq 'CAP%ABC'
  end
end