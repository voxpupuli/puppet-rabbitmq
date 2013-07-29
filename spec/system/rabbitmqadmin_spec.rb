require 'spec_helper_system'

describe 'rabbitmq::install::rabbitmqadmin class' do
  let(:os) {
    node.facts['osfamily']
  }

  describe 'does nothing if service is unmanaged' do
    puppet_apply(%{
      class { 'rabbitmq':
        admin_enable   => true,
        manage_service => false,
      }
    })

    describe file('/var/lib/rabbitmq/rabbitmqadmin') do
      it { should_not be_file }
    end
  end

  describe 'downloads the cli tools' do

    puppet_apply(%{
      class { 'rabbitmq':
        admin_enable   => true,
        manage_service => true,
      }
    })

    describe file('/var/lib/rabbitmq/rabbitmqadmin') do
      it { should be_file }
    end

  end

end
