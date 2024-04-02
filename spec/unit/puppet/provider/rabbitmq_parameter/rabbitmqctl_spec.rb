# frozen_string_literal: true

require 'spec_helper'

describe Puppet::Type.type(:rabbitmq_parameter).provider(:rabbitmqctl) do
  let(:params) do
    {
      name: 'documentumShovel@/',
      component_name: 'shovel',
      value: {
        'src-uri' => 'amqp://',
        'src-queue' => 'my-queue',
        'dest-uri' => 'amqp://remote-server',
        'dest-queue' => 'another-queue'
      }
    }
  end
  let(:type_class) { Puppet::Type.type(:rabbitmq_parameter).provider(:rabbitmqctl) }
  let(:resource) { Puppet::Type.type(:rabbitmq_parameter).new(params) }
  let(:provider) { resource.provider }
  let(:instances) { type_class.instances }

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
        shovel  documentumShovel  {"src-uri":"amqp://","src-queue":"my-queue","dest-uri":"amqp://remote-server","dest-queue":"another-queue"}
      EOT
      type_class.prefetch('documentumShovel@/' => resource)
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

    it 'return one instance' do
      allow(type_class).to receive(:rabbitmqctl_list).with('vhosts').and_return <<~EOT
        /
      EOT
      allow(type_class).to receive(:rabbitmqctl_list).with('parameters', '-p', '/').and_return <<~EOT
        shovel  documentumShovel  {"src-uri":"amqp://","src-queue":"my-queue","dest-uri":"amqp://remote-server","dest-queue":"another-queue"}
      EOT
      expect(instances.size).to eq(1)
      expect(instances.map do |prov|
        {
          name: prov.get(:name),
          component_name: prov.get(:component_name),
          value: prov.get(:value)
        }
      end).to eq(
        [
          {
            name: 'documentumShovel@/',
            component_name: 'shovel',
            value: {
              'src-uri' => 'amqp://',
              'src-queue' => 'my-queue',
              'dest-uri' => 'amqp://remote-server',
              'dest-queue' => 'another-queue'
            }
          }
        ]
      )
    end

    it 'return multiple instances' do
      allow(type_class).to receive(:rabbitmqctl_list).with('vhosts').and_return <<~EOT
        /
      EOT
      allow(type_class).to receive(:rabbitmqctl_list).with('parameters', '-p', '/').and_return <<~EOT
        shovel  documentumShovel1  {"src-uri":"amqp://","src-queue":"my-queue","dest-uri":"amqp://remote-server","dest-queue":"another-queue"}
        shovel  documentumShovel2  {"src-uri":["amqp://cl1","amqp://cl2"],"src-queue":"my-queue","dest-uri":"amqp://remote-server","dest-queue":"another-queue"}
      EOT
      expect(instances.size).to eq(2)
      expect(instances.map do |prov|
        {
          name: prov.get(:name),
          component_name: prov.get(:component_name),
          value: prov.get(:value)
        }
      end).to eq(
        [
          {
            name: 'documentumShovel1@/',
            component_name: 'shovel',
            value: {
              'src-uri' => 'amqp://',
              'src-queue' => 'my-queue',
              'dest-uri' => 'amqp://remote-server',
              'dest-queue' => 'another-queue'
            }
          },
          {
            name: 'documentumShovel2@/',
            component_name: 'shovel',
            value: {
              'src-uri' => ['amqp://cl1', 'amqp://cl2'],
              'src-queue' => 'my-queue',
              'dest-uri' => 'amqp://remote-server',
              'dest-queue' => 'another-queue'
            }
          }
        ]
      )
    end

    it 'return different instances' do
      allow(type_class).to receive(:rabbitmqctl_list).with('vhosts').and_return <<~EOT
        /
      EOT
      allow(type_class).to receive(:rabbitmqctl_list).with('parameters', '-p', '/').and_return <<~EOT
        shovel  documentumShovel1  {"src-uri":"amqp://","src-queue":"my-queue","dest-uri":"amqp://remote-server","dest-queue":"another-queue"}
        federation  documentumFederation2  {"uri":"amqp://","expires":"360000"}
      EOT
      expect(instances.size).to eq(2)
      expect(instances.map do |prov|
        {
          name: prov.get(:name),
          component_name: prov.get(:component_name),
          value: prov.get(:value)
        }
      end).to eq(
        [
          {
            name: 'documentumShovel1@/',
            component_name: 'shovel',
            value: {
              'src-uri' => 'amqp://',
              'src-queue' => 'my-queue',
              'dest-uri' => 'amqp://remote-server',
              'dest-queue' => 'another-queue'
            }
          },
          {
            name: 'documentumFederation2@/',
            component_name: 'federation',
            value: {
              'uri' => 'amqp://',
              'expires' => '360000'
            }
          }
        ]
      )
    end
  end

  describe '#create' do
    it 'create parameter' do
      allow(type_class).to receive(:rabbitmqctl).with('set_parameter', '-p', '/', 'shovel', 'documentumShovel',
                                                      '{"src-uri":"amqp://","src-queue":"my-queue","dest-uri":"amqp://remote-server","dest-queue":"another-queue"}')
      provider.create
    end
  end

  describe '#destroy' do
    it 'destroy parameter' do
      allow(type_class).to receive(:rabbitmqctl).with('clear_parameter', '-p', '/', 'shovel', 'documentumShovel')
      provider.destroy
    end
  end
end
