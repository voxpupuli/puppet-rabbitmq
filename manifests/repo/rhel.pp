# Makes sure that the RabbitMQ repo is installed
# https://www.rabbitmq.com/docs/install-rpm
#
# @api private
#
# @param primary_gpg_key
# @param erlang_repo_gpg_key
# @param server_repo_gpg_key
#
class rabbitmq::repo::rhel (
  String[1] $primary_gpg_key = $rabbitmq::rpm_repo_primary_gpg_key,
  String[1] $erlang_repo_gpg_key = $rabbitmq::rpm_repo_erlang_gpg_key,
  String[1] $server_repo_gpg_key = $rabbitmq::rpm_repo_server_gpg_key,
) {
  # gpg-pubkey-6026dfca-573adfde is the primary GPG key
  exec { "rpm --import ${primary_gpg_key}":
    path   => ['/bin','/usr/bin','/sbin','/usr/sbin'],
    unless => 'rpm -q gpg-pubkey-6026dfca-573adfde 2>/dev/null',
    before => File['rabbitmq.repo'],
  }
  # gpg-pubkey-cc4bbe5b-60490155 is erlang repo key
  exec { "rpm --import ${erlang_repo_gpg_key}":
    path   => ['/bin','/usr/bin','/sbin','/usr/sbin'],
    unless => 'rpm -q gpg-pubkey-cc4bbe5b-60490155 2>/dev/null',
    before => File['rabbitmq.repo'],
  }
  # gpg-pubkey-26208342-60327a6a is the server repo key
  exec { "rpm --import ${server_repo_gpg_key}":
    path   => ['/bin','/usr/bin','/sbin','/usr/sbin'],
    unless => 'rpm -q gpg-pubkey-26208342-60327a6a 2>/dev/null',
    before => File['rabbitmq.repo'],
  }

  # Use a file instead of yumrepo as "Continuation lines that yum supports (for the baseurl, for example) are not supported."
  # https://forge.puppet.com/modules/puppetlabs/yumrepo_core/reference
  file { 'rabbitmq.repo':
    path   => '/etc/yum.repos.d/rabbitmq.repo',
    group  => 'root',
    mode   => '0644',
    owner  => 'root',
    source => 'puppet:///modules/rabbitmq/rabbitmq.repo',
  }
}
