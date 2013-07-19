require 'spec_helper'

describe 'rabbitmq::install' do

  let :default_params do
    {
      :package_ensure   => 'installed',
      :package_name     => 'rabbitmq-server',
      :package_provider => 'apt',
      :package_source   => '',
    }
  end

  context "on RHEL" do
    let(:facts) {{ :osfamily => 'RedHat' }}
    let(:params) { default_params.merge({
      :package_source => 'http://www.rabbitmq.com/releases/rabbitmq-server/v3.2.3/rabbitmq-server-3.2.3-1.noarch.rpm',
      :package_provider => 'rpm'
    })}
    it 'installs the rabbitmq package' do
      should contain_package('rabbitmq-server').with(
        'ensure'   => 'installed',
        'name'     => 'rabbitmq-server',
        'provider' => 'rpm',
        'source'   => 'http://www.rabbitmq.com/releases/rabbitmq-server/v3.2.3/rabbitmq-server-3.2.3-1.noarch.rpm'
      )
    end
  end

  context "on Debian" do
    let(:facts) {{ :osfamily => 'Debian', :lsbdistcodename => 'precise' }}
    let(:params) { default_params }

    it 'installs the rabbitmq package' do
      should contain_package('rabbitmq-server').with(
        'ensure'   => 'installed',
        'name'     => 'rabbitmq-server',
        'provider' => 'apt'
      )
    end
  end

end
