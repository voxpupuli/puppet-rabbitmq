# rabbitmq

[![License](https://img.shields.io/github/license/voxpupuli/puppet-rabbitmq.svg)](https://github.com/voxpupuli/puppet-rabbitmq/blob/master/LICENSE)
[![Build Status](https://github.com/voxpupuli/puppet-rabbitmq/actions/workflows/ci.yml/badge.svg)](https://github.com/voxpupuli/puppet-rabbitmq/actions)
[![Puppet Forge](https://img.shields.io/puppetforge/v/puppet/rabbitmq.svg)](https://forge.puppetlabs.com/puppet/rabbitmq)
[![Puppet Forge - downloads](https://img.shields.io/puppetforge/dt/puppet/rabbitmq.svg)](https://forge.puppetlabs.com/puppet/rabbitmq)
[![Puppet Forge - endorsement](https://img.shields.io/puppetforge/e/puppet/rabbitmq.svg)](https://forge.puppetlabs.com/puppet/rabbitmq)
[![Puppet Forge - scores](https://img.shields.io/puppetforge/f/puppet/rabbitmq.svg)](https://forge.puppetlabs.com/puppet/rabbitmq)

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with rabbitmq](#setup)
    * [What rabbitmq affects](#what-rabbitmq-affects)
    * [Setup requirements](#setup-requirements)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
   * [RedHat module dependencies](#redhat-module-dependecies)
6. [Development - Guide for contributing to the module](#development)

## Overview

This module manages RabbitMQ (www.rabbitmq.com)

## Module Description
The rabbitmq module sets up rabbitmq and has a number of providers to manage
everything from vhosts to exchanges after setup.

This module has been tested against 3.5.x and 3.6.x (as well as earlier
versions) and is known to not support all features against versions
prior to 2.7.1.

## Setup

### What rabbitmq affects

* rabbitmq repository files.
* rabbitmq package.
* rabbitmq configuration file.
* rabbitmq service.

## Usage

All options and configuration can be done through interacting with the parameters
on the main rabbitmq class.
These are now documented via [Puppet Strings](https://github.com/puppetlabs/puppet-strings)

You can view example usage in [REFERENCE](REFERENCE.md).

**[puppet/epel](https://forge.puppet.com/modules/puppet/epel) is a soft dependency. If you're on CentOS 7 and don't want to require it, set `$require_epel` to `false`**

Version v13.2.0 and older also added an erlang repository on CentOS 7. That isn't used and can be safely removed.

## Reference

See [REFERENCE](REFERENCE.md).

## Development

This module is maintained by [Vox Pupuli](https://voxpupuli.org/). Voxpupuli
welcomes new contributions to this module, especially those that include
documentation and rspec tests. We are happy to provide guidance if necessary.

Please see [CONTRIBUTING](.github/CONTRIBUTING.md) for more details.

### Authors
* Jeff McCune <jeff@puppetlabs.com>
* Dan Bode <dan@puppetlabs.com>
* RPM/RHEL packages by Vincent Janelle <randomfrequency@gmail.com>
* Puppetlabs Module Team
* Voxpupuli Team
