class CpEnv
  class NamespaceDeleter

    # Class to delete a namespace's AWS resources, and then the namespace
    # itself. The order is important, because deleting the AWS resources is
    # more likely to fail than deleting the namespace, and if the namespace is
    # deleted, we'll never try again to delete any AWS resources.
    #
    # This class will not do anything if a) there is still a
    # `namespaces/[cluster]/[namespace]` folder, or b) the namespace has
    # `is-production` set to `true`
    #
    # Assumption: The script which invokes this class is being called from the
    # root of an up to date working copy of the environments repo.

    attr_reader :namespace, :k8sclient

    CLUSTER = "live-1"
    KUBECONFIG_AWS_REGION = "eu-west-2"
    NAMESPACES = "namespaces/#{CLUSTER}.cloud-platform.service.justice.gov.uk"
    PRODUCTION_LABEL = "cloud-platform.justice.gov.uk/is-production"
    LABEL_TRUE = "true"
    EMPTY_MAIN_TF_URL = "https://raw.githubusercontent.com/ministryofjustice/cloud-platform-environments/master/namespace-resources/resources/main.tf"

    def initialize(args)
      @namespace= args.fetch(:namespace)
      # check_prerequisites
    end

    def delete
      if safe_to_delete?
        destroy_aws_resources
        delete_namespace
        clean_up
      end
    end

    private

    def check_prerequisites
      raise "No namespace supplied" if namespace.to_s.empty?

      %w(
        KUBECONFIG_AWS_ACCESS_KEY_ID
        KUBECONFIG_AWS_SECRET_ACCESS_KEY
        KUBECONFIG_S3_BUCKET
        KUBECONFIG_S3_KEY
        KUBE_CONFIG
        KUBE_CTX
        PIPELINE_TERRAFORM_STATE_LOCK_TABLE
        PIPELINE_STATE_BUCKET
      ).each do |var|
        env(var)
      end
    end

    def safe_to_delete?
      dir = File.join(NAMESPACES, namespace)
      if FileTest.directory?(File.join(NAMESPACES, namespace))
        log("red", "Namespace folder #{dir} exists. Will not delete.")
        return false
      end

      ns = kubeclient.get_namespaces.find { |n| n.metadata.name == namespace }

      if ns.nil?
        log("red", "Namespace #{namespace} not found in #{CLUSTER}. Will not delete.")
        return false
      end

      if ns.metadata.labels[PRODUCTION_LABEL] == LABEL_TRUE
        log("red", "Namespace #{namespace} has 'is-production: true'. Will not delete.")
        return false
      end

      true
    end

    def destroy_aws_resources
      create_empty_main_tf
      log("green", "Destroying AWS resources for namespace #{namespace}...")
      apply_namespace_dir(CLUSTER, namespace_dir)
    end

    def namespace_dir
      File.join(NAMESPACES, namespace)
    end

    def delete_namespace
      log("green", "Deleting namespace #{namespace}...")
      execute("kubectl delete namespace #{namespace}")
    end

    def kubeclient
      if @k8s_client.nil?
        kubeconfig = {
          s3client: Aws::S3::Client.new(
            region: KUBECONFIG_AWS_REGION,
            credentials: Aws::Credentials.new(
              env('KUBECONFIG_AWS_ACCESS_KEY_ID'),
              env('KUBECONFIG_AWS_SECRET_ACCESS_KEY')
            )
          ),
          bucket:       env('KUBECONFIG_S3_BUCKET'),
          key:          env('KUBECONFIG_S3_KEY'),
          local_target: env('KUBE_CONFIG'),
        }
        config_file = Kubeconfig.new(kubeconfig).fetch_and_store

        config = Kubeclient::Config.read(config_file)

        ctx = config.context(env('KUBE_CTX'))

        @k8s_client = Kubeclient::Client.new(
          ctx.api_endpoint,
          "v1",
          ssl_options: ctx.ssl_options,
          auth_options: ctx.auth_options
        )
      end

      @k8s_client
    end

    def create_empty_main_tf
      dir = File.join(namespace_dir, "resources")
      execute("mkdir -p #{dir}")
      content = URI::open(EMPTY_MAIN_TF_URL).read
      file = File.join(dir, "main.tf")
      File.open(file, 'w') { |f| f.puts(content) }
    end

    # Remove the empty main.tf we created, along
    # with the containing namespace folder
    def clean_up
      execute("rm -rf #{namespace_dir}")
    end

    def env(var)
      ENV.fetch(var)
    end
  end
end

__END__

#!/usr/bin/env ruby

require "#{File.dirname(__FILE__)}/../lib/orphaned_namespace_checker"

ENVIRONMENTS_GITHUB_REPO = 'cloud-platform-environments'

