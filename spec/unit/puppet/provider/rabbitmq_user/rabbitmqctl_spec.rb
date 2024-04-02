# frozen_string_literal: true

require 'spec_helper'

describe Puppet::Type.type(:rabbitmq_user).provider(:rabbitmqctl) do
  let(:params) do
    {
      ensure: :present,
      name: 'rmq_x',
      password: 'secret',
    }
  end
  let(:type_class) { Puppet::Type.type(:rabbitmq_user).provider(:rabbitmqctl) }
  let(:resource) { Puppet::Type.type(:rabbitmq_user).new(params) }
  let(:provider) { resource.provider }
  let(:instances) { type_class.instances }

  before do
    allow(type_class).to receive(:rabbitmqctl_list).with('users').and_return <<~EOT
      rmq_x [disk, storage]
      rmq_y [network, cpu, administrator]
      rmq_z []
    EOT
  end

  describe '#self.instances' do
    it { expect(instances.size).to eq(3) }

    it 'returns an array of users' do
      expect(instances.map(&:name)).to match_array(%w[rmq_x rmq_y rmq_z])
    end

    it 'returns the expected tags' do
      expect(instances.first.get(:tags)).to match_array(%w[disk storage])
    end
  end

  describe '#exists?' do
    it { expect(instances.first.exists?).to be true }
  end

  describe '#create' do
    it 'adds a user' do
      allow(type_class).to receive(:rabbitmqctl).with('add_user', 'rmq_x', 'secret')
      provider.create
    end

    context 'no password supplied' do
      let(:params) do
        {
          ensure: :present,
          name: 'rmq_x'
        }
      end

      it 'raises an error' do
        expect do
          provider.create
        end.to raise_error(Puppet::Error, 'Password is a required parameter for rabbitmq_user (user: rmq_x)')
      end
    end
  end

  describe '#destroy' do
    it 'removes a user' do
      allow(type_class).to receive(:rabbitmqctl).with('delete_user', 'rmq_x')
      provider.destroy
    end
  end

  describe '#check_password' do
    it 'correct password' do
      allow(type_class).to receive(:rabbitmqctl).with(
        'eval',
        'rabbit_access_control:check_user_pass_login(list_to_binary("rmq_x"), list_to_binary("secret")).'
      ).and_return <<~EOT
        {ok,{user,<<"rmq_x">>,[],rabbit_auth_backend_internal,
                  {internal_user,<<"rmq_x">>,
                                 <<193,81,62,182,129,135,196,89,148,87,227,48,86,2,154,
                                   192,52,119,214,177>>,
                                 []}}}
      EOT
      provider.check_password('secret')
    end

    it 'incorrect password' do
      allow(type_class).to receive(:rabbitmqctl).with(
        'eval',
        'rabbit_access_control:check_user_pass_login(list_to_binary("rmq_x"), list_to_binary("nottherightone")).'
      ).and_return <<~EOT
        {refused,"user '~s' - invalid credentials",[<<"rmq_x">>]}
        ...done.
      EOT
      provider.check_password('nottherightone')
    end
  end

  describe '#tags=' do
    it 'clears all tags on existing user' do
      provider.set(tags: %w[tag1 tag2 tag3])
      allow(type_class).to receive(:rabbitmqctl).with('set_user_tags', 'rmq_x', [])
      provider.tags = []
      provider.flush
    end

    it 'sets multiple tags' do
      provider.set(tags: [])
      allow(type_class).to receive(:rabbitmqctl).with('set_user_tags', 'rmq_x', %w[tag1 tag2])
      provider.tags = %w[tag1 tag2]
      provider.flush
    end

    it 'clears tags while keeping admin tag' do
      provider.set(tags: %w[administrator tag1 tag2])
      resource[:admin] = true
      allow(type_class).to receive(:rabbitmqctl).with('set_user_tags', 'rmq_x', ['administrator'])
      provider.tags = []
      provider.flush
    end

    it 'changes tags while keeping admin tag' do
      provider.set(tags: %w[administrator tag1 tag2])
      resource[:admin] = true
      allow(type_class).to receive(:rabbitmqctl).with('set_user_tags', 'rmq_x', %w[tag1 tag7 tag3 administrator])
      provider.tags = %w[tag1 tag7 tag3]
      provider.flush
    end
  end

  describe '#admin=' do
    it 'gets admin value properly' do
      provider.set(tags: %w[administrator tag1 tag2])
      expect(provider.admin).to be :true
    end

    it 'gets false admin value' do
      provider.set(tags: %w[tag1 tag2])
      expect(provider.admin).to be :false
    end

    it 'sets admin value' do
      allow(type_class).to receive(:rabbitmqctl).with('set_user_tags', 'rmq_x', ['administrator'])
      resource[:admin] = true
      provider.admin = resource[:admin]
      provider.flush
    end

    it 'adds admin value to existing tags of the user' do
      resource[:tags] = %w[tag1 tag2]
      allow(type_class).to receive(:rabbitmqctl).with('set_user_tags', 'rmq_x', %w[tag1 tag2 administrator])
      resource[:admin] = true
      provider.admin = resource[:admin]
      provider.flush
    end

    it 'unsets admin value' do
      provider.set(tags: ['administrator'])
      allow(type_class).to receive(:rabbitmqctl).with('set_user_tags', 'rmq_x', [])
      provider.admin = :false
      provider.flush
    end

    it 'does not interfere with existing tags on the user when unsetting admin value' do
      provider.set(tags: %w[administrator tag1 tag2])
      resource[:tags] = %w[tag1 tag2]
      allow(type_class).to receive(:rabbitmqctl).with('set_user_tags', 'rmq_x', %w[tag1 tag2])
      provider.admin = :false
      provider.flush
    end
  end
end
