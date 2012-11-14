require 'spec_helper'

describe 'rabbitmq::server' do

  let :facts do
    # Needed for statement in rabbitmq.config template.
    { :puppetversion => '2.7.14' } 
  end

  describe 'package with default params' do
    it { should contain_package('rabbitmq-server').with(
      'ensure' => 'present'
    ) }
  end

  describe 'package with specified ensure' do
  	let :params do 
  	  { :version => "2.3.0" }
  	end
  	it { should contain_package('rabbitmq-server').with(
      'ensure' => '2.3.0'
    ) }
  end

  describe 'not deleting guest user by default' do
  	it { should_not contain_rabbitmq_user('guest') }
  end

  describe 'deleting guest user' do
  	let :params do 
  	  { :delete_guest_user => true }
  	end
  	it { should contain_rabbitmq_user('guest').with(
  	  'ensure'   => 'absent',
  	  'provider' => 'rabbitmqctl'
  	) }
  end

  describe 'default service include' do
  	it { should contain_class('rabbitmq::service').with(
  	  'service_name' => 'rabbitmq-server',
  	  'ensure'       => 'running'
  	) }
  end

  describe 'overriding service paramters' do
  	let :params do
  	  { 'service_name' => 'custom-rabbitmq-server',
        'service_ensure' => 'stopped'
      }
  	end
  	it { should contain_class('rabbitmq::service').with(
  	  'service_name' => 'custom-rabbitmq-server',
  	  'ensure'       => 'stopped'
  	) }
  end

  describe 'specifing node_ip_address' do
  	let :params do
  	  { :node_ip_address => '172.0.0.1' }
  	end
    it 'should set RABBITMQ_NODE_IP_ADDRESS to specified value' do
      verify_contents(subject, 'rabbitmq-env.config',
        ['RABBITMQ_NODE_IP_ADDRESS=172.0.0.1'])
    end
  end

  describe 'not configuring stomp by default' do
  	it 'should not specify stomp parameters in rabbitmq.config' do
      verify_contents(subject, 'rabbitmq.config',
        ['[','].'])  	
  	end
  end

  describe 'configuring stomp' do
  	let :params do
  	  { :config_stomp => true,
  	  	:stomp_port   => 5679
  	  }
  	end
  	it 'should specify stomp port in rabbitmq.config' do
      verify_contents(subject, 'rabbitmq.config',
        ['[','{rabbitmq_stomp, [{tcp_listeners, [5679]} ]}','].'])  	
  	end

  end

  describe 'configuring cluster' do
  	let :params do
  	  { :config_cluster => true,
  	  	:cluster_disk_nodes => ['hare-1', 'hare-2']
  	  }
  	end
  	it 'should specify cluster nodes in rabbitmq.config' do
      verify_contents(subject, 'rabbitmq.config',
        ['[',"{rabbit, [{cluster_nodes, ['rabbit@hare-1', 'rabbit@hare-2']}]}", '].'])  	
  	end
  	it 'should have the default erlang cookie' do
      verify_contents(subject, 'erlang_cookie',
        ['EOKOWXQREETZSHFNTPEY'])
  	end

  end

  describe 'specifying custom erlang cookie in cluster mode' do
  	let :params do
  	  { :config_cluster => true,
        :erlang_cookie => 'YOKOWXQREETZSHFNTPEY' }
  	end
    it 'should set .erlang.cookie to the specified value' do
      verify_contents(subject, 'erlang_cookie',
        ['YOKOWXQREETZSHFNTPEY'])
    end
  end

end
