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

### Migrating from puppet-rabbitmq <= 15.x

**Module versions greater than 15.x drop support for RabbitMQ < 3.7.0**.
Please upgrade to a newer RabbitMQ version before upgrading the module.

**Module versions greater than 15.x switch to the new ini-style config file**
As of RabbitMQ 3.7.0 instead of a Erlang-style `rabbitmq.config` file, there are two configuration files, `rabbitmq.conf` (sysctl style) and `advanced.config`.
`puppet-rabbitmq` >= 16.x uses these two files - using the same parameters _should_ have the same result, but **users are strongly advised to test upgrade in a dev environment**.

If the new files contain all the desired settings, use the `purge_legacy_config_files` parameter to ensure legacy-format configuration files are removed.

## Reference

See [REFERENCE](REFERENCE.md).

## Limitations

Supported OSes and dependencies are given into metadata.json file.

This module is tested with the last RabbitMQ 3.x release (3.13) and 3.x release from CentOS Messaging SIG (3.8).
It may work with other releases >= 3.7.0 but it is not tested against them.
It definitely **does not support anymore RabbitMQ < 3.7.0** because of the new INI-style/sysctl configuration file.

## Development

This module is maintained by [Vox Pupuli](https://voxpupuli.org/). Voxpupuli
welcomes new contributions to this module, especially those that include
documentation and rspec tests. We are happy to provide guidance if necessary.

Please see [CONTRIBUTING](https://github.com/voxpupuli/.github/blob/master/CONTRIBUTING.md) for more details.

### Authors
* Jeff McCune <jeff@puppetlabs.com>
* Dan Bode <dan@puppetlabs.com>
* RPM/RHEL packages by Vincent Janelle <randomfrequency@gmail.com>
* Puppetlabs Module Team
* Voxpupuli Team
