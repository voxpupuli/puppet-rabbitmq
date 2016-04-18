require 'spec_helper'

describe Puppet::Type.type(:rabbitmq_user).provider(:rabbitmqctl) do

  let(:resource) {
    Puppet::Type.type(:rabbitmq_user).new(
      {
        :ensure   => :present,
        :name     => 'rmq_x',
        :password => 'secret',
        :provider => described_class.name,
      }
    )
  }

  let(:provider) { resource.provider }
  let(:instance) { provider.class.instances.first }

  before :each do
    provider.class.stubs(:rabbitmqctl).with('-q', 'list_users').returns(
      "rmq_x [disk, storage]\nrmq_y [network, cpu, administrator]\nrmq_z []\n"
    )
  end

  describe '#self.instances' do
    it 'returns an array of users with tags' do
      users = provider.class.instances.collect { |x| x.name }
      expect(['rmq_x', 'rmq_y', 'rmq_z']).to match_array(users)
    end
  end

  describe '#exists?' do
    it 'checks if users are in place' do
      expect(instance.exists?).to eql true
    end
  end

  describe '#create' do
    it 'adds an users' do
      provider.expects(:rabbitmqctl).with('add_user', 'rmq_x', 'secret')
      provider.create
    end
  end

  describe '#destroy' do
    it 'removes an users' do
      provider.expects(:rabbitmqctl).with('delete_user', 'rmq_x')
      provider.destroy
    end
  end

  describe '#tags=' do
    it 'clears all tags on existing user' do
      provider.set(:tags => %w[tag1 tag2 tag3])
      provider.expects(:rabbitmqctl).with('set_user_tags', 'rmq_x', [])
      provider.tags=[]
      provider.flush
    end

    it 'sets multiple tags' do
      provider.set(:tags => [])
      provider.expects(:rabbitmqctl).with('set_user_tags', 'rmq_x', ['tag1', 'tag2'])
      provider.tags=['tag1','tag2']
      provider.flush
    end

    it 'clears tags while keeping admin tag' do
      provider.set(:tags => %w[administrator tag1 tag2])
      resource[:admin] = true
      provider.expects(:rabbitmqctl).with('set_user_tags', 'rmq_x', ['administrator'])
      provider.tags=[]
      provider.flush
    end

    it 'changes tags while keeping admin tag' do
      provider.set(:tags => %w[administrator tag1 tag2])
      resource[:admin]  = true
      provider.expects(:rabbitmqctl).with('set_user_tags', 'rmq_x', ['tag1', 'tag7', 'tag3', 'administrator'])
      provider.tags=['tag1', 'tag7', 'tag3']
      provider.flush
    end
  end

  describe '#admin=' do
    it 'gets admin value properly' do
      provider.set(:tags => %w[administrator tag1 tag2])
      expect(provider.admin).to eql :true

      provider.set(:tags => %w[tag1 tag2])
      expect(provider.admin).to eql :false
   end

    it 'sets admin value' do
      provider.expects(:rabbitmqctl).with('set_user_tags', 'rmq_x', ['administrator'])
      resource[:admin] = true
      provider.admin=resource[:admin]
      provider.flush
    end

    it 'adds admin value to existing tags of the user' do
      resource[:tags] = %w[tag1 tag2]
      provider.expects(:rabbitmqctl).with('set_user_tags', 'rmq_x', ['tag1', 'tag2', 'administrator'])
      resource[:admin] = true
      provider.admin=resource[:admin]
      provider.flush
    end

    it 'unsets admin value' do
      provider.set(:tags => ['administrator'])
      provider.expects(:rabbitmqctl).with('set_user_tags', 'rmq_x', [])
      provider.admin=:false
      provider.flush
    end
 
    it 'should not interfere with existing tags on the user when unsetting admin value' do
      provider.set(:tags => %w[administrator tag1 tag2])
      resource[:tags] = %w[tag1 tag2]
      provider.expects(:rabbitmqctl).with('set_user_tags', 'rmq_x', ['tag1', 'tag2'])
      provider.admin=:false
      provider.flush
    end
  end
end
