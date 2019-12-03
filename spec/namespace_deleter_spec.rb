require "spec_helper"

describe CpEnv::NamespaceDeleter do
  let(:params) { {} }
  subject(:deleter) { described_class.new(params) }

  it "instantiates" do
    expect(deleter).to be_a(described_class)
  end
end
