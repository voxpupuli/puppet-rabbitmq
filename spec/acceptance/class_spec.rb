require 'spec_helper_acceptance'

describe 'rabbitmq class:' do
  case fact('osfamily')
  when 'RedHat'
    package_name = 'rabbitmq-server'
    service_name = 'rabbitmq-server'
  when 'SUSE'
    package_name = 'rabbitmq-server'
    service_name = 'rabbitmq-server'
  when 'Debian'
    package_name = 'rabbitmq-server'
    service_name = 'rabbitmq-server'
  when 'Archlinux'
    package_name = 'rabbitmq'
    service_name = 'rabbitmq'
  end

  context 'default class inclusion' do
    it 'runs successfully' do
      pp = <<-EOS
      class { 'rabbitmq': }
      if $::osfamily == 'RedHat' {
        class { 'erlang': epel_enable => true}
        Class['erlang'] -> Class['rabbitmq']
      }
      EOS

      # Apply twice to ensure no errors the second time.
      apply_manifest(pp, catch_failures: true)
      expect(apply_manifest(pp, catch_changes: true).exit_code).to be_zero
    end

    describe package(package_name) do
      it { is_expected.to be_installed }
    end

    describe service(service_name) do
      it { is_expected.to be_enabled }
      it { is_expected.to be_running }
    end
  end

  context 'disable and stop service' do
    it 'runs successfully' do
      pp = <<-EOS
      class { 'rabbitmq':
        service_ensure => 'stopped',
      }
      if $::osfamily == 'RedHat' {
        class { 'erlang': epel_enable => true}
        Class['erlang'] -> Class['rabbitmq']
      }
      EOS

      apply_manifest(pp, catch_failures: true)
    end

    describe service(service_name) do
      it { is_expected.not_to be_enabled }
      it { is_expected.not_to be_running }
    end
  end

  context 'service is unmanaged' do
    it 'runs successfully' do
      pp_pre = <<-EOS
      class { 'rabbitmq': }
      if $::osfamily == 'RedHat' {
        class { 'erlang': epel_enable => true}
        Class['erlang'] -> Class['rabbitmq']
      }
      EOS

      pp = <<-EOS
      class { 'rabbitmq':
        service_manage => false,
        service_ensure  => 'stopped',
      }
      if $::osfamily == 'RedHat' {
        class { 'erlang': epel_enable => true}
        Class['erlang'] -> Class['rabbitmq']
      }
      EOS

      apply_manifest(pp_pre, catch_failures: true)
      apply_manifest(pp, catch_failures: true)
    end

    describe service(service_name) do
      it { is_expected.to be_enabled }
      it { is_expected.to be_running }
    end
  end

  context 'binding on all interfaces' do
    it 'runs successfully' do
      pp = <<-EOS
      class { 'rabbitmq':
        service_manage    => true,
        port              => 5672,
        admin_enable      => true,
        node_ip_address   => '0.0.0.0'
      }
      EOS

      apply_manifest(pp, catch_failures: true)
    end

    describe service(service_name) do
      it { is_expected.to be_running }
    end
    describe port(5672) do
      it { is_expected.to be_listening.on('0.0.0.0').with('tcp') }
    end
    describe port(15_672) do
      it { is_expected.to be_listening.on('0.0.0.0').with('tcp') }
    end
    describe port(25_672) do
      xit 'Is on 55672 instead on older rmq versions' do
        is_expected.to be_listening.on('0.0.0.0').with('tcp')
      end
    end
  end

  context 'binding to localhost only' do
    it 'runs successfully' do
      pp = <<-EOS
      class { 'rabbitmq':
        service_manage    => true,
        port              => 5672,
        admin_enable      => true,
        node_ip_address   => '127.0.0.1'
      }
      EOS

      apply_manifest(pp, catch_failures: true)
    end

    describe service(service_name) do
      it { is_expected.to be_running }
    end
    describe port(5672) do
      it { is_expected.to be_listening.on('127.0.0.1').with('tcp') }
    end
    describe port(15_672) do
      it { is_expected.to be_listening.on('127.0.0.1').with('tcp') }
    end
    # This listens on all interfaces regardless of these settings
    describe port(25_672) do
      xit 'Is on 55672 instead on older rmq versions' do
        is_expected.to be_listening.on('0.0.0.0').with('tcp')
      end
    end
  end

  context 'different management_ip_address and node_ip_address' do
    it 'runs successfully' do
      pp = <<-EOS
      class { 'rabbitmq':
        service_manage        => true,
        port                  => 5672,
        admin_enable          => true,
        node_ip_address       => '0.0.0.0',
        management_ip_address => '127.0.0.1'
      }
      EOS

      apply_manifest(pp, catch_failures: true)
    end

    describe service(service_name) do
      it { is_expected.to be_running }
    end
    describe port(5672) do
      it { is_expected.to be_listening.on('0.0.0.0').with('tcp') }
    end
    describe port(15_672) do
      it { is_expected.to be_listening.on('127.0.0.1').with('tcp') }
    end
    describe port(25_672) do
      xit 'Is on 55672 instead on older rmq versions' do
        is_expected.to be_listening.on('0.0.0.0').with('tcp')
      end
    end
  end
end
