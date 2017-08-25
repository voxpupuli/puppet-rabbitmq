require 'puppet'
require 'puppet/type/rabbitmq_policy'

describe Puppet::Type.type(:rabbitmq_policy) do
  before do
    @policy = Puppet::Type.type(:rabbitmq_policy).new(
      name: 'ha-all@/',
      pattern: '.*',
      definition: {
        'ha-mode' => 'all'
      }
    )
  end

  it 'accepts a valid name' do
    @policy[:name] = 'ha-all@/'
    @policy[:name].should == 'ha-all@/'
  end

  it 'requires a name' do
    expect do
      Puppet::Type.type(:rabbitmq_policy).new({})
    end.to raise_error(Puppet::Error, 'Title or name must be provided')
  end

  it 'fails when name does not have a @' do
    expect do
      @policy[:name] = 'ha-all'
    end.to raise_error(Puppet::Error, %r{Valid values match})
  end

  it 'accepts a valid regex for pattern' do
    @policy[:pattern] = '.*?'
    @policy[:pattern].should == '.*?'
  end

  it 'accepts an empty string for pattern' do
    @policy[:pattern] = ''
    @policy[:pattern].should == ''
  end

  it 'does not accept invalid regex for pattern' do
    expect do
      @policy[:pattern] = '*'
    end.to raise_error(Puppet::Error, %r{Invalid regexp})
  end

  it 'accepts valid value for applyto' do
    [:all, :exchanges, :queues].each do |v|
      @policy[:applyto] = v
      @policy[:applyto].should == v
    end
  end

  it 'does not accept invalid value for applyto' do
    expect do
      @policy[:applyto] = 'me'
    end.to raise_error(Puppet::Error, %r{Invalid value})
  end

  it 'accepts a valid hash for definition' do
    definition = { 'ha-mode' => 'all', 'ha-sync-mode' => 'automatic' }
    @policy[:definition] = definition
    @policy[:definition].should == definition
  end

  it 'does not accept invalid hash for definition' do
    expect do
      @policy[:definition] = 'ha-mode'
    end.to raise_error(Puppet::Error, %r{Invalid definition})

    expect do
      @policy[:definition] = { 'ha-mode' => %w[a b] }
    end.to raise_error(Puppet::Error, %r{Invalid definition})
  end

  it 'accepts valid value for priority' do
    [0, 10, '0', '10'].each do |v|
      @policy[:priority] = v
      @policy[:priority].should == v
    end
  end

  it 'does not accept invalid value for priority' do
    ['-1', -1, '1.0', 1.0, 'abc', ''].each do |v|
      expect do
        @policy[:priority] = v
      end.to raise_error(Puppet::Error, %r{Invalid value})
    end
  end

  it 'accepts and convert ha-params for ha-mode exactly' do
    definition = { 'ha-mode' => 'exactly', 'ha-params' => '2' }
    @policy[:definition] = definition
    @policy[:definition]['ha-params'].should be_a(Integer)
    @policy[:definition]['ha-params'].should == 2
  end

  it 'does not accept non-numeric ha-params for ha-mode exactly' do
    definition = { 'ha-mode' => 'exactly', 'ha-params' => 'nonnumeric' }
    expect do
      @policy[:definition] = definition
    end.to raise_error(Puppet::Error, %r{Invalid ha-params.*nonnumeric.*exactly})
  end

  it 'accepts and convert the expires value' do
    definition = { 'expires' => '1800000' }
    @policy[:definition] = definition
    @policy[:definition]['expires'].should be_a(Integer)
    @policy[:definition]['expires'].should == 1_800_000
  end

  it 'does not accept non-numeric expires value' do
    definition = { 'expires' => 'future' }
    expect do
      @policy[:definition] = definition
    end.to raise_error(Puppet::Error, %r{Invalid expires value.*future})
  end

  it 'accepts and convert the message-ttl value' do
    definition = { 'message-ttl' => '1800000' }
    @policy[:definition] = definition
    @policy[:definition]['message-ttl'].should be_a(Integer)
    @policy[:definition]['message-ttl'].should == 1_800_000
  end

  it 'does not accept non-numeric message-ttl value' do
    definition = { 'message-ttl' => 'future' }
    expect do
      @policy[:definition] = definition
    end.to raise_error(Puppet::Error, %r{Invalid message-ttl value.*future})
  end

  it 'accepts and convert the max-length value' do
    definition = { 'max-length' => '1800000' }
    @policy[:definition] = definition
    @policy[:definition]['max-length'].should be_a(Integer)
    @policy[:definition]['max-length'].should == 1_800_000
  end

  it 'does not accept non-numeric max-length value' do
    definition = { 'max-length' => 'future' }
    expect do
      @policy[:definition] = definition
    end.to raise_error(Puppet::Error, %r{Invalid max-length value.*future})
  end

  it 'accepts and convert the shards-per-node value' do
    definition = { 'shards-per-node' => '1800000' }
    @policy[:definition] = definition
    @policy[:definition]['shards-per-node'].should be_a(Integer)
    @policy[:definition]['shards-per-node'].should == 1_800_000
  end

  it 'does not accept non-numeric shards-per-node value' do
    definition = { 'shards-per-node' => 'future' }
    expect do
      @policy[:definition] = definition
    end.to raise_error(Puppet::Error, %r{Invalid shards-per-node value.*future})
  end

  it 'accepts and convert the ha-sync-batch-size value' do
    definition = { 'ha-sync-batch-size' => '1800000' }
    @policy[:definition] = definition
    @policy[:definition]['ha-sync-batch-size'].should be_a(Integer)
    @policy[:definition]['ha-sync-batch-size'].should == 1_800_000
  end

  it 'does not accept non-numeric ha-sync-batch-size value' do
    definition = { 'ha-sync-batch-size' => 'future' }
    expect do
      @policy[:definition] = definition
    end.to raise_error(Puppet::Error, %r{Invalid ha-sync-batch-size value.*future})
  end
end
