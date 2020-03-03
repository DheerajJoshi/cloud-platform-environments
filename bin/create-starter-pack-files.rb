#!/usr/bin/env ruby

require "erb"
require "optparse"
require "yaml"


require File.join(".", File.dirname(__FILE__), "..", "lib", "cp_env")

TEMPLATES_DIR = "../starter-pack-resources/templates"
RESOURCES_DIR = "../starter-pack-resources"

class StarterPackErb
  include ERB::Util
  attr_accessor :options, :template

  def initialize(options, template)
    @namespace = options[:namespace]
    @cluster_name = options[:cluster_name]
    @template = template
  end

  def render()
    ERB.new(@template).result(binding)
  end

  def save(file)
    File.open(file, "w+") do |f|
      f.write(render)
    end
  end

end

def get_options
  options = parse_options
  options
end

def helloworld_yaml_templates
  Dir["#{TEMPLATES_DIR}/cloud-platform-helloworld-ruby-app/*.yaml"]
end

def multicontainer_yaml_templates
  Dir["#{TEMPLATES_DIR}/cloud-platform-multi-container-demo-app/*.yaml"]
end

def create_deploy_helloworld_rubyapp(deploy_dir)

  log("green", "Creating cloud-platform-helloworld-ruby-app k8o files for #{get_options[:namespace]}")

  dir = File.join(deploy_dir, "cloud-platform-helloworld-ruby-app")
  system("mkdir #{dir}")

  helloworld_yaml_templates.each { |template| 
    list = StarterPackErb.new(get_options, File.read(template))
    list.save(File.join(dir, File.basename(template)))
  }

  log("green", "applying for cluster #{get_options[:cluster]}")

  set_kube_context(get_options[:cluster])

  execute("kubectl -n #{get_options[:namespace]} apply -f #{dir}")

  log("green", "Done.")

end


def create_deploy_multi_container_demo_app(deploy_dir)

  log("green", "Creating cloud-platform-multi-container-demo-app k8o files for #{get_options[:namespace]}")

  dir = File.join(deploy_dir, "cloud-platform-multi-container-demo-app")
  system("mkdir #{dir}")

  multicontainer_yaml_templates.each { |template| 
    list = StarterPackErb.new(get_options, File.read(template))
    list.save(File.join(dir, File.basename(template)))
  }

  log("green", "applying for cluster #{get_options[:cluster]}")

  set_kube_context(get_options[:cluster])

  execute("kubectl -n #{get_options[:namespace]} apply -f #{dir}")

  log("green", "Done.")

end



def parse_options

  options = {namespace: "starter-pack", cluster_name: "pk-conc-1", cluster: "pk-conc-1.cloud-platform.service.justice.gov.uk" }

  OptionParser.new { |opts|
    opts.on("-n", "--namespace NAMESPACE-NAME", "Namespace name") do |name|
      options[:namespace] = "starter-pack"
    end

    opts.on("-c", "--cluster-name CLUSTER-NAME", "Cluster name where the app needs to be deployed") do |name|
      options[:cluster_name] = name
    end

    opts.on("-c", "--cluster CLUSTER", "Cluster domain where the app needs to be deployed") do |name|
      options[:cluster] = name
    end

    opts.on_tail("-h", "--help", "Show help message") do
      puts opts
      exit
    end
  }.parse!

  options
end

def main

  deploy_dir = File.join(RESOURCES_DIR, "deploy")
  system("mkdir #{deploy_dir}")

  create_deploy_helloworld_rubyapp deploy_dir
  create_deploy_multi_container_demo_app deploy_dir
end

main

