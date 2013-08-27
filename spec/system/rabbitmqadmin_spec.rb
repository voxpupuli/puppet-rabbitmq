require 'spec_helper_system'

describe 'rabbitmq::install::rabbitmqadmin class' do

  let(:os) {
    node.facts['osfamily']
  }

  describe 'does nothing if service is unmanaged' do
    before do
      shell('rm /var/lib/rabbitmq/rabbitmqadmin')
    end
    it do
      puppet_apply(%{
        class { 'rabbitmq':
          admin_enable   => true,
          service_manage => false,
        }
      })
    end

    describe file('/var/lib/rabbitmq/rabbitmqadmin') do
      it { should_not be_file }
    end
  end

  describe 'downloads the cli tools' do

    it do
      puppet_apply(%{
        class { 'rabbitmq':
          admin_enable   => true,
          service_manage => true,
        }
      })
    end

    describe file('/var/lib/rabbitmq/rabbitmqadmin') do
      it { should be_file }
    end

  end

end
