require 'spec_helper_system'

describe "rabbitmq class:" do
  context 'should run successfully' do
    pp="
      class { 'erlang': epel_enable => true}
      class { 'rabbitmq':
        config_cluster           => true,
        cluster_nodes            => ['rabbit1', 'rabbit2'],
        cluster_node_type        => 'ram',
        wipe_db_on_cookie_change => true,
      }
      Class['erlang'] -> Class['rabbitmq']
    "

    context puppet_apply(pp) do
      its(:stderr) { should be_empty }
      its(:exit_code) { should_not == 1 }
      its(:refresh) { should be_nil }
      its(:stderr) { should be_empty }
    end
  end

  describe file('/etc/rabbitmq/rabbitmq.config') do
    it { should be_file }
    it { should contain 'cluster_nodes' }
    it { should contain 'rabbit@rabbit1' }
    it { should contain 'rabbit@rabbit2' }
    it { should contain 'ram' }
  end

  describe file('/var/lib/rabbitmq/.erlang.cookie') do
    it { should be_file }
  end

end
