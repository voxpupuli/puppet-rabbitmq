require 'spec_helper'

describe Facter::Util::Fact do
  before { Facter.clear }

  describe 'rabbitmq_plugins_dirs' do
    context 'with multiple plugins dirs' do
      it do
        Facter::Util::Resolution.expects(:which).with('rabbitmqctl').returns(true)
        Facter::Core::Execution.expects(:execute).with("rabbitmqctl eval 'application:get_env(rabbit, plugins_dir).'").returns('{ok,"/usr/lib/rabbitmq/plugins:/usr/lib/rabbitmq/lib/rabbitmq_server-3.7.10/plugins"}')
        expect(Facter.fact(:rabbitmq_plugins_dirs).value).to match_array(
          [
            '/usr/lib/rabbitmq/plugins',
            '/usr/lib/rabbitmq/lib/rabbitmq_server-3.7.10/plugins'
          ]
        )
      end
    end

    context 'with only 1 plugins dir' do
      it do
        Facter::Util::Resolution.expects(:which).with('rabbitmqctl').returns(true)
        Facter::Core::Execution.expects(:execute).with("rabbitmqctl eval 'application:get_env(rabbit, plugins_dir).'").returns('{ok,"/usr/lib/rabbitmq/lib/rabbitmq_server-0.0.0/plugins"}')
        expect(Facter.fact(:rabbitmq_plugins_dirs).value).to match_array(
          [
            '/usr/lib/rabbitmq/lib/rabbitmq_server-0.0.0/plugins'
          ]
        )
      end
    end

    context 'rabbitmqctl is not in path' do
      it do
        Facter::Util::Resolution.expects(:which).with('rabbitmqctl').returns(false)
        expect(Facter.fact(:rabbitmq_plugins_dirs).value).to be_nil
      end
    end
  end
end
