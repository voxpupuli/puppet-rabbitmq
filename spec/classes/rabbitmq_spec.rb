require 'spec_helper'

describe 'rabbitmq' do
  context 'on unsupported distributions' do
    let(:facts) { { osfamily: 'Unsupported' } }

    it 'we fail' do
      expect { catalogue }.to raise_error(Puppet::Error, %r{not supported on an Unsupported})
    end
  end

  context 'on Debian' do
    with_debian_facts
    it 'does not include rabbitmq::repo::apt' do
      is_expected.not_to contain_class('rabbitmq::repo::apt')
    end

    it 'does ensure rabbitmq apt::source is absent when repos_ensure is false' do
      is_expected.not_to contain_apt__source('rabbitmq')
    end
  end

  context 'on Debian' do
    let(:params) { { repos_ensure: true } }

    with_debian_facts

    it 'includes rabbitmq::repo::apt' do
      is_expected.to contain_class('rabbitmq::repo::apt')
    end

    describe 'apt::source default values' do
      it 'adds a repo with default values' do
        is_expected.to contain_apt__source('rabbitmq').with(ensure: 'present',
                                                            location: 'http://www.rabbitmq.com/debian/',
                                                            release: 'testing',
                                                            repos: 'main')
      end
    end

    context 'with file_limit => unlimited' do
      let(:params) { { file_limit: 'unlimited' } }

      it { is_expected.to contain_file('/etc/default/rabbitmq-server').with_content(%r{ulimit -n unlimited}) }
    end

    context 'with file_limit => infinity' do
      let(:params) { { file_limit: 'infinity' } }

      it { is_expected.to contain_file('/etc/default/rabbitmq-server').with_content(%r{ulimit -n infinity}) }
    end

    context 'with file_limit => \'-1\'' do
      let(:params) { { file_limit: '-1' } }

      it { is_expected.to contain_file('/etc/default/rabbitmq-server').with_content(%r{ulimit -n -1}) }
    end

    context 'with file_limit => \'1234\'' do
      let(:params) { { file_limit: '1234' } }

      it { is_expected.to contain_file('/etc/default/rabbitmq-server').with_content(%r{ulimit -n 1234}) }
    end

    context 'with file_limit => 1234' do
      let(:params) { { file_limit: 1234 } }

      it { is_expected.to contain_file('/etc/default/rabbitmq-server').with_content(%r{ulimit -n 1234}) }
    end

    context 'with file_limit => \'-42\'' do
      let(:params) { { file_limit: '-42' } }

      it 'does not compile' do
        expect { catalogue }.to raise_error(Puppet::Error, %r{\$file_limit must be a positive integer, '-1', 'unlimited', or 'infinity'})
      end
    end

    context 'with file_limit => \'foo\'' do
      let(:params) { { file_limit: 'foo' } }

      it 'does not compile' do
        expect { catalogue }.to raise_error(Puppet::Error, %r{\$file_limit must be a positive integer, '-1', 'unlimited', or 'infinity'})
      end
    end
  end

  context 'on Redhat' do
    with_redhat_facts
    it 'does not include rabbitmq::repo::rhel' do
      is_expected.not_to contain_class('rabbitmq::repo::rhel')
    end

    context 'with file_limit => \'unlimited\'' do
      let(:params) { { file_limit: 'unlimited' } }

      it {
        is_expected.to contain_file('/etc/security/limits.d/rabbitmq-server.conf').with(
          'owner'   => '0',
          'group'   => '0',
          'mode'    => '0644',
          'notify'  => 'Class[Rabbitmq::Service]',
          'content' => <<-EOS
rabbitmq soft nofile unlimited
rabbitmq hard nofile unlimited
EOS
        )
      }
    end

    context 'with file_limit => \'infinity\'' do
      let(:params) { { file_limit: 'infinity' } }

      it {
        is_expected.to contain_file('/etc/security/limits.d/rabbitmq-server.conf').with(
          'owner'   => '0',
          'group'   => '0',
          'mode'    => '0644',
          'notify'  => 'Class[Rabbitmq::Service]',
          'content' => <<-EOS
rabbitmq soft nofile infinity
rabbitmq hard nofile infinity
EOS
        )
      }
    end

    context 'with file_limit => \'-1\'' do
      let(:params) { { file_limit: '-1' } }

      it {
        is_expected.to contain_file('/etc/security/limits.d/rabbitmq-server.conf').with(
          'owner'   => '0',
          'group'   => '0',
          'mode'    => '0644',
          'notify'  => 'Class[Rabbitmq::Service]',
          'content' => <<-EOS
rabbitmq soft nofile -1
rabbitmq hard nofile -1
EOS
        )
      }
    end

    context 'with file_limit => \'1234\'' do
      let(:params) { { file_limit: '1234' } }

      it {
        is_expected.to contain_file('/etc/security/limits.d/rabbitmq-server.conf').with(
          'owner'   => '0',
          'group'   => '0',
          'mode'    => '0644',
          'notify'  => 'Class[Rabbitmq::Service]',
          'content' => <<-EOS
rabbitmq soft nofile 1234
rabbitmq hard nofile 1234
EOS
        )
      }
    end

    context 'with file_limit => \'-42\'' do
      let(:params) { { file_limit: '-42' } }

      it 'does not compile' do
        expect { catalogue }.to raise_error(Puppet::Error, %r{\$file_limit must be a positive integer, '-1', 'unlimited', or 'infinity'})
      end
    end

    context 'with file_limit => \'foo\'' do
      let(:params) { { file_limit: 'foo' } }

      it 'does not compile' do
        expect { catalogue }.to raise_error(Puppet::Error, %r{\$file_limit must be a positive integer, '-1', 'unlimited', or 'infinity'})
      end
    end
  end

  context 'on Redhat' do
    let(:params) { { repos_ensure: false } }

    with_redhat_facts
    it 'does not contain class rabbitmq::repo::rhel when repos_ensure is false' do
      is_expected.not_to contain_class('rabbitmq::repo::rhel')
    end
    it 'does not contain "rabbitmq" repo' do
      is_expected.not_to contain_yumrepo('rabbitmq')
    end
  end

  context 'on Redhat' do
    let(:params) { { repos_ensure: true } }

    with_redhat_facts
    it 'contains class rabbitmq::repo::rhel' do
      is_expected.to contain_class('rabbitmq::repo::rhel')
    end
    it 'contains "rabbitmq" repo' do
      is_expected.to contain_yumrepo('rabbitmq')
    end
    it 'the repo should be present, and contain the expected values' do
      is_expected.to contain_yumrepo('rabbitmq').with(ensure: 'present',
                                                      baseurl: 'https://packagecloud.io/rabbitmq/rabbitmq-server/el/$releasever/$basearch',
                                                      gpgkey: 'https://www.rabbitmq.com/rabbitmq-release-signing-key.asc')
    end
  end

  context 'on RedHat 7.0 or higher' do
    with_redhat_facts

    it {
      is_expected.to contain_file('/etc/systemd/system/rabbitmq-server.service.d').with(
        'ensure'                  => 'directory',
        'owner'                   => '0',
        'group'                   => '0',
        'mode'                    => '0755',
        'selinux_ignore_defaults' => true
      )
    }

    it {
      is_expected.to contain_exec('rabbitmq-systemd-reload').with(
        'command'     => '/usr/bin/systemctl daemon-reload',
        'notify'      => 'Class[Rabbitmq::Service]',
        'refreshonly' => true
      )
    }
    context 'with file_limit => \'unlimited\'' do
      let(:params) { { file_limit: 'unlimited' } }

      it {
        is_expected.to contain_file('/etc/systemd/system/rabbitmq-server.service.d/limits.conf').with(
          'owner'   => '0',
          'group'   => '0',
          'mode'    => '0644',
          'notify'  => 'Exec[rabbitmq-systemd-reload]',
          'content' => <<-EOS
[Service]
LimitNOFILE=unlimited
EOS
        )
      }
    end

    context 'with file_limit => \'infinity\'' do
      let(:params) { { file_limit: 'infinity' } }

      it {
        is_expected.to contain_file('/etc/systemd/system/rabbitmq-server.service.d/limits.conf').with(
          'owner'   => '0',
          'group'   => '0',
          'mode'    => '0644',
          'notify'  => 'Exec[rabbitmq-systemd-reload]',
          'content' => <<-EOS
[Service]
LimitNOFILE=infinity
EOS
        )
      }
    end

    context 'with file_limit => \'-1\'' do
      let(:params) { { file_limit: '-1' } }

      it {
        is_expected.to contain_file('/etc/systemd/system/rabbitmq-server.service.d/limits.conf').with(
          'owner'   => '0',
          'group'   => '0',
          'mode'    => '0644',
          'notify'  => 'Exec[rabbitmq-systemd-reload]',
          'content' => <<-EOS
[Service]
LimitNOFILE=-1
EOS
        )
      }
    end

    context 'with file_limit => \'1234\'' do
      let(:params) { { file_limit: '1234' } }

      it {
        is_expected.to contain_file('/etc/systemd/system/rabbitmq-server.service.d/limits.conf').with(
          'owner'   => '0',
          'group'   => '0',
          'mode'    => '0644',
          'notify'  => 'Exec[rabbitmq-systemd-reload]',
          'content' => <<-EOS
[Service]
LimitNOFILE=1234
EOS
        )
      }
    end
  end

  %w[Debian RedHat SUSE Archlinux].each do |distro|
    osfacts = {
      osfamily: distro,
      staging_http_get: '',
      puppetversion: Puppet.version
    }

    case distro
    when 'Debian'
      osfacts[:lsbdistcodename] = 'squeeze'
      osfacts[:lsbdistid] = 'Debian'
    when 'RedHat'
      osfacts[:operatingsystemmajrelease] = '7'
    end

    context "on #{distro}" do
      with_distro_facts distro

      it { is_expected.to contain_class('rabbitmq::install') }
      it { is_expected.to contain_class('rabbitmq::config') }
      it { is_expected.to contain_class('rabbitmq::service') }

      context 'with admin_enable set to true' do
        let(:params) { { admin_enable: true, management_ip_address: '1.1.1.1' } }

        context 'with service_manage set to true' do
          it 'we enable the admin interface by default' do
            is_expected.to contain_class('rabbitmq::install::rabbitmqadmin')
            is_expected.to contain_rabbitmq_plugin('rabbitmq_management').with(
              'require' => 'Class[Rabbitmq::Install]',
              'notify'  => 'Class[Rabbitmq::Service]'
            )
            is_expected.to contain_staging__file('rabbitmqadmin').with_source('http://1.1.1.1:15672/cli/rabbitmqadmin')
          end
        end
        context 'with $management_ip_address undef and service_manage set to true' do
          let(:params) { { admin_enable: true, management_ip_address: :undef } }

          it 'we enable the admin interface by default' do
            is_expected.to contain_class('rabbitmq::install::rabbitmqadmin')
            is_expected.to contain_rabbitmq_plugin('rabbitmq_management').with(
              'require' => 'Class[Rabbitmq::Install]',
              'notify'  => 'Class[Rabbitmq::Service]'
            )
            is_expected.to contain_staging__file('rabbitmqadmin').with_source('http://127.0.0.1:15672/cli/rabbitmqadmin')
          end
        end
        context 'with service_manage set to true, node_ip_address = undef, and default user/pass specified' do
          let(:params) { { admin_enable: true, default_user: 'foobar', default_pass: 'hunter2', node_ip_address: :undef } }

          it 'we use the correct URL to rabbitmqadmin' do
            is_expected.to contain_staging__file('rabbitmqadmin').with(
              source: 'http://127.0.0.1:15672/cli/rabbitmqadmin',
              curl_option: '-u "foobar:hunter2" -k  --retry 30 --retry-delay 6'
            )
          end
        end
        context 'with service_manage set to true and default user/pass specified' do
          let(:params) { { admin_enable: true, default_user: 'foobar', default_pass: 'hunter2', management_ip_address: '1.1.1.1' } }

          it 'we use the correct URL to rabbitmqadmin' do
            is_expected.to contain_staging__file('rabbitmqadmin').with(
              source: 'http://1.1.1.1:15672/cli/rabbitmqadmin',
              curl_option: '-u "foobar:hunter2" -k --noproxy 1.1.1.1 --retry 30 --retry-delay 6'
            )
          end
        end
        context 'with service_manage set to true and management port specified' do
          # note that the 2.x management port is 55672 not 15672
          let(:params) { { admin_enable: true, management_port: 55_672, management_ip_address: '1.1.1.1' } }

          it 'we use the correct URL to rabbitmqadmin' do
            is_expected.to contain_staging__file('rabbitmqadmin').with(
              source: 'http://1.1.1.1:55672/cli/rabbitmqadmin',
              curl_option: '-u "guest:guest" -k --noproxy 1.1.1.1 --retry 30 --retry-delay 6'
            )
          end
        end
        context 'with ipv6, service_manage set to true and management port specified' do
          # note that the 2.x management port is 55672 not 15672
          let(:params) { { admin_enable: true, management_port: 55_672, management_ip_address: '::1' } }

          it 'we use the correct URL to rabbitmqadmin' do
            is_expected.to contain_staging__file('rabbitmqadmin').with(
              source: 'http://[::1]:55672/cli/rabbitmqadmin',
              curl_option: '-u "guest:guest" -k --noproxy ::1 -g -6 --retry 30 --retry-delay 6'
            )
          end
        end
        context 'with service_manage set to false' do
          let(:params) { { admin_enable: true, service_manage: false } }

          it 'does nothing' do
            is_expected.not_to contain_class('rabbitmq::install::rabbitmqadmin')
            is_expected.not_to contain_rabbitmq_plugin('rabbitmq_management')
          end
        end
      end

      describe 'manages configuration directory correctly' do
        it {
          is_expected.to contain_file('/etc/rabbitmq').with(
            'ensure' => 'directory',
            'mode'   => '0755'
          )
        }
      end

      describe 'manages configuration file correctly' do
        it {
          is_expected.to contain_file('rabbitmq.config').with(
            'owner' => '0',
            'group' => 'rabbitmq',
            'mode'  => '0640'
          )
        }
      end

      context 'configures config_cluster' do
        let(:params) do
          {
            config_cluster: true,
            cluster_nodes: ['hare-1', 'hare-2'],
            cluster_node_type: 'ram',
            wipe_db_on_cookie_change: false
          }
        end

        describe 'with erlang_cookie set' do
          let(:params) do
            {
              config_cluster: true,
              cluster_nodes: ['hare-1', 'hare-2'],
              cluster_node_type: 'ram',
              erlang_cookie: 'TESTCOOKIE',
              wipe_db_on_cookie_change: true
            }
          end

          it 'contains the rabbitmq_erlang_cookie' do
            is_expected.to contain_rabbitmq_erlang_cookie('/var/lib/rabbitmq/.erlang.cookie')
          end
        end

        describe 'with erlang_cookie set but without config_cluster' do
          let(:params) do
            {
              config_cluster: false,
              erlang_cookie: 'TESTCOOKIE'
            }
          end

          it 'contains the rabbitmq_erlang_cookie' do
            is_expected.to contain_rabbitmq_erlang_cookie('/var/lib/rabbitmq/.erlang.cookie')
          end
        end

        describe 'without erlang_cookie and without config_cluster' do
          let(:params) do
            {
              config_cluster: false
            }
          end

          it 'contains the rabbitmq_erlang_cookie' do
            is_expected.not_to contain_rabbitmq_erlang_cookie('/var/lib/rabbitmq/.erlang.cookie')
          end
        end

        describe 'and sets appropriate configuration' do
          let(:params) do
            {
              config_cluster: true,
              cluster_nodes: ['hare-1', 'hare-2'],
              cluster_node_type: 'ram',
              erlang_cookie: 'ORIGINAL',
              wipe_db_on_cookie_change: true
            }
          end

          it 'for cluster_nodes' do
            is_expected.to contain_file('rabbitmq.config').with('content' => %r{cluster_nodes.*\['rabbit@hare-1', 'rabbit@hare-2'\], ram})
          end
        end
      end

      describe 'rabbitmq-env configuration' do
        context 'with default params' do
          it 'sets environment variables' do
            is_expected.to contain_file('rabbitmq-env.config'). \
              with_content(%r{ERL_INETRC=/etc/rabbitmq/inetrc})
          end
        end

        context 'with environment_variables set' do
          let(:params) do
            { environment_variables: {
              'NODE_IP_ADDRESS' => '1.1.1.1',
              'NODE_PORT'          => '5656',
              'NODENAME'           => 'HOSTNAME',
              'SERVICENAME'        => 'RabbitMQ',
              'CONSOLE_LOG'        => 'RabbitMQ.debug',
              'CTL_ERL_ARGS'       => 'verbose',
              'SERVER_ERL_ARGS'    => 'v',
              'SERVER_START_ARGS'  => 'debug'
            } }
          end

          it 'sets environment variables' do
            is_expected.to contain_file('rabbitmq-env.config'). \
              with_content(%r{NODE_IP_ADDRESS=1.1.1.1}). \
              with_content(%r{NODE_PORT=5656}). \
              with_content(%r{NODENAME=HOSTNAME}). \
              with_content(%r{SERVICENAME=RabbitMQ}). \
              with_content(%r{CONSOLE_LOG=RabbitMQ.debug}). \
              with_content(%r{CTL_ERL_ARGS=verbose}). \
              with_content(%r{SERVER_ERL_ARGS=v}). \
              with_content(%r{SERVER_START_ARGS=debug})
          end
        end
      end

      context 'delete_guest_user' do
        describe 'should do nothing by default' do
          it { is_expected.not_to contain_rabbitmq_user('guest') }
        end

        describe 'delete user when delete_guest_user set' do
          let(:params) { { delete_guest_user: true } }

          it 'removes the user' do
            is_expected.to contain_rabbitmq_user('guest').with(
              'ensure'   => 'absent',
              'provider' => 'rabbitmqctl'
            )
          end
        end
      end

      context 'configuration setting' do
        describe 'node_ip_address when set' do
          let(:params) { { node_ip_address: '172.0.0.1' } }

          it 'sets NODE_IP_ADDRESS to specified value' do
            is_expected.to contain_file('rabbitmq-env.config').
              with_content(%r{NODE_IP_ADDRESS=172\.0\.0\.1})
          end
        end

        describe 'stomp by default' do
          it 'does not specify stomp parameters in rabbitmq.config' do
            is_expected.to contain_file('rabbitmq.config').without('content' => %r{stomp})
          end
        end
        describe 'stomp when set' do
          let(:params) { { config_stomp: true, stomp_port: 5679 } }

          it 'specifies stomp port in rabbitmq.config' do
            is_expected.to contain_file('rabbitmq.config').with('content' => %r{rabbitmq_stomp.*tcp_listeners, \[5679\]}m)
          end
        end
        describe 'stomp when set ssl port w/o ssl enabled' do
          let(:params) { { config_stomp: true, stomp_port: 5679, ssl: false, ssl_stomp_port: 5680 } }

          it 'does not configure ssl_listeners in rabbitmq.config' do
            is_expected.to contain_file('rabbitmq.config').without('content' => %r{rabbitmq_stomp.*ssl_listeners, \[5680\]}m)
          end
        end
        describe 'stomp when set with ssl' do
          let(:params) { { config_stomp: true, stomp_port: 5679, ssl: true, ssl_stomp_port: 5680 } }

          it 'specifies stomp port and ssl stomp port in rabbitmq.config' do
            is_expected.to contain_file('rabbitmq.config').with('content' => %r{rabbitmq_stomp.*tcp_listeners, \[5679\].*ssl_listeners, \[5680\]}m)
          end
        end
      end

      describe 'configuring ldap authentication' do
        let :params do
          { config_stomp: true,
            ldap_auth: true,
            ldap_server: 'ldap.example.com',
            ldap_user_dn_pattern: 'ou=users,dc=example,dc=com',
            ldap_other_bind: 'as_user',
            ldap_use_ssl: false,
            ldap_port: 389,
            ldap_log: true,
            ldap_config_variables: { 'foo' => 'bar' } }
        end

        it { is_expected.to contain_rabbitmq_plugin('rabbitmq_auth_backend_ldap') }

        it 'contains ldap parameters' do
          verify_contents(catalogue, 'rabbitmq.config',
                          ['[', '  {rabbit, [', '    {auth_backends, [rabbit_auth_backend_internal, rabbit_auth_backend_ldap]},', '  ]}',
                           '  {rabbitmq_auth_backend_ldap, [', '    {other_bind, as_user},',
                           '    {servers, ["ldap.example.com"]},',
                           '    {user_dn_pattern, "ou=users,dc=example,dc=com"},', '    {use_ssl, false},',
                           '    {port, 389},', '    {foo, bar},', '    {log, true}'])
        end
      end

      describe 'configuring ldap authentication' do
        let :params do
          { config_stomp: false,
            ldap_auth: true,
            ldap_server: 'ldap.example.com',
            ldap_user_dn_pattern: 'ou=users,dc=example,dc=com',
            ldap_other_bind: 'as_user',
            ldap_use_ssl: false,
            ldap_port: 389,
            ldap_log: true,
            ldap_config_variables: { 'foo' => 'bar' } }
        end

        it { is_expected.to contain_rabbitmq_plugin('rabbitmq_auth_backend_ldap') }

        it 'contains ldap parameters' do
          verify_contents(catalogue, 'rabbitmq.config',
                          ['[', '  {rabbit, [', '    {auth_backends, [rabbit_auth_backend_internal, rabbit_auth_backend_ldap]},', '  ]}',
                           '  {rabbitmq_auth_backend_ldap, [', '    {other_bind, as_user},',
                           '    {servers, ["ldap.example.com"]},',
                           '    {user_dn_pattern, "ou=users,dc=example,dc=com"},', '    {use_ssl, false},',
                           '    {port, 389},', '    {foo, bar},', '    {log, true}'])
        end
      end

      describe 'configuring auth_backends' do
        let :params do
          { auth_backends: ['{baz, foo}', 'bar'] }
        end

        it 'contains auth_backends' do
          verify_contents(catalogue, 'rabbitmq.config',
                          ['    {auth_backends, [{baz, foo}, bar]},'])
        end
      end

      describe 'auth_backends overrides ldap_auth' do
        let :params do
          { auth_backends: ['{baz, foo}', 'bar'],
            ldap_auth: true }
        end

        it 'contains auth_backends' do
          verify_contents(catalogue, 'rabbitmq.config',
                          ['    {auth_backends, [{baz, foo}, bar]},'])
        end
      end

      describe 'configuring shovel plugin' do
        let :params do
          {
            config_shovel: true
          }
        end

        it { is_expected.to contain_rabbitmq_plugin('rabbitmq_shovel') }

        it { is_expected.to contain_rabbitmq_plugin('rabbitmq_shovel_management') }

        describe 'with admin_enable false' do
          let :params do
            {
              config_shovel: true,
              admin_enable: false
            }
          end

          it { is_expected.not_to contain_rabbitmq_plugin('rabbitmq_shovel_management') }
        end

        describe 'with static shovels' do
          let :params do
            {
              config_shovel: true,
              config_shovel_statics: {
                'shovel_first' => '{sources,[{broker,"amqp://"}]},
        {destinations,[{broker,"amqp://site1.example.com"}]},
        {queue,<<"source_one">>}',
                'shovel_second' => '{sources,[{broker,"amqp://"}]},
        {destinations,[{broker,"amqp://site2.example.com"}]},
        {queue,<<"source_two">>}'
              }
            }
          end

          it 'generates correct configuration' do
            verify_contents(catalogue, 'rabbitmq.config', [
                              '  {rabbitmq_shovel,',
                              '    [{shovels,[',
                              '      {shovel_first,[{sources,[{broker,"amqp://"}]},',
                              '        {destinations,[{broker,"amqp://site1.example.com"}]},',
                              '        {queue,<<"source_one">>}]},',
                              '      {shovel_second,[{sources,[{broker,"amqp://"}]},',
                              '        {destinations,[{broker,"amqp://site2.example.com"}]},',
                              '        {queue,<<"source_two">>}]}',
                              '    ]}]}'
                            ])
          end
        end
      end

      describe 'configuring shovel plugin' do
        let :params do
          {
            config_shovel: true
          }
        end

        it { is_expected.to contain_rabbitmq_plugin('rabbitmq_shovel') }

        it { is_expected.to contain_rabbitmq_plugin('rabbitmq_shovel_management') }

        describe 'with admin_enable false' do
          let :params do
            {
              config_shovel: true,
              admin_enable: false
            }
          end

          it { is_expected.not_to contain_rabbitmq_plugin('rabbitmq_shovel_management') }
        end

        describe 'with static shovels' do
          let :params do
            {
              config_shovel: true,
              config_shovel_statics: {
                'shovel_first' => '{sources,[{broker,"amqp://"}]},
        {destinations,[{broker,"amqp://site1.example.com"}]},
        {queue,<<"source_one">>}',
                'shovel_second' => '{sources,[{broker,"amqp://"}]},
        {destinations,[{broker,"amqp://site2.example.com"}]},
        {queue,<<"source_two">>}'
              }
            }
          end

          it 'generates correct configuration' do
            verify_contents(catalogue, 'rabbitmq.config', [
                              '  {rabbitmq_shovel,',
                              '    [{shovels,[',
                              '      {shovel_first,[{sources,[{broker,"amqp://"}]},',
                              '        {destinations,[{broker,"amqp://site1.example.com"}]},',
                              '        {queue,<<"source_one">>}]},',
                              '      {shovel_second,[{sources,[{broker,"amqp://"}]},',
                              '        {destinations,[{broker,"amqp://site2.example.com"}]},',
                              '        {queue,<<"source_two">>}]}',
                              '    ]}]}'
                            ])
          end
        end
      end

      describe 'default_user and default_pass set' do
        let(:params) { { default_user: 'foo', default_pass: 'bar' } }

        it 'sets default_user and default_pass to specified values' do
          is_expected.to contain_file('rabbitmq.config').with('content' => %r{default_user, <<"foo">>.*default_pass, <<"bar">>}m)
        end
      end

      describe 'interfaces option with no ssl' do
        let(:params) do
          { interface: '0.0.0.0' }
        end

        it 'sets ssl options to specified values' do
          is_expected.to contain_file('rabbitmq.config').with_content(%r{tcp_listeners, \[\{"0.0.0.0", 5672\}\]})
        end
      end

      describe 'ssl options and mangament_ssl false' do
        let(:params) do
          { ssl: true,
            ssl_port: 3141,
            ssl_cacert: '/path/to/cacert',
            ssl_cert: '/path/to/cert',
            ssl_key: '/path/to/key',
            management_ssl: false,
            management_port: 13_142 }
        end

        it 'sets ssl options to specified values' do
          is_expected.to contain_file('rabbitmq.config').with_content(
            %r{ssl_listeners, \[3141\]}
          )
          is_expected.to contain_file('rabbitmq.config').with_content(
            %r{ssl_options, \[}
          )
          is_expected.to contain_file('rabbitmq.config').with_content(
            %r{cacertfile,"/path/to/cacert"}
          )
          is_expected.to contain_file('rabbitmq.config').with_content(
            %r{certfile,"/path/to/cert"}
          )
          is_expected.to contain_file('rabbitmq.config').with_content(
            %r{keyfile,"/path/to/key"}
          )
        end
        it 'sets non ssl port for management port' do
          is_expected.to contain_file('rabbitmq.config').with_content(
            %r{port, 13142}
          )
          is_expected.to contain_file('rabbitmqadmin.conf').with_content(
            %r{port\s=\s13142}
          )
        end
      end

      describe 'ssl options and mangament_ssl true' do
        let(:params) do
          { ssl: true,
            ssl_port: 3141,
            ssl_cacert: '/path/to/cacert',
            ssl_cert: '/path/to/cert',
            ssl_key: '/path/to/key',
            management_ssl: true,
            ssl_management_port: 13_141 }
        end

        it 'sets ssl options to specified values' do
          is_expected.to contain_file('rabbitmq.config').with_content(
            %r{ssl_listeners, \[3141\]}
          )
          is_expected.to contain_file('rabbitmq.config').with_content(
            %r{ssl_opts, }
          )
          is_expected.to contain_file('rabbitmq.config').with_content(
            %r{ssl_options, \[}
          )
          is_expected.to contain_file('rabbitmq.config').with_content(
            %r{cacertfile,"/path/to/cacert"}
          )
          is_expected.to contain_file('rabbitmq.config').with_content(
            %r{certfile,"/path/to/cert"}
          )
          is_expected.to contain_file('rabbitmq.config').with_content(
            %r{keyfile,"/path/to/key"}
          )
        end
        it 'sets ssl managment port to specified values' do
          is_expected.to contain_file('rabbitmq.config').with_content(
            %r{port, 13141}
          )
        end
        it 'sets ssl options in the rabbitmqadmin.conf' do
          is_expected.to contain_file('rabbitmqadmin.conf').with_content(
            %r{ssl_ca_cert_file\s=\s/path/to/cacert}
          )
          is_expected.to contain_file('rabbitmqadmin.conf').with_content(
            %r{ssl_cert_file\s=\s/path/to/cert}
          )
          is_expected.to contain_file('rabbitmqadmin.conf').with_content(
            %r{ssl_key_file\s=\s/path/to/key}
          )
          is_expected.to contain_file('rabbitmqadmin.conf').with_content(
            %r{hostname\s=\s}
          )
          is_expected.to contain_file('rabbitmqadmin.conf').with_content(
            %r{port\s=\s13141}
          )
        end
      end

      describe 'ssl options' do
        let(:params) do
          { ssl: true,
            ssl_port: 3141,
            ssl_cacert: '/path/to/cacert',
            ssl_cert: '/path/to/cert',
            ssl_key: '/path/to/key' }
        end

        it 'sets ssl options to specified values' do
          is_expected.to contain_file('rabbitmq.config').with_content(
            %r{ssl_listeners, \[3141\]}
          )
          is_expected.to contain_file('rabbitmq.config').with_content(
            %r{ssl_options, \[}
          )
          is_expected.to contain_file('rabbitmq.config').with_content(
            %r{cacertfile,"/path/to/cacert"}
          )
          is_expected.to contain_file('rabbitmq.config').with_content(
            %r{certfile,"/path/to/cert"}
          )
          is_expected.to contain_file('rabbitmq.config').with_content(
            %r{keyfile,"/path/to/key"}
          )
        end
      end

      describe 'ssl options with ssl_interfaces' do
        let(:params) do
          { ssl: true,
            ssl_port: 3141,
            ssl_interface: '0.0.0.0',
            ssl_cacert: '/path/to/cacert',
            ssl_cert: '/path/to/cert',
            ssl_key: '/path/to/key' }
        end

        it 'sets ssl options to specified values' do
          is_expected.to contain_file('rabbitmq.config').with_content(%r{ssl_listeners, \[\{"0.0.0.0", 3141\}\]})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{cacertfile,"/path/to/cacert"})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{certfile,"/path/to/cert"})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{keyfile,"/path/to/key})
        end
      end

      describe 'ssl options with ssl_only' do
        let(:params) do
          { ssl: true,
            ssl_only: true,
            ssl_port: 3141,
            ssl_cacert: '/path/to/cacert',
            ssl_cert: '/path/to/cert',
            ssl_key: '/path/to/key' }
        end

        it 'sets ssl options to specified values' do
          is_expected.to contain_file('rabbitmq.config').with_content(%r{tcp_listeners, \[\]})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{ssl_listeners, \[3141\]})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{ssl_options, \[})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{cacertfile,"/path/to/cacert"})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{certfile,"/path/to/cert"})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{keyfile,"/path/to/key})
        end
        it 'does not set TCP listener environment defaults' do
          is_expected.to contain_file('rabbitmq-env.config'). \
            without_content(%r{NODE_PORT=}). \
            without_content(%r{NODE_IP_ADDRESS=})
        end
      end

      describe 'ssl options with ssl_only and ssl_interfaces' do
        let(:params) do
          { ssl: true,
            ssl_only: true,
            ssl_port: 3141,
            ssl_interface: '0.0.0.0',
            ssl_cacert: '/path/to/cacert',
            ssl_cert: '/path/to/cert',
            ssl_key: '/path/to/key' }
        end

        it 'sets ssl options to specified values' do
          is_expected.to contain_file('rabbitmq.config').with_content(%r{tcp_listeners, \[\]})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{ssl_listeners, \[\{"0.0.0.0", 3141\}\]})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{cacertfile,"/path/to/cacert"})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{certfile,"/path/to/cert"})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{keyfile,"/path/to/key})
        end
      end

      describe 'ssl options with specific ssl versions' do
        let(:params) do
          { ssl: true,
            ssl_port: 3141,
            ssl_cacert: '/path/to/cacert',
            ssl_cert: '/path/to/cert',
            ssl_key: '/path/to/key',
            ssl_versions: ['tlsv1.2', 'tlsv1.1'] }
        end

        it 'sets ssl options to specified values' do
          is_expected.to contain_file('rabbitmq.config').with_content(%r{ssl_listeners, \[3141\]})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{ssl_options, \[})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{cacertfile,"/path/to/cacert"})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{certfile,"/path/to/cert"})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{keyfile,"/path/to/key})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{ssl, \[\{versions, \['tlsv1.1', 'tlsv1.2'\]\}\]})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{versions, \['tlsv1.1', 'tlsv1.2'\]})
        end
      end

      describe 'ssl options with ssl_versions and not ssl' do
        let(:params) do
          { ssl: false,
            ssl_port: 3141,
            ssl_cacert: '/path/to/cacert',
            ssl_cert: '/path/to/cert',
            ssl_key: '/path/to/key',
            ssl_versions: ['tlsv1.2', 'tlsv1.1'] }
        end

        it 'fails' do
          expect { catalogue }.to raise_error(Puppet::Error, %r{\$ssl_versions requires that \$ssl => true})
        end
      end

      describe 'ssl options with ssl ciphers' do
        let(:params) do
          { ssl: true,
            ssl_port: 3141,
            ssl_cacert: '/path/to/cacert',
            ssl_cert: '/path/to/cert',
            ssl_key: '/path/to/key',
            ssl_ciphers: ['ecdhe_rsa,aes_256_cbc,sha', 'dhe_rsa,aes_256_cbc,sha'] }
        end

        it 'sets ssl ciphers to specified values' do
          is_expected.to contain_file('rabbitmq.config').with_content(%r{ciphers,\[[[:space:]]+{dhe_rsa,aes_256_cbc,sha},[[:space:]]+{ecdhe_rsa,aes_256_cbc,sha}[[:space:]]+\]})
        end
      end

      describe 'ssl admin options with specific ssl versions' do
        let(:params) do
          { ssl: true,
            ssl_management_port: 5926,
            ssl_cacert: '/path/to/cacert',
            ssl_cert: '/path/to/cert',
            ssl_key: '/path/to/key',
            ssl_versions: ['tlsv1.2', 'tlsv1.1'],
            admin_enable: true }
        end

        it 'sets admin ssl opts to specified values' do
          is_expected.to contain_file('rabbitmq.config').with_content(%r{rabbitmq_management, \[})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{listener, \[})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{port, 5926\}})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{ssl, true\}})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{ssl_opts, \[})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{cacertfile, "/path/to/cacert"\},})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{certfile, "/path/to/cert"\},})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{keyfile, "/path/to/key"\}})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{,\{versions, \['tlsv1.1', 'tlsv1.2'\]\}})
        end
      end

      describe 'ssl admin options' do
        let(:params) do
          { ssl: true,
            ssl_management_port: 3141,
            ssl_cacert: '/path/to/cacert',
            ssl_cert: '/path/to/cert',
            ssl_key: '/path/to/key',
            admin_enable: true }
        end

        it 'sets rabbitmq_management ssl options to specified values' do
          is_expected.to contain_file('rabbitmq.config').with_content(%r{rabbitmq_management, \[})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{listener, \[})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{port, 3141\}})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{ssl, true\}})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{ssl_opts, \[})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{cacertfile, "/path/to/cacert"\},})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{certfile, "/path/to/cert"\},})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{keyfile, "/path/to/key"\}})
        end
      end

      describe 'admin without ssl' do
        let(:params) do
          { ssl: false,
            management_port: 3141,
            admin_enable: true }
        end

        it 'sets rabbitmq_management options to specified values' do
          is_expected.to contain_file('rabbitmq.config').with_content(%r{rabbitmq_management, \[})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{listener, \[})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{port, 3141\}})
        end
      end

      describe 'ssl admin options' do
        let(:params) do
          { ssl: true,
            ssl_management_port: 3141,
            ssl_cacert: '/path/to/cacert',
            ssl_cert: '/path/to/cert',
            ssl_key: '/path/to/key',
            admin_enable: true }
        end

        it 'sets rabbitmq_management ssl options to specified values' do
          is_expected.to contain_file('rabbitmq.config').with_content(%r{rabbitmq_management, \[})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{listener, \[})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{port, 3141\},})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{ssl, true\},})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{ssl_opts, \[})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{cacertfile, "/path/to/cacert"\},})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{certfile, "/path/to/cert"\},})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{keyfile, "/path/to/key"\}})
        end
      end

      describe 'admin without ssl' do
        let(:params) do
          { ssl: false,
            management_port: 3141,
            admin_enable: true }
        end

        it 'sets rabbitmq_management options to specified values' do
          is_expected.to contain_file('rabbitmq.config'). \
            with_content(%r{\{rabbitmq_management, \[}). \
            with_content(%r{\{listener, \[}). \
            with_content(%r{\{port, 3141\}})
        end
      end

      describe 'ipv6 enabled' do
        let(:params) { { ipv6: true } }

        it 'enables resolver inet6 in inetrc' do
          is_expected.to contain_file('rabbitmq-inetrc').with_content(%r{{inet6, true}.})
        end

        context 'without other erl args' do
          it 'enables inet6 distribution' do
            is_expected.to contain_file('rabbitmq-env.config'). \
              with_content(%r{^RABBITMQ_SERVER_ERL_ARGS="-proto_dist inet6_tcp"$}). \
              with_content(%r{^RABBITMQ_CTL_ERL_ARGS="-proto_dist inet6_tcp"$})
          end
        end

        context 'with other quoted erl args' do
          let(:params) do
            { ipv6: true,
              environment_variables: { 'RABBITMQ_SERVER_ERL_ARGS' => '"some quoted args"',
                                       'RABBITMQ_CTL_ERL_ARGS'    => '"other quoted args"' } }
          end

          it 'enables inet6 distribution and quote properly' do
            is_expected.to contain_file('rabbitmq-env.config'). \
              with_content(%r{^RABBITMQ_SERVER_ERL_ARGS="some quoted args -proto_dist inet6_tcp"$}). \
              with_content(%r{^RABBITMQ_CTL_ERL_ARGS="other quoted args -proto_dist inet6_tcp"$})
          end
        end

        context 'with other unquoted erl args' do
          let(:params) do
            { ipv6: true,
              environment_variables: { 'RABBITMQ_SERVER_ERL_ARGS' => 'foo',
                                       'RABBITMQ_CTL_ERL_ARGS'    => 'bar' } }
          end

          it 'enables inet6 distribution and quote properly' do
            is_expected.to contain_file('rabbitmq-env.config'). \
              with_content(%r{^RABBITMQ_SERVER_ERL_ARGS="foo -proto_dist inet6_tcp"$}). \
              with_content(%r{^RABBITMQ_CTL_ERL_ARGS="bar -proto_dist inet6_tcp"$})
          end
        end
      end

      describe 'config_variables options' do
        let(:params) do
          { config_variables: {
            'hipe_compile' => true,
            'vm_memory_high_watermark'      => 0.4,
            'frame_max'                     => 131_072,
            'collect_statistics'            => 'none',
            'auth_mechanisms'               => "['PLAIN', 'AMQPLAIN']"
          } }
        end

        it 'sets environment variables' do
          is_expected.to contain_file('rabbitmq.config'). \
            with_content(%r{\{hipe_compile, true\}}). \
            with_content(%r{\{vm_memory_high_watermark, 0.4\}}). \
            with_content(%r{\{frame_max, 131072\}}). \
            with_content(%r{\{collect_statistics, none\}}). \
            with_content(%r{\{auth_mechanisms, \['PLAIN', 'AMQPLAIN'\]\}})
        end
      end

      describe 'config_kernel_variables options' do
        let(:params) do
          { config_kernel_variables: {
            'inet_dist_listen_min' => 9100,
            'inet_dist_listen_max' => 9105
          } }
        end

        it 'sets config variables' do
          is_expected.to contain_file('rabbitmq.config'). \
            with_content(%r{\{inet_dist_listen_min, 9100\}}). \
            with_content(%r{\{inet_dist_listen_max, 9105\}})
        end
      end

      describe 'config_management_variables' do
        let(:params) do
          { config_management_variables: {
            'rates_mode' => 'none'
          } }
        end

        it 'sets config variables' do
          is_expected.to contain_file('rabbitmq.config'). \
            with_content(%r{\{rates_mode, none\}})
        end
      end

      describe 'tcp_keepalive enabled' do
        let(:params) { { tcp_keepalive: true } }

        it 'sets tcp_listen_options keepalive true' do
          is_expected.to contain_file('rabbitmq.config'). \
            with_content(%r{\{keepalive,     true\}})
        end
      end

      describe 'tcp_keepalive disabled (default)' do
        it 'does not set tcp_listen_options' do
          is_expected.to contain_file('rabbitmq.config'). \
            without_content(%r{\{keepalive,     true\}})
        end
      end

      describe 'tcp_backlog with default value' do
        it 'sets tcp_listen_options backlog to 128' do
          is_expected.to contain_file('rabbitmq.config'). \
            with_content(%r{\{backlog,       128\}})
        end
      end

      describe 'tcp_backlog with non-default value' do
        let(:params) do
          { tcp_backlog: 256 }
        end

        it 'sets tcp_listen_options backlog to 256' do
          is_expected.to contain_file('rabbitmq.config'). \
            with_content(%r{\{backlog,       256\}})
        end
      end

      describe 'tcp_sndbuf with default value' do
        it 'does not set tcp_listen_options sndbuf' do
          is_expected.to contain_file('rabbitmq.config'). \
            without_content(%r{sndbuf})
        end
      end

      describe 'tcp_sndbuf with non-default value' do
        let(:params) do
          { tcp_sndbuf: 128 }
        end

        it 'sets tcp_listen_options sndbuf to 128' do
          is_expected.to contain_file('rabbitmq.config'). \
            with_content(%r{\{sndbuf,       128\}})
        end
      end

      describe 'tcp_recbuf with default value' do
        it 'does not set tcp_listen_options recbuf' do
          is_expected.to contain_file('rabbitmq.config'). \
            without_content(%r{recbuf})
        end
      end

      describe 'tcp_recbuf with non-default value' do
        let(:params) do
          { tcp_recbuf: 128 }
        end

        it 'sets tcp_listen_options recbuf to 128' do
          is_expected.to contain_file('rabbitmq.config'). \
            with_content(%r{\{recbuf,       128\}})
        end
      end

      describe 'rabbitmq-heartbeat options' do
        let(:params) { { heartbeat: 60 } }

        it 'sets heartbeat paramter in config file' do
          is_expected.to contain_file('rabbitmq.config'). \
            with_content(%r{\{heartbeat, 60\}})
        end
      end

      context 'delete_guest_user' do
        describe 'should do nothing by default' do
          it { is_expected.not_to contain_rabbitmq_user('guest') }
        end

        describe 'delete user when delete_guest_user set' do
          let(:params) { { delete_guest_user: true } }

          it 'removes the user' do
            is_expected.to contain_rabbitmq_user('guest').with(
              'ensure'   => 'absent',
              'provider' => 'rabbitmqctl'
            )
          end
        end
      end

      ##
      ## rabbitmq::service
      ##
      describe 'service with default params' do
        it {
          is_expected.to contain_service('rabbitmq-server').with(
            'ensure'     => 'running',
            'enable'     => 'true',
            'hasstatus'  => 'true',
            'hasrestart' => 'true'
          )
        }
      end

      describe 'service with ensure stopped' do
        let :params do
          { service_ensure: 'stopped' }
        end

        it {
          is_expected.to contain_service('rabbitmq-server').with(
            'ensure'    => 'stopped',
            'enable'    => false
          )
        }
      end

      describe 'service with service_manage equal to false' do
        let :params do
          { service_manage: false }
        end

        it { is_expected.not_to contain_service('rabbitmq-server') }
      end
    end
  end

  ##
  ## rabbitmq::install
  ##
  context 'on RHEL with repos_ensure' do
    with_redhat_facts
    let(:params) { { repos_ensure: true } }

    it 'installs the rabbitmq package' do
      is_expected.to contain_package('rabbitmq-server').with(
        'ensure'   => 'installed',
        'name'     => 'rabbitmq-server'
      )
    end
  end

  context 'on RHEL' do
    with_redhat_facts
    let(:params) { { repos_ensure: false } }

    it 'installs the rabbitmq package [from EPEL] when $repos_ensure is false' do
      is_expected.to contain_package('rabbitmq-server').with(
        'ensure'   => 'installed',
        'name'     => 'rabbitmq-server'
      )
    end
  end

  context 'on Debian' do
    with_debian_facts
    it 'installs the rabbitmq package' do
      is_expected.to contain_package('rabbitmq-server').with(
        'ensure'   => 'installed',
        'name'     => 'rabbitmq-server'
      )
    end
  end

  context 'on Archlinux' do
    with_archlinux_facts
    it 'installs the rabbitmq package' do
      is_expected.to contain_package('rabbitmq-server').with(
        'ensure'   => 'installed'
      )
    end
  end

  context 'on OpenBSD' do
    with_openbsd_facts
    it 'installs the rabbitmq package' do
      is_expected.to contain_package('rabbitmq-server').with(
        'ensure'   => 'installed',
        'name'     => 'rabbitmq'
      )
    end
  end

  context "on FreeBSD" do
    with_freebsd_facts
    it 'installs the rabbitmq package' do
      should contain_package('rabbitmq-server').with(
        'ensure'   => 'installed',
        'name'     => 'rabbitmq',
        'provider' => 'freebsd'
      )
    end
  end

  describe 'repo management on Debian' do
    with_debian_facts

    context 'with no pin' do
      let(:params) { { repos_ensure: true, package_apt_pin: '' } }

      describe 'it sets up an apt::source' do
        it {
          is_expected.to contain_apt__source('rabbitmq').with(
            'location'    => 'http://www.rabbitmq.com/debian/',
            'release'     => 'testing',
            'repos'       => 'main',
            'key'         => '{"id"=>"0A9AF2115F4687BD29803A206B73A36E6026DFCA", "source"=>"https://www.rabbitmq.com/rabbitmq-release-signing-key.asc", "content"=>:undef}'
          )
        }
      end
    end

    context 'with pin' do
      let(:params) { { repos_ensure: true, package_apt_pin: '700' } }

      describe 'it sets up an apt::source and pin' do
        it {
          is_expected.to contain_apt__source('rabbitmq').with(
            'location'    => 'http://www.rabbitmq.com/debian/',
            'release'     => 'testing',
            'repos'       => 'main',
            'key'         => '{"id"=>"0A9AF2115F4687BD29803A206B73A36E6026DFCA", "source"=>"https://www.rabbitmq.com/rabbitmq-release-signing-key.asc", "content"=>:undef}'
          )
        }

        it {
          is_expected.to contain_apt__pin('rabbitmq').with(
            'packages' => '*',
            'priority' => '700',
            'origin'   => 'www.rabbitmq.com'
          )
        }
      end
    end
  end
end
