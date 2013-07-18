require 'spec_helper_system'

describe 'rabbitmq::install::rabbitmqadmin class' do
  let(:os) {
    node.facts['osfamily']
  }

  puppet_apply(%{
    class { 'rabbitmq': }
  })

  describe file('/var/lib/rabbitmq/rabbitmqadmin') do
    it { should be_file }
  end

end
