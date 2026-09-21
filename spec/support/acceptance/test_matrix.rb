# frozen_string_literal: true

# https://mirror.stream.centos.org/SIGs/9-stream/messaging/x86_64/rabbitmq-38/Packages/r/
# https://mirror.stream.centos.org/SIGs/9-stream/messaging/x86_64/rabbitmq-4/Packages/r/
MESSAGING_SIG_VERSIONS = ['3.9', '4.2'].freeze
# Eg. Oracle Linux is EL but does not have centos-release-rabbitmq-* in repos
OS_WITH_MESSAGING_SIG_PKGS = %w[AlmaLinux CentOS Rocky].freeze

# Run tests on:
# * upstream versions (alias not provided by the CentOS Messaging SIG) on all the supported OSes
# * Messaging SIG versions on supported EL OSes
def run_test?(rabbitmq_version, os_name)
  if !MESSAGING_SIG_VERSIONS.include?(rabbitmq_version) ||
     (MESSAGING_SIG_VERSIONS.include?(rabbitmq_version) && OS_WITH_MESSAGING_SIG_PKGS.include?(os_name))
    true
  end
end

# Return params to enable CentOS Messaging SIG repos
def class_repo_params(rabbitmq_version, os_name)
  if MESSAGING_SIG_VERSIONS.include?(rabbitmq_version) && OS_WITH_MESSAGING_SIG_PKGS.include?(os_name)
    "repos_ensure => false,\nenable_centos_release => true,"
  else
    ''
  end
end
