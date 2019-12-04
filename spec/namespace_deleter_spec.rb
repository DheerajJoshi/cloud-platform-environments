require "spec_helper"

describe CpEnv::NamespaceDeleter do
  let(:metadata_prod) { double(Kubeclient::Resource, name: "prod", labels: { "cloud-platform.justice.gov.uk/is-production" => "true" }) }
  let(:metadata_nonprod) { double(Kubeclient::Resource, name: "nonprod", labels: { "cloud-platform.justice.gov.uk/is-production" => "false" }) }

  let(:prod) { double(Kubeclient::Resource, metadata: metadata_prod) }
  let(:nonprod) { double(Kubeclient::Resource, metadata: metadata_nonprod) }

  let(:namespaces) { [prod, nonprod] }

  let(:namespace) { "nonprod" }

  let(:params) { { namespace: namespace } }

  subject(:deleter) { described_class.new(params) }

  let(:terraform_apply) { "terraform apply --auto-approve" }
  let(:k8s_client) { double(Kubeclient::Client, get_namespaces: namespaces) }

  before do
    allow(Kubeclient::Client).to receive(:new).and_return(k8s_client)
    allow($stdout).to receive(:puts).at_least(:once) # suppress output from 'log' method
  end

  context "when the namespace does not exist in the cluster" do
    let(:namespace) { "mynamespace" }

    it "does not delete AWS resources" do
      expect(Open3).to_not receive(:capture3).with(terraform_apply)
      deleter.delete
    end

    it "does not delete the namespace" do
      expect(k8s_client).to_not receive(:delete_namespace)
      deleter.delete
    end
  end

  context "when the namespace source code folder exists" do

    before do
      allow(FileTest).to receive(:directory?).with("namespaces/live-1.cloud-platform.service.justice.gov.uk/#{namespace}").and_return(true)
    end

    it "does not delete AWS resources" do
      expect(Open3).to_not receive(:capture3).with(terraform_apply)
      deleter.delete
    end

    it "does not delete the namespace" do
      expect(k8s_client).to_not receive(:delete_namespace)
      deleter.delete
    end
  end

  context "when the namespace has is-production true" do
    let(:namespace) { "prod" }

    it "does not delete AWS resources" do
      expect(Open3).to_not receive(:capture3).with(terraform_apply)
      deleter.delete
    end

    it "does not delete the namespace" do
      expect(k8s_client).to_not receive(:delete_namespace)
      deleter.delete
    end
  end

  context "when the namespace should be deleted" do
    it "deletes AWS resources" do
      expect_execute(terraform_apply, "", "")
      deleter.delete
    end

    it "deletes the namespace" do
      expect(k8s_client).to receive(:delete_namespace).with(namespace)
      deleter.delete
    end
  end
end
