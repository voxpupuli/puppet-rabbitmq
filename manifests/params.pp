# Class: rabbitmq::params
#
#   The RabbitMQ Module configuration settings.
#
class rabbitmq::params {

  case $::osfamily {
    'Debian': {
      if $::config_mirrored_queues {
        $mirrored_queues_pkg_name = 'rabbitmq-server_2.8.7-1_all.deb'
        $mirrored_queues_pkg_url  = 'http://www.rabbitmq.com/releases/rabbitmq-server/v2.8.7/'
        $erlang_pkg_name          = 'erlang-nox'
      }
    }
    default: { }
  }

}
