require 'spec_helper_system'

describe 'rabbitmq::service class' do
  let(:os) {
    node.facts['osfamily']
  }

  puppet_apply(%{
    class { 'rabbitmq': }
  })

  describe service('rabbitmq-server') do
    it { should be_enabled }
    it { should be_running }
  end

end
