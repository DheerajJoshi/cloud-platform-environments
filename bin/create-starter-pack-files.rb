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
  options = {namespace: "poornima-dev", cluster_name: "live-1", cluster: "live-1.cloud-platform.service.justice.gov.uk" }
  options
end

def helloworld_yaml_templates
  Dir["#{TEMPLATES_DIR}/cloud-platform-helloworld-rubyapp/*.yaml"]
end

def multicontainer_yaml_templates
  Dir["#{TEMPLATES_DIR}/cloud-platform-multi-container-app/*.yaml"]
end

def create_deploy_helloworld_rubyapp(deploy_dir)

  log("green", "Creating cloud-platform-helloworld-app k8o files for {#get_options[:namespace]}")

  dir = File.join(deploy_dir, "cloud-platform-helloworld-app")
  system("mkdir #{dir}")

  helloworld_yaml_templates.each { |template| 
    list = StarterPackErb.new(get_options, File.read(template))
    list.save(File.join(dir, File.basename(template)))
  }

  log("green", "applying for cluster #{get_options[:cluster]}")

  set_kube_context(get_options[:cluster])

  Open3.capture3("kubectl -n #{get_options[:namespace]} apply -f #{dir}")

  log("green", "Done.")

end


def create_deploy_multi_container_app(deploy_dir)

  log("green", "Creating cloud-platform-multi-container-app k8o files for {#get_options[:namespace]}")

  dir = File.join(deploy_dir, "cloud-platform-multi-container-app")
  system("mkdir #{dir}")

  multicontainer_yaml_templates.each { |template| 
    list = StarterPackErb.new(get_options, File.read(template))
    list.save(File.join(DEPLOY_DIR, File.basename(template)))
  }

  log("green", "applying for cluster #{get_options[:cluster]}")

  set_kube_context(get_options[:cluster])

  Open3.capture3("kubectl -n #{get_options[:namespace]} apply -f #{dir}")

  log("green", "Done.")

end

def main

  deploy_dir = File.join(RESOURCES_DIR, "deploy")
  system("mkdir #{deploy_dir}")

  create_deploy_helloworld_rubyapp deploy_dir
  # create_deploy_multi_container_app deploy_dir
end

main
