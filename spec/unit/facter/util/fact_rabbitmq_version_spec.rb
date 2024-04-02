# frozen_string_literal: true

require 'spec_helper'

describe Facter::Util::Fact do
  before do
    Facter.clear
  end

  describe 'rabbitmq_version' do
    context 'with value' do
      it do
        allow(Facter::Util::Resolution).to receive(:which).with('rabbitmqadmin').and_return(true)
        allow(Facter::Core::Execution).to receive(:execute).with('rabbitmqadmin --version 2>&1').and_return('rabbitmqadmin 3.6.0')
        expect(Facter.fact(:rabbitmq_version).value).to eq('3.6.0')
      end
    end

    context 'with invalid value' do
      it do
        allow(Facter::Util::Resolution).to receive(:which).with('rabbitmqadmin').and_return(true)
        allow(Facter::Core::Execution).to receive(:execute).with('rabbitmqadmin --version 2>&1').and_return('rabbitmqadmin %%VSN%%')
        expect(Facter.fact(:rabbitmq_version).value).to be_nil
      end
    end

    context 'rabbitmqadmin is not in path' do
      it do
        allow(Facter::Util::Resolution).to receive(:which).with('rabbitmqadmin').and_return(false)
        expect(Facter.fact(:rabbitmq_version).value).to be_nil
      end
    end
  end
end
