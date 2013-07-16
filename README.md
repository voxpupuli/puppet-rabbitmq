#rabbitmq

####Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with rabbitmq](#setup)
    * [What rabbitmq affects](#what-rabbitmq-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with rabbitmq](#beginning-with-rabbitmq)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

##Overview

This module manages RabbitMQ (www.rabbitmq.com)

##Module Description
The rabbitmq module sets up rabbitmq and has a number of providers to manage
everything from vhosts to exchanges after setup.

This module has been tested against 2.7.1 and is known to not support
all features against earlier versions.

##Setup

###What rabbitmq affects

* rabbitmq repository files.
* rabbitmq package.
* rabbitmq configuration file.
* rabbitmq service.

###Beginning with rabbitmq

```puppet
include '::rabbitmq'
include '::rabbitmq::server'
```

##Usage

The rabbitmq module is currently split and requires you to include two seperate
classes to get full functionality.

##rabbitmq class

To begin with the rabbitmq class controls the installation of rabbitmq.  In here
you can control many parameters relating to the package and service, such as
disabling puppet support of the service:

```puppet
class { '::rabbitmq':
  service_manage => false
}
```

### rabbitmq::server

This class manages much of the configuration of RabbitMQ and has a lot of
parameters that can be tweaked:

```puppet
class { 'rabbitmq::server':
  port              => '5672',
  delete_guest_user => true,
}
```

### Clustering
To use RabbitMQ clustering and H/A facilities, use the rabbitmq::server
parameters `config\_cluster` and `cluster\_disk\_nodes`, e.g.:

```puppet
class { 'rabbitmq::server':
  config_cluster => true,
  cluster_disk_nodes => ['rabbit1', 'rabbit2'],
}
```

Currently all cluster nodes are registered as disk nodes (not ram).

**NOTE:** You still need to use `x-ha-policy: all` in your client 
applications for any particular queue to take advantage of H/A.

You should set the 'config_mirrored_queues' parameter if you plan
on using RabbitMQ Mirrored Queues within your cluster:

```puppet
class { 'rabbitmq::server':
  config_cluster => true,
  config_mirrored_queues => true,
  cluster_disk_nodes => ['rabbit1', 'rabbit2'],
}
```

##Reference

##Classes

* rabbitmq: Main class for installation and service management.
* rabbitmq::server: Main class for rabbitmq configuration/management.
* rabbitmq::install: Handles package installation.
* rabbitmq::params: Different configuration data for different systems.
* rabbitmq::service: Handles the rabbitmq service.
* rabbitmq::repo::apt: Handles apt repo for Debian systems.
* rabbitmq::repo::rhel: Handles yum repo for Redhat systems.

###Parameters

####`admin_enable`

If enabled sets up the management interface/plugin for RabbitMQ.

####`erlang_enable`

If true then we include an erlang module.

####`package\_ensure`

Determines the ensure state of the package.  Set to installed by default, but could
be changed to latest.

####`package\_name`

The name of the package to install.

####`package\_provider`

What provider to use to install the package.

####`package\_source`

Where should the package be installed from?

####`management\_port`

What port is the rabbitmq management interface on?

####`service\_ensure`

The state of the service.

####`service\_manage`

Determines if the service is managed.

####`service\_name`

The name of the service to manage.

####`version`

Sets the version to install.

##Native Types

### rabbitmq\_user

query all current users: `$ puppet resource rabbitmq\_user`

```
rabbitmq_user { 'dan':
  admin    => true,
  password => 'bar',
}
```

### rabbitmq\_vhost

query all current vhosts: `$ puppet resource rabbitmq\_vhost`

```puppet
rabbitmq_vhost { 'myhost':
  ensure => present,
}
```

### rabbitmq\_user\_permissions

```puppet
rabbitmq_user_permissions { 'dan@myhost':
  configure_permission => '.*',
  read_permission      => '.*',
  write_permission     => '.*',
}
```

### rabbitmq\_plugin

query all currently enabled plugins `$ puppet resource rabbitmq\_plugin`

```puppet
rabbitmq_plugin {'rabbitmq_stomp':
  ensure => present,
}
```

##Limitations

This module has been built on and tested against Puppet 2.7 and higher.

The module has been tested on:

* RedHat Enterprise Linux 5/6
* Debian 6/7
* CentOS 5/6
* Ubuntu 12.04

Testing on other platforms has been light and cannot be guaranteed.

##Development

Puppet Labs modules on the Puppet Forge are open projects, and community
contributions are essential for keeping them great. We can’t access the
huge number of platforms and myriad of hardware, software, and deployment
configurations that Puppet is intended to serve.

We want to keep it as easy as possible to contribute changes so that our
modules work in your environment. There are a few guidelines that we need
contributors to follow so that we can have a chance of keeping on top of things.

You can read the complete module contribution guide [on the Puppet Labs wiki.](http://projects.puppetlabs.com/projects/module-site/wiki/Module_contributing)

### Authors
* Jeff McCune <jeff@puppetlabs.com>
* Dan Bode <dan@puppetlabs.com>
* RPM/RHEL packages by Vincent Janelle <randomfrequency@gmail.com>
* Puppetlabs Module Team
