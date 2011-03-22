node default {

  class { 'rabbitmq':
    config => template('rabbitmq/rabbitmq.conf'),
  }

}

