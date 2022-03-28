# frozen_string_literal: true

require 'spec_helper'

describe Facter::Util::Fact do
  before do
    Facter.clear
  end

  describe 'rabbitmq_clusternam' do
    context 'with value' do
      it do
        Facter::Util::Resolution.expects(:which).with('rabbitmqctl').returns(true)
        Facter::Core::Execution.expects(:execute).with('rabbitmqctl -q cluster_status 2>&1').returns(' {cluster_name,<<"monty">>},')
        expect(Facter.fact(:rabbitmq_clustername).value).to eq('monty')
      end
    end

    context 'with dashes in hostname' do
      it do
        Facter::Util::Resolution.expects(:which).with('rabbitmqctl').returns(true)
        Facter::Core::Execution.expects(:execute).with('rabbitmqctl -q cluster_status 2>&1').returns('Cluster name: rabbit-1')
        expect(Facter.fact(:rabbitmq_clustername).value).to eq('rabbit-1')
      end
    end

    context 'with dashes in clustername/hostname' do
      it do
        Facter::Util::Resolution.expects(:which).with('rabbitmqctl').returns(true)
        Facter::Core::Execution.expects(:execute).with('rabbitmqctl -q cluster_status 2>&1').returns(' {cluster_name,<<"monty-python@rabbit-1">>},')
        expect(Facter.fact(:rabbitmq_clustername).value).to eq('monty-python@rabbit-1')
      end
    end

    context 'with quotes around node name' do
      it do
        Facter::Util::Resolution.expects(:which).with('rabbitmqctl').returns(true)
        Facter::Core::Execution.expects(:execute).with('rabbitmqctl -q cluster_status 2>&1').returns("monty\npython\nCluster name: 'monty@rabbit-1'\nend\nof\nfile")
        expect(Facter.fact(:rabbitmq_clustername).value).to eq("'monty@rabbit-1'")
      end
    end

    context 'rabbitmq is not running' do
      it do
        error_string = <<~EOS
          Status of node 'monty@rabbit-1' ...
          Error: unable to connect to node 'monty@rabbit-1': nodedown

          DIAGNOSTICS
          ===========

          attempted to contact: ['monty@rabbit-1']

          monty@rabbit-1:
            * connected to epmd (port 4369) on centos-7-x64
            * epmd reports: node 'rabbit' not running at all
                            no other nodes on centos-7-x64
            * suggestion: start the node

          current node details:
          - node name: 'rabbitmq-cli-73@centos-7-x64'
          - home dir: /var/lib/rabbitmq
          - cookie hash: 6WdP0nl6d3HYqA5vTKMkIg==

        EOS
        Facter::Util::Resolution.expects(:which).with('rabbitmqctl').returns(true)
        Facter::Core::Execution.expects(:execute).with('rabbitmqctl -q cluster_status 2>&1').returns(error_string)
        expect(Facter.fact(:rabbitmq_clustername).value).to be_nil
      end
    end

    context 'rabbitmqctl is not in path' do
      it do
        Facter::Util::Resolution.expects(:which).with('rabbitmqctl').returns(false)
        expect(Facter.fact(:rabbitmq_clustername).value).to be_nil
      end
    end
  end
end
