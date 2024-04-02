# frozen_string_literal: true

require 'spec_helper'

describe Puppet::Type.type(:rabbitmq_parameter).provider(:rabbitmqctl) do
  let(:params) do
    {
      name: 'documentumFederation@/',
      component_name: 'federation',
      value: {
        'uri' => 'amqp://',
        'expires' => '360000'
      }
    }
  end
  let(:type_class) { Puppet::Type.type(:rabbitmq_parameter).provider(:rabbitmqctl) }
  let(:resource) { Puppet::Type.type(:rabbitmq_parameter).new(params) }
  let(:provider) { resource.provider }
  let(:instances) { Puppet::Type.type(:rabbitmq_parameter).instances }

  after do
    type_class.instance_variable_set(:@parameters, nil)
  end

  describe '#prefetch' do
    it 'exists' do
      expect(type_class).to respond_to :prefetch
    end

    it 'matches' do
      allow(type_class).to receive(:rabbitmqctl_list).with('vhosts').and_return <<~EOT
        /
      EOT
      allow(type_class).to receive(:rabbitmqctl_list).with('parameters', '-p', '/').and_return <<~EOT
        federation  documentumFederation  {"uri":"amqp://","expires":360000}
      EOT
      type_class.prefetch('documentumFederation@/' => resource)
    end
  end

  describe '#instances' do
    it 'exists' do
      expect(type_class).to respond_to :instances
    end

    it 'fail with invalid output from list' do
      allow(type_class).to receive(:rabbitmqctl_list).with('vhosts').and_return <<~EOT
        /
      EOT
      allow(type_class).to receive(:rabbitmqctl_list).with('parameters', '-p', '/').and_return 'foobar'
      expect { instances }.to raise_error Puppet::Error, %r{cannot parse line from list_parameter}
    end

    it 'return no instance' do
      allow(type_class).to receive(:rabbitmqctl_list).with('vhosts').and_return <<~EOT
        /
      EOT
      allow(type_class).to receive(:rabbitmqctl_list).with('parameters', '-p', '/').and_return ''
      expect(instances.size).to eq(0)
    end
  end

  describe '#create' do
    it 'create parameter' do
      allow(type_class).to receive(:rabbitmqctl).with('set_parameter', '-p', '/', 'federation', 'documentumFederation',
                                                      '{"uri":"amqp://","expires":360000}')
      provider.create
    end
  end

  describe '#destroy' do
    it 'destroy parameter' do
      allow(type_class).to receive(:rabbitmqctl).with('clear_parameter', '-p', '/', 'federation', 'documentumFederation')
      provider.destroy
    end
  end
end
