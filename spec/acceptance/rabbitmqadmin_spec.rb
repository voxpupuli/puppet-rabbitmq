# frozen_string_literal: true

require 'spec_helper_acceptance'

rabbitmq_version = ENV.fetch('BEAKER_FACTER_rabbitmq_version', '3.13')

describe 'rabbitmq::install::rabbitmqadmin class', if: run_test?(rabbitmq_version, fact('os.name')) do
  context 'downloads the cli tools' do
    it 'runs successfully' do
      pp = <<-EOS
        class { 'rabbitmq':
          rabbitmq_version      => '#{rabbitmq_version}',
          admin_enable          => true,
          service_manage        => true,
          #{class_repo_params(rabbitmq_version, fact('os.name'))}
        }
      EOS

      apply_manifest(pp, catch_failures: true)
    end

    describe file('/var/lib/rabbitmq/rabbitmqadmin') do
      it { is_expected.to be_file }
    end
  end

  context 'does nothing if service is unmanaged' do
    it 'runs successfully' do
      pp = <<-EOS
        class { 'rabbitmq':
          rabbitmq_version      => '#{rabbitmq_version}',
          admin_enable          => true,
          service_manage        => false,
          #{class_repo_params(rabbitmq_version, fact('os.name'))}
        }
      EOS

      shell('rm -f /var/lib/rabbitmq/rabbitmqadmin')
      apply_manifest(pp, catch_failures: true)
    end

    describe file('/var/lib/rabbitmq/rabbitmqadmin') do
      it { is_expected.not_to be_file }
    end
  end

  context 'works with specified default credentials' do
    it 'runs successfully' do
      # make sure credential change takes effect before admin_enable
      pp_pre = <<-EOS
        class { 'rabbitmq':
          rabbitmq_version      => '#{rabbitmq_version}',
          service_manage        => true,
          default_user          => 'foobar',
          default_pass          => 'bazblam',
          #{class_repo_params(rabbitmq_version, fact('os.name'))}
        }
      EOS

      pp = <<-EOS
        class { 'rabbitmq':
          rabbitmq_version      => '#{rabbitmq_version}',
          admin_enable          => true,
          service_manage        => true,
          default_user          => 'foobar',
          default_pass          => 'bazblam',
          #{class_repo_params(rabbitmq_version, fact('os.name'))}
        }
      EOS

      shell('rm -f /var/lib/rabbitmq/rabbitmqadmin')
      apply_manifest(pp_pre, catch_failures: true)
      apply_manifest(pp, catch_failures: true)
    end

    describe file('/var/lib/rabbitmq/rabbitmqadmin') do
      it { is_expected.to be_file }
    end
  end
end
