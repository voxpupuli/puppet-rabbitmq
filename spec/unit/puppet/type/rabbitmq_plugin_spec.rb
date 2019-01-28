require 'spec_helper'
describe Puppet::Type.type(:rabbitmq_plugin) do
  let(:plugin) do
    Puppet::Type.type(:rabbitmq_plugin).new(name: 'foo')
  end

  it 'accepts a plugin name' do
    plugin[:name] = 'plugin-name'
    expect(plugin[:name]).to eq('plugin-name')
  end
  it 'accepts a mode of offline' do
    plugin[:mode] = 'offline'
    expect(plugin[:mode]).to eq(:offline)
  end
  it 'accepts a mode of online' do
    plugin[:mode] = 'online'
    expect(plugin[:mode]).to eq(:online)
  end
  it 'accepts a mode of best' do
    plugin[:mode] = 'best'
    expect(plugin[:mode]).to eq(:best)
  end
  it 'requires a name' do
    expect do
      Puppet::Type.type(:rabbitmq_plugin).new({})
    end.to raise_error(Puppet::Error, 'Title or name must be provided')
  end
  it 'defaults to a umask of 0022' do
    expect(plugin[:umask]).to eq(0o022)
  end
  it 'defaults to a mode of best' do
    expect(plugin[:mode]).to eq(:best)
  end
  it 'does not allow a non-octal value to be specified' do
    expect do
      plugin[:umask] = '198'
    end.to raise_error(Puppet::Error, %r{The umask specification is invalid: "198"})
  end
end
