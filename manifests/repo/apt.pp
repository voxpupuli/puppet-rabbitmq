# sets up the vmware hosted apt repo
class rabbitmq::repo::apt() {
  
  apt::source { 'rabbitmq':
    location    => 'http://www.rabbitmq.com/debian/',
    release     => 'testing',
    repos       => 'main',
    include_src => false,
    key         => 'RabbitMQ Release Signing Key <info@rabbitmq.com>',
    key_content => template('rabbitmq/rabbit.pub.key')
  }
}
