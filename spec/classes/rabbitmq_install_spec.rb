require 'spec_helper'

describe 'rabbitmq' do

  context "on RHEL" do
    let(:facts) {{ :osfamily => 'RedHat' }}
    let(:params) {{ :package_source => 'http://www.rabbitmq.com/releases/rabbitmq-server/v3.2.3/rabbitmq-server-3.2.3-1.noarch.rpm' }}
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
    it 'installs the rabbitmq package' do
      should contain_package('rabbitmq-server').with(
        'ensure'   => 'installed',
        'name'     => 'rabbitmq-server',
        'provider' => 'apt'
      )
    end
  end

end
