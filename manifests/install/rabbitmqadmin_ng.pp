# @api private
#
# @summary Install rabbitmqadmin-ng
#
class rabbitmq::install::rabbitmqadmin_ng (
  String $rabbitmqadmin_ng_version = $rabbitmq::rabbitmqadmin_ng_version,
) {
  if versioncmp($rabbitmq::rabbitmq_version, '4.0') >= 0 {
    case $facts['os']['family'] {
      'Debian': {
        $deb_arch = $facts['os']['architecture'] ? {
          'aarch64' => 'arm64',
          default   => $facts['os']['architecture'],
        }

        $rabbitmqadmin_deb = "/var/lib/rabbitmq/rabbitmqadmin_${$rabbitmqadmin_ng_version}_${deb_arch}.deb"
        $rabbitmqadmin_url = "https://github.com/rabbitmq/rabbitmqadmin-ng/releases/download/v${$rabbitmqadmin_ng_version}/rabbitmqadmin_${$rabbitmqadmin_ng_version}_${deb_arch}.deb"
        $rabbitmqadmin_checksum_url = "${rabbitmqadmin_url}.sha512"

        archive::download { $rabbitmqadmin_deb:
          ensure      => present,
          url         => $rabbitmqadmin_url,
          digest_type => 'sha512',
          digest_url  => $rabbitmqadmin_checksum_url,
        }

        package { 'rabbitmqadmin':
          ensure  => $rabbitmqadmin_ng_version,
          source  => $rabbitmqadmin_deb,
          require => Archive::Download[$rabbitmqadmin_deb],
        }
      }
      'RedHat': {
        $rabbitmqadmin_url = "https://github.com/rabbitmq/rabbitmqadmin-ng/releases/download/v${$rabbitmqadmin_ng_version}/rabbitmqadmin-${$rabbitmqadmin_ng_version}-1.${facts['os']['architecture']}.rpm"

        package { 'rabbitmqadmin':
          ensure => $rabbitmqadmin_ng_version,
          source => $rabbitmqadmin_url,
        }
      }
      default: {
        $rabbitmqadmin_url = "https://github.com/rabbitmq/rabbitmqadmin-ng/releases/download/v${$rabbitmqadmin_ng_version}/rabbitmqadmin-${$rabbitmqadmin_ng_version}-${facts['os']['architecture']}-unknown-linux-gnu"

        file { '/usr/bin/rabbitmqadmin':
          owner  => 'root',
          group  => 'root',
          mode   => '0755',
          source => $rabbitmqadmin_url,
        }
      }
    }
  }
}
