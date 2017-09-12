require 'spec_helper'

provider_class = Puppet::Type.type(:rabbitmq_user).provider(:rabbitmqctl)
describe provider_class do
  let(:resource) do
    Puppet::Type::Rabbitmq_user.new(
      name: 'foo', password: 'bar'
    )
  end
  let(:provider) { provider_class.new(resource) }

  it 'matches user names' do
    provider.expects(:rabbitmqctl).with('-q', 'list_users').returns <<-EOT
foo
EOT
    expect(provider.exists?).to eq('foo')
  end
  it 'matches user names with 2.4.1 syntax' do
    provider.expects(:rabbitmqctl).with('-q', 'list_users').returns <<-EOT
foo bar
EOT
    expect(provider.exists?).to eq('foo bar')
  end
  it 'does not match if no users on system' do
    provider.expects(:rabbitmqctl).with('-q', 'list_users').returns <<-EOT
EOT
    expect(provider.exists?).to be_nil
  end
  it 'matches user names from list' do
    provider.expects(:rabbitmqctl).with('-q', 'list_users').returns <<-EOT
one
two three
foo
bar
EOT
    expect(provider.exists?).to eq('foo')
  end
  context 'when no password is given' do
    let(:resource) do
      Puppet::Type::Rabbitmq_user.new(
        name: 'rmq_x'
      )
    end

    it 'raises an error' do
      expect do
        provider.create
      end.to raise_error(Puppet::Error, 'Password is a required parameter for rabbitmq_user (user: rmq_x)')
    end
  end
  it 'creates user and set password' do
    resource[:password] = 'bar'
    provider.expects(:rabbitmqctl).with('add_user', 'foo', 'bar')
    provider.create
  end
  it 'creates user, set password and set to admin' do
    resource[:password] = 'bar'
    resource[:admin] = 'true'
    provider.expects(:rabbitmqctl).with('add_user', 'foo', 'bar')
    provider.expects(:rabbitmqctl).with('-q', 'list_users').returns <<-EOT
foo   []
icinga  [monitoring]
kitchen []
kitchen2        [abc, def, ghi]
EOT
    provider.expects(:rabbitmqctl).with('set_user_tags', 'foo', ['administrator'])
    provider.create
  end
  it 'calls rabbitmqctl to delete' do
    provider.expects(:rabbitmqctl).with('delete_user', 'foo')
    provider.destroy
  end
  it 'is able to retrieve admin value' do
    provider.expects(:rabbitmqctl).with('-q', 'list_users').returns <<-EOT
foo [administrator]
EOT
    expect(provider.admin).to eq(:true)
  end
  it 'is able to retrieve correct admin value when there are multiple results' do
    provider.expects(:rabbitmqctl).with('-q', 'list_users').returns <<-EOT
one [administrator]
foo []
EOT
    expect(provider.admin).to eq(:false)
  end
  it 'fails if admin value is invalid' do
    provider.expects(:rabbitmqctl).with('-q', 'list_users').returns <<-EOT
foo fail
EOT
    expect { provider.admin }.to raise_error(Puppet::Error, %r{Could not match line})
  end
  it 'is able to set admin value' do
    provider.expects(:rabbitmqctl).with('-q', 'list_users').returns <<-EOT
foo   []
icinga  [monitoring]
kitchen []
kitchen2        [abc, def, ghi]
EOT
    provider.expects(:rabbitmqctl).with('set_user_tags', 'foo', ['administrator'])
    provider.admin = :true
  end
  it 'does not interfere with existing tags on the user when setting admin value' do
    provider.expects(:rabbitmqctl).with('-q', 'list_users').returns <<-EOT
foo   [bar, baz]
icinga  [monitoring]
kitchen []
kitchen2        [abc, def, ghi]
EOT
    provider.expects(:rabbitmqctl).with('set_user_tags', 'foo', %w[bar baz administrator].sort)
    provider.admin = :true
  end
  it 'is able to unset admin value' do
    provider.expects(:rabbitmqctl).with('-q', 'list_users').returns <<-EOT
