#!/usr/bin/env ruby

require File.join(".", File.dirname(__FILE__), "..", "lib", "cp_env")

namespace = ARGV.shift

CpEnv::NamespaceDeleter.new(namespace: namespace).delete
