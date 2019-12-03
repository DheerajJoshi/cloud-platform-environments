#!/usr/bin/env ruby

require File.join(".", File.dirname(__FILE__), "..", "lib", "cp_env")

require "pry-byebug"

CpEnv::NamespaceDeleter.new(namespace: "dstest-deva").delete
