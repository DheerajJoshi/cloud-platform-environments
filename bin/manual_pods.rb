#!/usr/bin/env ruby

require File.join(".", File.dirname(__FILE__), "..", "lib", "cp_env")

# This script will delete any pods which are:
#
#   * not part of a ReplicaSet
#   * and not in kube-system
#   * and have been running for more than 2 days
#
# Such pods prevent the node-recycler from draining a node to
# replace it.
#
# Developers need to run manual pods for tasks such as port-forwarding
# to a database, but there's no good reason for such a pod to still be
# running after 48 hours. If pods should always be running, they should
# be part of a deployment (and hence a ReplicaSet).

CpEnv::ManuallyCreatedPodDeleter.new.run
