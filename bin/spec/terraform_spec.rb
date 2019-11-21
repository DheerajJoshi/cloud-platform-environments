require "spec_helper"

describe Terraform do
  let(:cluster) { "live-1.cloud-platform.service.justice.gov.uk" }
  let(:namespace) { "mynamespace" }
  let(:dir) { "namespaces/#{cluster}/#{namespace}" }
  let(:success) { double(success?: true) }
  let(:failure) { double(success?: false) }

  let(:env_vars) {
    {
      "PIPELINE_STATE_BUCKET" => "bucket",
      "PIPELINE_STATE_KEY_PREFIX" => "key-prefix/",
      "PIPELINE_TERRAFORM_STATE_LOCK_TABLE" => "lock-table",
      "PIPELINE_STATE_REGION" => "region",
      "PIPELINE_CLUSTER_STATE_BUCKET" => "cluster-bucket",
      "PIPELINE_CLUSTER_STATE_KEY_PREFIX" => "state-key-prefix/",
    }
  }

  let(:params) { {
    cluster: cluster,
    namespace: namespace,
    dir: dir
  } }

  subject(:tf) { described_class.new(params) }

  context "terraform 0.11" do
    before do
      allow(FileTest).to receive(:exists?).with("#{dir}/resources/versions.tf").and_return(false)
    end

    describe "plan" do
      it "runs terraform plan" do
        env_vars.each do |key, val|
          expect(ENV).to receive(:fetch).with(key).at_least(:once).and_return(val)
        end
        allow(FileTest).to receive(:directory?).and_return(true)

        tf_dir = "#{dir}/resources"

        tf_init = "cd #{tf_dir}; terraform init -backend-config=\"bucket=bucket\" -backend-config=\"key=key-prefix/live-1.cloud-platform.service.justice.gov.uk/mynamespace/terraform.tfstate\" -backend-config=\"dynamodb_table=lock-table\" -backend-config=\"region=region\""

        tf_plan = "cd #{tf_dir}; terraform plan -var=\"cluster_name=live-1\" -var=\"cluster_state_bucket=cluster-bucket\" -var=\"cluster_state_key=state-key-prefix/live-1/terraform.tfstate\"  | grep -vE '^(\\x1b\\[0m)?\\s{3,}'"

        expect_execute(tf_init, "", success)
        expect_execute(tf_plan, "", success)
        expect($stdout).to receive(:puts)

        tf.plan
      end
    end

    describe "apply" do
      it "applies terraform files" do
        env_vars.each do |key, val|
          expect(ENV).to receive(:fetch).with(key).at_least(:once).and_return(val)
        end
        allow(FileTest).to receive(:directory?).and_return(true)

        tf_dir = "#{dir}/resources"

        tf_init = "cd #{tf_dir}; terraform init -backend-config=\"bucket=bucket\" -backend-config=\"key=key-prefix/live-1.cloud-platform.service.justice.gov.uk/mynamespace/terraform.tfstate\" -backend-config=\"dynamodb_table=lock-table\" -backend-config=\"region=region\""

        tf_apply = "cd #{tf_dir}; terraform apply -var=\"cluster_name=live-1\" -var=\"cluster_state_bucket=cluster-bucket\" -var=\"cluster_state_key=state-key-prefix/live-1/terraform.tfstate\" -auto-approve"

        expect_execute(tf_init, "", success)
        expect_execute(tf_apply, "", success)
        expect($stdout).to receive(:puts)

        tf.apply
      end
    end

  end
end
