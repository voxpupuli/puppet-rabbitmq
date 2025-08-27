# frozen_string_literal: true

require 'spec_helper'

provider_class = Puppet::Type.type(:rabbitmq_parameter).provider(:rabbitmqctl)
describe provider_class do
  let(:resource) do
    Puppet::Type.type(:rabbitmq_parameter).new(
      name: 'documentumFederation@/',
      component_name: 'federation',
      value: {
        'uri' => 'amqp://',
        'expires' => '360000'
      }
    )
  end
  let(:provider) { provider_class.new(resource) }

  after do
    described_class.instance_variable_set(:@parameters, nil)
  end

  describe '#prefetch' do
    it 'exists' do
      expect(described_class).to respond_to :prefetch
    end

    it 'matches' do
      expect(provider_class).to receive(:rabbitmqctl_list).with('vhosts').and_return(<<~EOT)
        /
      EOT
      expect(provider_class).to receive(:rabbitmqctl_list).with('parameters', '-p', '/').and_return(<<~EOT)
        federation  documentumFederation  {"uri":"amqp://","expires":360000}
      EOT
      provider_class.prefetch('documentumFederation@/' => resource)
    end
  end

  describe '#instances' do
    it 'exists' do
      expect(described_class).to respond_to :instances
    end

    it 'fail with invalid output from list' do
      expect(provider_class).to receive(:rabbitmqctl_list).with('vhosts').and_return(<<~EOT)
        /
      EOT
      expect(provider.class).to receive(:rabbitmqctl_list).with('parameters', '-p', '/').and_return('foobar')
      expect { provider_class.instances }.to raise_error Puppet::Error, %r{cannot parse line from list_parameter}
    end

    it 'return no instance' do
      expect(provider_class).to receive(:rabbitmqctl_list).with('vhosts').and_return(<<~EOT)
        /
      EOT
      expect(provider_class).to receive(:rabbitmqctl_list).with('parameters', '-p', '/').and_return('')
      instances = provider_class.instances
      expect(instances.size).to eq(0)
    end
  end

  describe '#create' do
    it 'create parameter' do
      expect(provider).to receive(:rabbitmqctl).with('set_parameter', '-p', '/', 'federation', 'documentumFederation',
                                                     '{"uri":"amqp://","expires":360000}')
      provider.create
    end
  end

  describe '#destroy' do
    it 'destroy parameter' do
      expect(provider).to receive(:rabbitmqctl).with('clear_parameter', '-p', '/', 'federation', 'documentumFederation')
      provider.destroy
    end
  end
end