foo     [administrator]
guest   [administrator]
icinga  []
EOT
    provider.expects(:rabbitmqctl).with('set_user_tags', 'foo', [])
    provider.admin = :false
  end
  it 'does not interfere with existing tags on the user when unsetting admin value' do
    provider.expects(:rabbitmqctl).with('-q', 'list_users').returns <<-EOT
foo   [administrator, bar, baz]
icinga  [monitoring]
kitchen []
kitchen2        [abc, def, ghi]
EOT
    provider.expects(:rabbitmqctl).with('set_user_tags', 'foo', %w[bar baz].sort)
    provider.admin = :false
  end

  it 'clears all tags on existing user' do
    provider.expects(:rabbitmqctl).with('-q', 'list_users').returns <<-EOT
one [administrator]
foo [tag1,tag2]
icinga  [monitoring]
kitchen []
kitchen2        [abc, def, ghi]
EOT
    provider.expects(:rabbitmqctl).with('set_user_tags', 'foo', [])
    provider.tags = []
  end

  it 'sets multiple tags' do
    provider.expects(:rabbitmqctl).with('-q', 'list_users').returns <<-EOT
one [administrator]
foo []
icinga  [monitoring]
kitchen []
kitchen2        [abc, def, ghi]
EOT
    provider.expects(:rabbitmqctl).with('set_user_tags', 'foo', %w[tag1 tag2])
    provider.tags = %w[tag1 tag2]
  end

  it 'clears tags while keep admin tag' do
    resource[:admin] = true
    provider.expects(:rabbitmqctl).with('-q', 'list_users').returns <<-EOT
one [administrator]
foo [administrator, tag1, tag2]
icinga  [monitoring]
kitchen []
kitchen2        [abc, def, ghi]
EOT
    provider.expects(:rabbitmqctl).with('set_user_tags', 'foo', ['administrator'])
    provider.tags = []
  end

  it 'changes tags while keep admin tag' do
    resource[:admin] = true
    provider.expects(:rabbitmqctl).with('-q', 'list_users').returns <<-EOT
one [administrator]
foo [administrator, tag1, tag2]
icinga  [monitoring]
kitchen []
kitchen2        [abc, def, ghi]
EOT
    provider.expects(:rabbitmqctl).with('set_user_tags', 'foo', %w[administrator tag1 tag3 tag7])
    provider.tags = %w[tag1 tag7 tag3]
  end

  it 'creates user with tags and without admin' do
    resource[:tags] = %w[tag1 tag2]
    provider.expects(:rabbitmqctl).with('add_user', 'foo', 'bar')
    provider.expects(:rabbitmqctl).with('set_user_tags', 'foo', %w[tag1 tag2])
    provider.expects(:rabbitmqctl).with('-q', 'list_users').returns <<-EOT
foo []
EOT
    provider.create
  end

  it 'creates user with tags and with admin' do
    resource[:tags] = %w[tag1 tag2]
    resource[:admin] = true
    provider.expects(:rabbitmqctl).with('add_user', 'foo', 'bar')
    provider.expects(:rabbitmqctl).with('-q', 'list_users').twice.returns <<-EOT
foo []
EOT
    provider.expects(:rabbitmqctl).with('set_user_tags', 'foo', ['administrator'])
    provider.expects(:rabbitmqctl).with('set_user_tags', 'foo', %w[administrator tag1 tag2])
    provider.create
  end

  it 'does not return the administrator tag in tags for admins' do
    resource[:tags] = []
    resource[:admin] = true
    provider.expects(:rabbitmqctl).with('-q', 'list_users').returns <<-EOT
foo [administrator]
EOT
    expect(provider.tags).to eq([])
  end

  it 'returns the administrator tag for non-admins' do
    # this should not happen though.
    resource[:tags] = []
    resource[:admin] = :false
    provider.expects(:rabbitmqctl).with('-q', 'list_users').returns <<-EOT
foo [administrator]
EOT
    expect(provider.tags).to eq(['administrator'])
  end
end