def main(namespace, destroy)
  check_prerequisites(namespace)

  # How to fetch the kubeconfig file, so we can talk to the cluster
  kubeconfig = {
    s3client: Aws::S3::Client.new(
      region: env('KUBECONFIG_AWS_REGION'),
      credentials: Aws::Credentials.new(env('KUBECONFIG_AWS_ACCESS_KEY_ID'), env('KUBECONFIG_AWS_SECRET_ACCESS_KEY'))
    ),
    bucket:                env('KUBECONFIG_S3_BUCKET'),
    key:                   env('KUBECONFIG_S3_KEY'),
    local_target:          env('KUBE_CONFIG'),
    context:               env('KUBE_CTX'),
  }
  config = Kubeconfig.new(kubeconfig).fetch_and_store

  k8s_client = ClusterNamespaceLister.new(
    config_file: config,
    context:     kubeconfig.fetch(:context)
  ).kubeclient

  puts
  puts "About to delete AWS resources for namespace: #{namespace}"
  puts

  tf_executable = "#{env('TERRAFORM_PATH')}/terraform"

  system("rm -rf main.tf .terraform") # clean up any leftover state from prior invocations

  tf_init(
    cluster: ENV.fetch('KUBERNETES_CLUSTER'),
    namespace: namespace,
    terraform: tf_executable,
  )

  # KUBE_CONFIG & KUBE_CTX env. vars must be in scope, or tf_plan/tf_apply will not work
  # see: https://www.terraform.io/docs/providers/kubernetes/index.html#argument-reference
  if destroy
    destroy_namespace(terraform: tf_executable, namespace: namespace, k8s_client: k8s_client)
  else
    tf_plan(tf_executable)
  end
end

def check_prerequisites(namespace)
  raise "Please supply namespace as the first command-line argument" if namespace.to_s.empty?

  %w(
    KUBECONFIG_AWS_ACCESS_KEY_ID
    KUBECONFIG_AWS_REGION
    KUBECONFIG_AWS_SECRET_ACCESS_KEY
    KUBECONFIG_S3_BUCKET
    KUBECONFIG_S3_KEY
    KUBERNETES_CLUSTER
    KUBE_CONFIG
    KUBE_CTX
    PIPELINE_TERRAFORM_STATE_LOCK_TABLE
    TERRAFORM_PATH
    TFSTATE_AWS_ACCESS_KEY_ID
    TFSTATE_AWS_REGION
    TFSTATE_AWS_SECRET_ACCESS_KEY
    TFSTATE_BUCKET
    TFSTATE_BUCKET_PREFIX
  ).each do |var|
    env(var)
  end

  raise "Namespace #{namespace} exists in the environments github repo\nAborting." if namespace_defined_in_code?(namespace)
end

def namespace_defined_in_code?(namespace)
  GithubNamespaceLister.new(
    env_repo: ENVIRONMENTS_GITHUB_REPO,
    cluster_name: env('KUBERNETES_CLUSTER'),
    github_token: env('GITHUB_TOKEN'),
  ).namespace_exists?(namespace)
end

def tf_init(args)
  tf_executable = args.fetch(:terraform)
  namespace = args.fetch(:namespace)
  cluster = args.fetch(:cluster)

  create_empty_main_tf(cluster)

  # Get AWS credentials from the environment, via bash, so that we don't
  # accidentally log them in cleartext, if all commands are logged.
  cmd = <<~EOF
  #{tf_executable} init \
    -backend-config="access_key=${TFSTATE_AWS_ACCESS_KEY_ID}" \
    -backend-config="secret_key=${TFSTATE_AWS_SECRET_ACCESS_KEY}" \
    -backend-config="bucket=#{env('TFSTATE_BUCKET')}" \
    -backend-config="key=#{env('TFSTATE_BUCKET_PREFIX')}#{cluster}/#{namespace}/terraform.tfstate" \
    -backend-config="dynamodb_table=${PIPELINE_TERRAFORM_STATE_LOCK_TABLE}" \
    -backend-config="region=#{env('TFSTATE_AWS_REGION')}"
  EOF
  system cmd
end

def create_empty_main_tf(cluster)
  url = EMPTY_MAIN_TF_URLS.fetch(cluster)
  content = open(url).read
  File.open('main.tf', 'w') { |f| f.puts(content) }
end

def tf_plan(tf_executable)
  # Terraform plan will only use AWS credentials from these, specific
  # variable names.
  cmd = <<~EOF
    AWS_ACCESS_KEY_ID=${TFSTATE_AWS_ACCESS_KEY_ID} \
    AWS_SECRET_ACCESS_KEY=${TFSTATE_AWS_SECRET_ACCESS_KEY} \
    #{tf_executable} plan
  EOF
  system cmd
end

def destroy_namespace(args)
  tf         = args.fetch(:terraform)
  namespace  = args.fetch(:namespace)
  k8s_client = args.fetch(:k8s_client)

  puts
  puts "Removing namespace #{namespace} from the cluster"
  puts

  tf_apply(tf)
  k8s_client.delete_namespace(namespace)
end

# Apply the terraform plan, with no confirmation step.
# This will actually delete AWS resources, so use with care.
def tf_apply(tf_executable)
  cmd = <<~EOF
    AWS_ACCESS_KEY_ID=${TFSTATE_AWS_ACCESS_KEY_ID} \
    AWS_SECRET_ACCESS_KEY=${TFSTATE_AWS_SECRET_ACCESS_KEY} \
    #{tf_executable} apply --auto-approve
  EOF
  system cmd
end

def env(var)
  ENV.fetch(var)
end

namespace = ARGV.shift
destroy = (ARGV.shift == 'destroy')

main(namespace, destroy)
