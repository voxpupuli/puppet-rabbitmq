# frozen_string_literal: true

require 'spec_helper'

describe Facter::Util::Fact do
  before do
    Facter.clear
  end

  describe 'rabbitmq_version' do
    context 'with value' do
      it do
        expect(Facter::Core::Execution).to receive(:which).with('rabbitmq-diagnostics').and_return(true)
        expect(Facter::Core::Execution).to receive(:execute).with('rabbitmq-diagnostics version 2>&1').and_return('3.13.7')
        expect(Facter.fact(:rabbitmq_version).value).to eq('3.13.7')
      end
    end

    context 'with invalid value' do
      it do
        expect(Facter::Core::Execution).to receive(:which).with('rabbitmq-diagnostics').and_return(true)
        expect(Facter::Core::Execution).to receive(:execute).with('rabbitmq-diagnostics version 2>&1').and_return('%%VSN%%')
        expect(Facter.fact(:rabbitmq_version).value).to be_nil
      end
    end

    context 'rabbitmq-diagnostics is not in path' do
      it do
        expect(Facter::Core::Execution).to receive(:which).with('rabbitmq-diagnostics').and_return(false)
        expect(Facter.fact(:rabbitmq_version).value).to be_nil
      end
    end
  end
end
