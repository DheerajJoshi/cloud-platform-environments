require "bundler/setup"
require "kubeclient"
require "open3"
require "open-uri"
require "aws-sdk-s3"

class CpEnv
end

require File.join(File.dirname(__FILE__), "cp_env", "pipeline")
require File.join(File.dirname(__FILE__), "cp_env", "terraform")
require File.join(File.dirname(__FILE__), "cp_env", "kubeconfig")
