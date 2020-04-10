require 'spec_helper'

provider_class = Puppet::Type.type(:rabbitmq_parameter).provider(:rabbitmqctl)
describe provider_class do
  let(:resource) do
    Puppet::Type.type(:rabbitmq_parameter).new(
      name: 'documentumFederation@/',
      component_name: 'federation',
      value: {
        'uri'      => 'amqp://',
        'expires'  => '360000'
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
      provider_class.expects(:rabbitmqctl_list).with('vhosts').returns <<-EOT
/
EOT
      provider_class.expects(:rabbitmqctl_list).with('parameters', '-p', '/').returns <<-EOT
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
      provider_class.expects(:rabbitmqctl_list).with('vhosts').returns <<-EOT
/
EOT
      provider.class.expects(:rabbitmqctl_list).with('parameters', '-p', '/').returns 'foobar'
      expect { provider_class.instances }.to raise_error Puppet::Error, %r{cannot parse line from list_parameter}
    end

    it 'return no instance' do
      provider_class.expects(:rabbitmqctl_list).with('vhosts').returns <<-EOT
/
EOT
      provider_class.expects(:rabbitmqctl_list).with('parameters', '-p', '/').returns ''
      instances = provider_class.instances
      expect(instances.size).to eq(0)
    end
  end

  describe '#create' do
    it 'create parameter' do
      provider.expects(:rabbitmqctl).with('set_parameter', '-p', '/', 'federation', 'documentumFederation',
                                          '{"uri":"amqp://","expires":360000}')
      provider.create
    end
  end

  describe '#destroy' do
    it 'destroy parameter' do
      provider.expects(:rabbitmqctl).with('clear_parameter', '-p', '/', 'federation', 'documentumFederation')
      provider.destroy
    end
  end
end
