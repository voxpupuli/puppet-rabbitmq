# RabbitMQ Puppet Module

Jeff McCune <jeff@puppetlabs.com>

This module manages the RabbitMQ Middleware service.

This module is available on the [Forge](http://forge.puppetlabs.com/)

RabbitMQ Packages are published in the Puppet Labs ProSvc repository at:
[yum.puppetlabs.com](http://yum.puppetlabs.com/prosvc/)

This module has been tested against 2.4.1 and is known to work with
features known not to exist in earlier version.

# Quick Start

    class site::mcollective::middleware {

      $rabbitmq_plugins = [ 'amqp_client-2.3.1.ez', 'rabbit_stomp-2.3.1.ez' ]

      class { 'rabbitmq':
        config => template('rabbitmq/rabbitmq.conf'),
      }

      class { 'rabbitmq::service':
        ensure => running,
      }

      # Required for MCollective
      rabbitmq::plugin { $rabbitmq_plugins:
        ensure => present,
      }

    }

# TODO

* Manage a mcollective user account in RabbitMQ.

TODO - 
  need to understand what valid input for rabbitmq_user_list i
