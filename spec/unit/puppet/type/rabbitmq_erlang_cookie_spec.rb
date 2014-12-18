require 'mocha'
require 'puppet'
require 'puppet/type/rabbitmq_exchange'
RSpec.configure do |config|
  config.mock_with :mocha
end
describe Puppet::Type.type(:rabbitmq_erlang_cookie) do
  context 'when content needs to change and force is unset' do
    it 'fails' do
      File.expects(:read).with('/var/lib/rabbitmq/.erlang.cookie').returns('OLDCOOKIE')
      File.expects(:exists?).returns(true)
      expect {
        Puppet::Type.type(:rabbitmq_erlang_cookie).new(
          :name    => '/var/lib/rabbitmq/.erlang.cookie',
          :content => 'NEWCOOKIE',
        )
      }.to raise_error(Puppet::Error, /The current erlang cookie needs to change/)
    end
  end

  context 'when content needs to change and force is true' do
    it 'sets the cookie' do
      File.expects(:read).with('/var/lib/rabbitmq/.erlang.cookie').returns('OLDCOOKIE')
      File.expects(:exists?).returns(true)
      cookie = Puppet::Type.type(:rabbitmq_erlang_cookie).new(
        :name    => '/var/lib/rabbitmq/.erlang.cookie',
        :content => 'NEWCOOKIE',
        :force   => true,
      )
      expect(cookie[:content]).to eq('NEWCOOKIE')
    end
  end

  context 'when content does not need to change' do
    it 'still sets the cookie' do
      File.expects(:read).with('/var/lib/rabbitmq/.erlang.cookie').returns('NEWCOOKIE')
      File.expects(:exists?).returns(true)
      cookie = Puppet::Type.type(:rabbitmq_erlang_cookie).new(
        :name    => '/var/lib/rabbitmq/.erlang.cookie',
        :content => 'NEWCOOKIE',
      )
      expect(cookie[:content]).to eq('NEWCOOKIE')
    end
  end
end
