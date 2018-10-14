require 'spec_helper'

describe Facter::Util::Fact do
  before do
    Facter.clear
  end

  describe 'rabbitmq_version' do
    context 'with value' do
      it do
        Facter::Util::Resolution.expects(:which).with('rabbitmqadmin').returns(true)
        Facter::Core::Execution.expects(:execute).with('rabbitmqadmin --version 2>&1').returns('rabbitmqadmin 3.6.0')
        expect(Facter.fact(:rabbitmq_version).value).to eq('3.6.0')
      end
    end
    context 'with invalid value' do
      it do
        Facter::Util::Resolution.expects(:which).with('rabbitmqadmin').returns(true)
        Facter::Core::Execution.expects(:execute).with('rabbitmqadmin --version 2>&1').returns('rabbitmqadmin %%VSN%%')
        expect(Facter.fact(:rabbitmq_version).value).to be_nil
      end
    end
    context 'rabbitmqadmin is not in path' do
      it do
        Facter::Util::Resolution.expects(:which).with('rabbitmqadmin').returns(false)
        expect(Facter.fact(:rabbitmq_version).value).to be_nil
      end
    end
  end
end
