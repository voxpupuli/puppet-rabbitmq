# RabbitMQ Puppet Module

Jeff McCune <jeff@puppetlabs.com>

This module manages the RabbitMQ Middleware service.

It is designed to work with MCollective.

This module is available on the [Forge](http://forge.puppetlabs.com/)

RabbitMQ Packages are published in the Puppet Labs ProSvc repository at:
[yum.puppetlabs.com](http://yum.puppetlabs.com/prosvc/)

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

* Delete the default guest user account
* Manage a mcollective user account in RabbitMQ.
* Model user accounts as a defined resource type.

