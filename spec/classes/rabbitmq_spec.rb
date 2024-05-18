# frozen_string_literal: true

# rubocop:disable RSpec/RepeatedExampleGroupDescription
# rubocop:disable RSpec/RepeatedExampleGroupBody

require 'spec_helper'

describe 'rabbitmq' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let :facts do
        os_facts
      end

      name = case os_facts[:os]['family']
             when 'Archlinux', 'OpenBSD', 'FreeBSD'
               'rabbitmq'
             else
               'rabbitmq-server'
             end

      rabbitmq_home = case os_facts[:os]['family']
                      when 'FreeBSD'
                        '/var/db/rabbitmq'
                      else
                        '/var/lib/rabbitmq'
                      end

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to contain_class('rabbitmq::install') }
      it { is_expected.to contain_class('rabbitmq::config').that_notifies('Class[rabbitmq::service]') }
      it { is_expected.to contain_class('rabbitmq::service') }

      it { is_expected.to contain_package(name).with_ensure('installed').with_name(name) }

      it { is_expected.to contain_package('rabbitmq-server-plugins') } if os_facts[:os]['family'] == 'Suse'

      context 'with default params' do
        if os_facts[:os]['family'] == 'Debian'
          it 'includes rabbitmq::repo::apt' do
            is_expected.to contain_class('rabbitmq::repo::apt').
              with_key_source('https://packagecloud.io/rabbitmq/rabbitmq-server/gpgkey').
              with_key_content(nil)
          end

          it 'adds a repo with default values' do
            is_expected.to contain_apt__source('rabbitmq').
              with_ensure('present').
              with_location("https://packagecloud.io/rabbitmq/rabbitmq-server/#{os_facts[:os]['name'].downcase}").
              with_release(nil).
              with_repos('main')
          end
        else
          it { is_expected.not_to contain_class('rabbitmq::repo::apt') }
          it { is_expected.not_to contain_apt__souce('rabbitmq') }
        end

        if os_facts[:os]['family'] == 'RedHat'
          it { is_expected.to contain_class('rabbitmq::repo::rhel') }

          it 'the repo should be present, and contain the expected values' do
            is_expected.to contain_yumrepo('rabbitmq').
              with_ensure('present').
              with_baseurl(%r{https://packagecloud.io/rabbitmq/rabbitmq-server/el/\d+/\$basearch$}).
              with_gpgkey('https://packagecloud.io/rabbitmq/rabbitmq-server/gpgkey')
          end
        else
          it { is_expected.not_to contain_class('rabbitmq::repo::rhel') }
          it { is_expected.not_to contain_yumrepo('rabbitmq') }
        end
      end

      context 'with service_restart => false' do
        let(:params) { { service_restart: false } }

        it { is_expected.not_to contain_class('rabbitmq::config').that_notifies('Class[rabbitmq::service]') }
      end

      context 'with repos_ensure => false' do
        let(:params) { { repos_ensure: false } }

        it { is_expected.not_to contain_class('rabbitmq::repo::apt') }
        it { is_expected.not_to contain_apt__source('rabbitmq') }
        it { is_expected.not_to contain_class('rabbitmq::repo::rhel') }
        it { is_expected.not_to contain_yumrepo('rabbitmq') }
      end

      context 'with no pin', if: os_facts[:os]['family'] == 'Debian' do
        let(:params) { { package_apt_pin: '' } }

        describe 'it sets up an apt::source' do
          it {
            is_expected.to contain_apt__source('rabbitmq').with(
              'location' => "https://packagecloud.io/rabbitmq/rabbitmq-server/#{os_facts[:os]['name'].downcase}",
              'repos' => 'main',
              'key' => '{"id"=>"8C695B0219AFDEB04A058ED8F4E789204D206F89", "source"=>"https://packagecloud.io/rabbitmq/rabbitmq-server/gpgkey", "content"=>nil}'
            )
          }
        end
      end

      context 'with pin', if: os_facts[:os]['family'] == 'Debian' do
        let(:params) { { package_apt_pin: '700' } }

        describe 'it sets up an apt::source and pin' do
          it {
            is_expected.to contain_apt__source('rabbitmq').with(
              'location' => "https://packagecloud.io/rabbitmq/rabbitmq-server/#{os_facts[:os]['name'].downcase}",
              'repos' => 'main',
              'key' => '{"id"=>"8C695B0219AFDEB04A058ED8F4E789204D206F89", "source"=>"https://packagecloud.io/rabbitmq/rabbitmq-server/gpgkey", "content"=>nil}'
            )
          }

          it {
            is_expected.to contain_apt__pin('rabbitmq').with(
              'packages' => '*',
              'priority' => '700',
              'origin' => 'packagecloud.io'
            )
          }
        end
      end

      ['infinity', -1, 1234].each do |value|
        context "with file_limit => '#{value}'" do
          let(:params) { { file_limit: value } }

          if os_facts[:os]['family'] == 'RedHat'
            it do
              is_expected.to contain_file('/etc/security/limits.d/rabbitmq-server.conf').
                with_owner('0').
                with_group('0').
                with_mode('0644').
                that_notifies('Class[Rabbitmq::Service]').
                with_content("rabbitmq soft nofile #{value}\nrabbitmq hard nofile #{value}\n")
            end
          else
            it { is_expected.not_to contain_file('/etc/security/limits.d/rabbitmq-server.conf') }
          end

          if os_facts[:os]['family'] == 'Debian'
            it { is_expected.to contain_file('/etc/default/rabbitmq-server').with_content(%r{ulimit -n #{value}}) }
          else
            it { is_expected.not_to contain_file('/etc/default/rabbitmq-server') }
          end

          if os_facts[:systemd]
            selinux_ignore_defaults = os_facts[:os]['family'] == 'RedHat'

            it do
              is_expected.to contain_systemd__service_limits("#{name}.service").
                with_selinux_ignore_defaults(selinux_ignore_defaults).
                with_limits('LimitNOFILE' => value).
                with_restart_service(false)
            end
          else
            it { is_expected.not_to contain_systemd__service_limits("#{name}.service") }
          end
        end
      end

      [-42, '-42', 'foo'].each do |value|
        context "with file_limit => '#{value}'" do
          let(:params) { { file_limit: value } }

          it 'does not compile' do
            expect { catalogue }.to raise_error(Puppet::PreformattedError, %r{Error while evaluating a Resource Statement})
          end
        end
      end

      [-1000, 0, 1000].each do |value|
        context "with oom_score_adj => '#{value}'" do
          let(:params) { { oom_score_adj: value } }

          if os_facts[:os]['family'] == 'Debian'
            it { is_expected.to contain_file('/etc/default/rabbitmq-server').with_content(%r{^echo #{value} > /proc/\$\$/oom_score_adj$}) }
          else
            it { is_expected.not_to contain_file('/etc/default/rabbitmq-server') }
          end

          if os_facts[:systemd]
            it do
              is_expected.to contain_systemd__service_limits("#{name}.service").
                with_limits('OOMScoreAdjust' => value).
                with_restart_service(false)
            end
          else
            it { is_expected.not_to contain_systemd__service_limits("#{name}.service") }
          end
        end
      end

      [-2000, 2000, '500', 'foo'].each do |value|
        context "with oom_score_adj => '#{value}'" do
          let(:params) { { oom_score_adj: value } }

          it 'does not compile' do
            expect { catalogue }.to raise_error(Puppet::PreformattedError, %r{Error while evaluating a Resource Statement})
          end
        end
      end

      context 'on systems with systemd', if: os_facts[:systemd] do
        it do
          is_expected.to contain_systemd__service_limits("#{name}.service").
            with_restart_service(false)
        end
      end

      context 'on systems without systemd', unless: os_facts[:systemd] do
        it { is_expected.not_to contain_systemd__service_limits("#{name}.service") }
      end

      context 'with admin_enable set to true' do
        let(:params) { { admin_enable: true, management_ip_address: '1.1.1.1' } }

        context 'with service_manage set to true' do
          let(:params) { { admin_enable: true, management_ip_address: '1.1.1.1', service_manage: true } }

          context 'with rabbitmqadmin_package set to blub' do
            let(:params) { { rabbitmqadmin_package: 'blub' } }

            it 'installs a package called blub' do
              is_expected.to contain_package('rabbitmqadmin').with_name('blub')
            end
          end

          it 'we enable the admin interface by default' do
            is_expected.to contain_class('rabbitmq::install::rabbitmqadmin')
            is_expected.to contain_rabbitmq_plugin('rabbitmq_management').with(
              notify: 'Class[Rabbitmq::Service]'
            )
            is_expected.to contain_archive('rabbitmqadmin').with_source('http://1.1.1.1:15672/cli/rabbitmqadmin')
          end

          it { is_expected.to contain_package('python') } if %w[Debian SUSE Archlinux].include?(os_facts[:os]['family'])
          it { is_expected.to contain_package('python3') } if %w[RedHat].include?(os_facts[:os]['family'])
          it { is_expected.to contain_package('python38') } if %w[FreeBSD].include?(os_facts[:os]['family'])
        end

        context 'with manage_python false' do
          let(:params) { { manage_python: false } }

          it do
            is_expected.to contain_class('rabbitmq::install::rabbitmqadmin')
            is_expected.not_to contain_package('python')
            is_expected.not_to contain_package('python2')
            is_expected.not_to contain_package('python3')
          end
        end

        context 'with $management_ip_address undef and service_manage set to true', unless: os_facts[:os]['family'] == 'Archlinux' do
          let(:params) { { admin_enable: true, management_ip_address: :undef } }

          it 'we enable the admin interface by default' do
            is_expected.to contain_class('rabbitmq::install::rabbitmqadmin')
            is_expected.to contain_rabbitmq_plugin('rabbitmq_management').with(
              notify: 'Class[Rabbitmq::Service]'
            )
            is_expected.to contain_archive('rabbitmqadmin').with_source('http://127.0.0.1:15672/cli/rabbitmqadmin')
          end
        end

        context 'with service_manage set to true, node_ip_address = undef, and default user/pass specified', unless: os_facts[:os]['family'] == 'Archlinux' do
          let(:params) { { admin_enable: true, default_user: 'foobar', default_pass: 'hunter2', node_ip_address: :undef } }

          it 'we use the correct URL to rabbitmqadmin' do
            is_expected.to contain_archive('rabbitmqadmin').with(
              source: 'http://127.0.0.1:15672/cli/rabbitmqadmin',
              username: 'foobar',
              password: 'hunter2'
            )
          end
        end

        context 'with service_manage set to true and default user/pass specified', unless: os_facts[:os]['family'] == 'Archlinux' do
          let(:params) { { admin_enable: true, default_user: 'foobar', default_pass: 'hunter2', management_ip_address: '1.1.1.1' } }

          it 'we use the correct URL to rabbitmqadmin' do
            is_expected.to contain_archive('rabbitmqadmin').with(
              source: 'http://1.1.1.1:15672/cli/rabbitmqadmin',
              username: 'foobar',
              password: 'hunter2'
            )
          end
        end

        context 'with service_manage set to true and archive_options set', unless: os_facts[:os]['family'] == 'Archlinux' do
          let(:params) do
            {
              admin_enable: true,
              management_ip_address: '1.1.1.1',
              archive_options: %w[fizz pop]
            }
          end

          it 'we use the correct archive_options to rabbitmqadmin' do
            is_expected.to contain_archive('rabbitmqadmin').with(
              source: 'http://1.1.1.1:15672/cli/rabbitmqadmin',
              download_options: %w[fizz pop]
            )
          end
        end

        context 'with service_manage set to true and management port specified', unless: os_facts[:os]['family'] == 'Archlinux' do
          # NOTE: that the 2.x management port is 55672 not 15672
          let(:params) { { admin_enable: true, management_port: 55_672, management_ip_address: '1.1.1.1' } }

          it 'we use the correct URL to rabbitmqadmin' do
            is_expected.to contain_archive('rabbitmqadmin').with(
              source: 'http://1.1.1.1:55672/cli/rabbitmqadmin',
              username: 'guest',
              password: 'guest'
            )
          end
        end

        context 'with ipv6, service_manage set to true and management port specified', unless: os_facts[:os]['family'] == 'Archlinux' do
          # NOTE: that the 2.x management port is 55672 not 15672
          let(:params) { { admin_enable: true, management_port: 55_672, management_ip_address: '::1' } }

          it 'we use the correct URL to rabbitmqadmin' do
            is_expected.to contain_archive('rabbitmqadmin').with(
              source: 'http://[::1]:55672/cli/rabbitmqadmin',
              username: 'guest',
              password: 'guest'
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
            'owner' => 'rabbitmq',
            'group' => 'rabbitmq',
            'mode' => '2755'
          )
        }
      end

      describe 'manages configuration file correctly' do
        it {
          is_expected.to contain_file('rabbitmq.config').with(
            'owner' => 'rabbitmq',
            'group' => 'rabbitmq',
            'mode' => '0640'
          )
        }
      end

      describe 'manages SSL directory correctly' do
        it {
          is_expected.to contain_file('/etc/rabbitmq/ssl').with(
            'ensure' => 'directory',
            'owner' => 'rabbitmq',
            'group' => 'rabbitmq',
            'mode' => '2750'
          )
        }
      end

      describe 'does not contain pre-ranch settings with default config' do
        it do
          is_expected.to contain_file('rabbitmq.config'). \
            without_content(%r{binary,}).                 \
            without_content(%r{\{packet,        raw\},}). \
            without_content(%r{\{reuseaddr,     true\},})
        end
      end

      describe 'contains pre-ranch settings with config_ranch set to false' do
        let(:params) { { config_ranch: false } }

        it do
          is_expected.to contain_file('rabbitmq.config'). \
            with_content(%r{binary,}).                 \
            with_content(%r{\{packet,        raw\},}). \
            with_content(%r{\{reuseaddr,     true\},})
        end
      end

      context 'configures config_cluster' do
        let(:params) do
          {
            config_cluster: true,
            cluster_nodes: %w[hare-1 hare-2],
            cluster_node_type: 'ram',
            wipe_db_on_cookie_change: false
          }
        end

        describe 'with erlang_cookie set' do
          let(:params) do
            {
              config_cluster: true,
              cluster_nodes: %w[hare-1 hare-2],
              cluster_node_type: 'ram',
              erlang_cookie: 'TESTCOOKIE',
              wipe_db_on_cookie_change: true
            }
          end

          it 'contains the rabbitmq_erlang_cookie' do
            is_expected.to contain_rabbitmq_erlang_cookie("#{rabbitmq_home}/.erlang.cookie")
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
            is_expected.to contain_rabbitmq_erlang_cookie("#{rabbitmq_home}/.erlang.cookie")
          end
        end

        describe 'without erlang_cookie and without config_cluster' do
          let(:params) do
            {
              config_cluster: false
            }
          end

          it 'does not contains the rabbitmq_erlang_cookie' do
            is_expected.not_to contain_rabbitmq_erlang_cookie("#{rabbitmq_home}/.erlang.cookie")
          end
        end

        describe 'and sets appropriate configuration' do
          let(:params) do
            {
              config_cluster: true,
              cluster_nodes: %w[hare-1 hare-2],
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
            if %w[FreeBSD OpenBSD].include?(os_facts[:os]['family'])
              is_expected.to contain_file('rabbitmq-env.config'). \
                with_content(%r{ERL_INETRC=/usr/local/etc/rabbitmq/inetrc})
            else
              is_expected.to contain_file('rabbitmq-env.config'). \
                with_content(%r{ERL_INETRC=/etc/rabbitmq/inetrc})
            end
          end
        end

        context 'with environment_variables set' do
          let(:params) do
            { environment_variables: {
              'NODE_IP_ADDRESS' => '1.1.1.1',
              'NODE_PORT' => '5656',
              'NODENAME' => 'HOSTNAME',
              'SERVICENAME' => 'RabbitMQ',
              'CONSOLE_LOG' => 'RabbitMQ.debug',
              'CTL_ERL_ARGS' => 'verbose',
              'SERVER_ERL_ARGS' => 'v',
              'SERVER_START_ARGS' => 'debug'
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
              'ensure' => 'absent',
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

      describe 'configuring ldap authentication' do
        let :params do
          { config_stomp: false,
            ldap_auth: true,
            ldap_server: 'ldap.example.com',
            ldap_other_bind: 'as_user',
            ldap_use_ssl: false,
            ldap_port: 389,
            ldap_log: true,
            ldap_config_variables: { 'foo' => 'bar' } }
        end

        it { is_expected.to contain_rabbitmq_plugin('rabbitmq_auth_backend_ldap') }

        it 'does not set user_dn_pattern when none is specified' do
          verify_contents(catalogue, 'rabbitmq.config',
                          ['[', '  {rabbit, [', '    {auth_backends, [rabbit_auth_backend_internal, rabbit_auth_backend_ldap]},', '  ]}',
                           '  {rabbitmq_auth_backend_ldap, [', '    {other_bind, as_user},',
                           '    {servers, ["ldap.example.com"]},',
                           '    {use_ssl, false},',
                           '    {port, 389},', '    {foo, bar},', '    {log, true}'])
          content = catalogue.resource('file', 'rabbitmq.config').send(:parameters)[:content]
          expect(content).not_to include 'user_dn_pattern'
        end
      end

      describe 'configuring ldap authentication' do
        let :params do
          { config_stomp: false,
            ldap_auth: true,
            ldap_server: ['ldap1.example.com', 'ldap2.example.com'],
            ldap_other_bind: 'as_user',
            ldap_use_ssl: false,
            ldap_port: 389,
            ldap_log: true,
            ldap_config_variables: { 'foo' => 'bar' } }
        end

        it { is_expected.to contain_rabbitmq_plugin('rabbitmq_auth_backend_ldap') }

        it 'does not set user_dn_pattern when none is specified' do
          verify_contents(catalogue, 'rabbitmq.config',
                          ['[', '  {rabbit, [', '    {auth_backends, [rabbit_auth_backend_internal, rabbit_auth_backend_ldap]},', '  ]}',
                           '  {rabbitmq_auth_backend_ldap, [', '    {other_bind, as_user},',
                           '    {servers, ["ldap1.example.com", "ldap2.example.com"]},',
                           '    {use_ssl, false},',
                           '    {port, 389},', '    {foo, bar},', '    {log, true}'])
          content = catalogue.resource('file', 'rabbitmq.config').send(:parameters)[:content]
          expect(content).not_to include 'user_dn_pattern'
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

      context 'use config file for plugins' do
        describe 'config_plugins_file: true and default list of enabled plugins' do
          let :params do
            { use_config_file_for_plugins: true }
          end

          it 'does not use rabbitmqplugin provider' do
            is_expected.not_to contain_rabbitmq_plugin('rabbitmq_management')
            is_expected.not_to contain_rabbitmq_plugin('rabbitmq_shovel_management')
            is_expected.not_to contain_rabbitmq_plugin('rabbitmq_stomp')
            is_expected.not_to contain_rabbitmq_plugin('rabbitmq_auth_backend_ldap')
            is_expected.not_to contain_rabbitmq_plugin('rabbitmq_shovel')
          end

          it 'configures enabled_plugins' do
            is_expected.to contain_file('enabled_plugins').with_content(%r{\[rabbitmq_management\]\.})
          end
        end

        describe 'config_plugins_file: true and custom list of enabled plugins' do
          let :params do
            {
              use_config_file_for_plugins: true,
              admin_enable: false,
              plugins: %w[rabbitmq_stomp rabbitmq_shovel rabbitmq_prometheus]
            }
          end

          it 'does not use rabbitmqplugin provider' do
            is_expected.not_to contain_rabbitmq_plugin('rabbitmq_stomp')
            is_expected.not_to contain_rabbitmq_plugin('rabbitmq_shovel')
            is_expected.not_to contain_rabbitmq_plugin('rabbitmq_prometheus')
          end

          it 'configures enabled_plugins' do
            is_expected.to contain_file('enabled_plugins').with_content(%r{\[rabbitmq_stomp,rabbitmq_shovel,rabbitmq_prometheus\]\.})
          end
        end

        describe 'with all plugins enabled admin_enable: false, manamgent_enable: true' do
          let :params do
            {
              use_config_file_for_plugins: true,
              admin_enable: false,
              management_enable: true,
              stomp_ensure: true,
              ldap_auth: true,
              config_shovel: true
            }
          end

          it 'does not use rabbitmqplugin provider' do
            is_expected.not_to contain_rabbitmq_plugin('rabbitmq_management')
            is_expected.not_to contain_rabbitmq_plugin('rabbitmq_shovel_management')
            is_expected.not_to contain_rabbitmq_plugin('rabbitmq_stomp')
            is_expected.not_to contain_rabbitmq_plugin('rabbitmq_auth_backend_ldap')
            is_expected.not_to contain_rabbitmq_plugin('rabbitmq_shovel')
          end

          it 'configures enabled_plugins' do
            is_expected.to contain_file('enabled_plugins').with_content(%r{rabbitmq_management})
            is_expected.to contain_file('enabled_plugins').with_content(%r{rabbitmq_stomp})
            is_expected.to contain_file('enabled_plugins').with_content(%r{rabbitmq_auth_backend_ldap})
            is_expected.to contain_file('enabled_plugins').with_content(%r{rabbitmq_shovel})
            is_expected.to contain_file('enabled_plugins').with_content(%r{rabbitmq_shovel_management})
            is_expected.to contain_file('enabled_plugins').with_content(%r{\[rabbitmq_management,rabbitmq_stomp,rabbitmq_auth_backend_ldap,rabbitmq_shovel,rabbitmq_shovel_management\]\.})
          end
        end
      end

      describe 'configure management plugin' do
        let :params do
          {
            admin_enable: true,
            management_enable: false
          }
        end

        it { is_expected.to contain_rabbitmq_plugin('rabbitmq_management') }

        it 'sets rabbitmq_managment opts to specified values' do
          is_expected.to contain_file('rabbitmq.config').with_content(%r{rabbitmq_management, \[})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{listener, \[})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{port, 15672\}})
        end

        describe 'with admin_enable false' do
          let :params do
            {
              admin_enable: false,
              management_enable: false
            }
          end

          it { is_expected.not_to contain_rabbitmq_plugin('rabbitmq_management') }
        end

        describe 'with admin_enable false and management_enable true' do
          let :params do
            {
              admin_enable: false,
              management_enable: true
            }
          end

          it { is_expected.to contain_rabbitmq_plugin('rabbitmq_management') }

          it 'sets rabbitmq_managment opts to specified values' do
            is_expected.to contain_file('rabbitmq.config').with_content(%r{rabbitmq_management, \[})
            is_expected.to contain_file('rabbitmq.config').with_content(%r{listener, \[})
            is_expected.to contain_file('rabbitmq.config').with_content(%r{port, 15672\}})
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
            ssl_secure_renegotiate: true,
            ssl_reuse_sessions: true,
            ssl_honor_cipher_order: true,
            ssl_dhfile: :undef,
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
          is_expected.to contain_file('rabbitmq.config').with_content(
            %r{secure_renegotiate,true}
          )
          is_expected.to contain_file('rabbitmq.config').with_content(
            %r{reuse_sessions,true}
          )
          is_expected.to contain_file('rabbitmq.config').with_content(
            %r{honor_cipher_order,true}
          )
          is_expected.to contain_file('rabbitmq.config').without_content(
            %r{dhfile,}
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
            ssl_secure_renegotiate: true,
            ssl_reuse_sessions: true,
            ssl_honor_cipher_order: true,
            ssl_dhfile: :undef,

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
          is_expected.to contain_file('rabbitmq.config').with_content(
            %r{secure_renegotiate,true}
          )
          is_expected.to contain_file('rabbitmq.config').with_content(
            %r{reuse_sessions,true}
          )
          is_expected.to contain_file('rabbitmq.config').with_content(
            %r{honor_cipher_order,true}
          )
          is_expected.to contain_file('rabbitmq.config').without_content(
            %r{dhfile,}
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
            ssl_key: '/path/to/key',
            ssl_secure_renegotiate: true,
            ssl_reuse_sessions: true,
            ssl_honor_cipher_order: true,
            ssl_dhfile: :undef }
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
          is_expected.to contain_file('rabbitmq.config').with_content(
            %r{secure_renegotiate,true}
          )
          is_expected.to contain_file('rabbitmq.config').with_content(
            %r{reuse_sessions,true}
          )
          is_expected.to contain_file('rabbitmq.config').with_content(
            %r{honor_cipher_order,true}
          )
          is_expected.to contain_file('rabbitmq.config').without_content(
            %r{dhfile,}
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

      describe 'ssl options with ssl ciphers (in Erlang [pre-3.7.9] format)' do
        let(:params) do
          { ssl: true,
            ssl_port: 3141,
            ssl_cacert: '/path/to/cacert',
            ssl_cert: '/path/to/cert',
            ssl_key: '/path/to/key',
            ssl_ciphers: ['ecdhe_rsa,aes_256_cbc,sha', 'dhe_rsa,aes_256_cbc,sha'] }
        end

        it 'sets ssl ciphers to specified values' do
          is_expected.to contain_file('rabbitmq.config').with_content(%r{ciphers,\[[[:space:]]+{ecdhe_rsa,aes_256_cbc,sha},[[:space:]]+{dhe_rsa,aes_256_cbc,sha}[[:space:]]+\]})
        end
      end

      describe 'ssl options with ssl ciphers (in OpenSSL style)' do
        let(:params) do
          { ssl: true,
            ssl_port: 3141,
            ssl_cacert: '/path/to/cacert',
            ssl_cert: '/path/to/cert',
            ssl_key: '/path/to/key',
            ssl_ciphers: %w[ECDHE-RSA-AES256-SHA DHE-RSA-AES256-SHA] }
        end

        it 'sets ssl ciphers to specified values' do
          is_expected.to contain_file('rabbitmq.config').with_content(%r{ciphers,\[[[:space:]]+"ECDHE-RSA-AES256-SHA",[[:space:]]+"DHE-RSA-AES256-SHA"[[:space:]]+\]})
        end
      end

      describe 'ssl options with ssl_crl_check enabled' do
        let(:params) do
          { ssl: true,
            ssl_port: 3141,
            ssl_cacert: '/path/to/cacert',
            ssl_cert: '/path/to/cert',
            ssl_key: '/path/to/key',
            ssl_crl_check: 'true' }
        end

        it 'sets ssl crl check setting to specified value' do
          is_expected.to contain_file('rabbitmq.config').with_content(%r{crl_check,true})
        end
      end

      describe 'ssl options with ssl_crl_check and ssl_crl_hash_cache enabled' do
        let(:params) do
          { ssl: true,
            ssl_port: 3141,
            ssl_cacert: '/path/to/cacert',
            ssl_cert: '/path/to/cert',
            ssl_key: '/path/to/key',
            ssl_crl_check: 'true',
            ssl_crl_cache_hash_dir: '/path/to/crl_cache/dir' }
        end

        it 'sets ssl crl check setting to specified value' do
          is_expected.to contain_file('rabbitmq.config').with_content(%r{crl_check,true})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{crl_cache,\s+{ssl_crl_hash_dir,\s+{internal,\s+\[{dir, "/path/to/crl_cache/dir"}\]}}})
        end
      end

      describe 'ssl options with ssl_crl_check and http cache enabled' do
        let(:params) do
          { ssl: true,
            ssl_port: 3141,
            ssl_cacert: '/path/to/cacert',
            ssl_cert: '/path/to/cert',
            ssl_key: '/path/to/key',
            ssl_crl_check: 'true',
            ssl_crl_cache_http_timeout: 5000 }
        end

        it 'sets ssl crl check setting to specified value' do
          is_expected.to contain_file('rabbitmq.config').with_content(%r{crl_check,true})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{crl_cache,\s+{ssl_crl_cache,\s+{internal,\s+\[{http, 5000}\]}}})
        end
      end

      describe 'ssl options with ssl_crl_check enabled and not ssl' do
        let(:params) do
          { ssl: false,
            ssl_port: 3141,
            ssl_cacert: '/path/to/cacert',
            ssl_cert: '/path/to/cert',
            ssl_key: '/path/to/key',
            ssl_crl_check: 'true' }
        end

        it 'fails' do
          expect { catalogue }.to raise_error(Puppet::Error, %r{\$ssl_crl_check requires that \$ssl => true})
        end
      end

      describe 'ssl options with ssl_crl_cache_hash_dir set and not ssl_crl_check' do
        let(:params) do
          { ssl: true,
            ssl_port: 3141,
            ssl_cacert: '/path/to/cacert',
            ssl_cert: '/path/to/cert',
            ssl_key: '/path/to/key',
            ssl_crl_check: 'false',
            ssl_crl_cache_hash_dir: '/path/to/crl_cache/dir' }
        end

        it 'fails' do
          expect { catalogue }.to raise_error(Puppet::Error, %r{\$ssl_crl_cache_hash_dir requires that \$ssl_crl_check => true|peer|best_effort})
        end
      end

      describe 'ssl options with ssl_crl_cache_http_timeout set and not ssl_crl_check' do
        let(:params) do
          { ssl: true,
            ssl_port: 3141,
            ssl_cacert: '/path/to/cacert',
            ssl_cert: '/path/to/cert',
            ssl_key: '/path/to/key',
            ssl_crl_check: 'false',
            ssl_crl_cache_http_timeout: 5000 }
        end

        it 'fails' do
          expect { catalogue }.to raise_error(Puppet::Error, %r{\$ssl_crl_cache_http_timeout requires that \$ssl_crl_check => true|peer|best_effort})
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

      describe 'ssl with ssl_dhfile' do
        let(:params) do
          { ssl: true,
            ssl_interface: '0.0.0.0',
            ssl_dhfile: '/etc/pki/tls/dh-params.pem' }
        end

        it { is_expected.to contain_file('rabbitmq.config').with_content(%r{dhfile, "/etc/pki/tls/dh-params\.pem}) }
      end

      describe 'ssl with ssl_dhfile unset' do
        let(:params) do
          { ssl: true,
            ssl_interface: '0.0.0.0',
            ssl_dhfile: :undef }
        end

        it { is_expected.to contain_file('rabbitmq.config').without_content(%r{dhfile,}) }
      end

      describe 'ssl with ssl_secure_renegotiate false' do
        let(:params) do
          { ssl: true,
            ssl_interface: '0.0.0.0',
            ssl_secure_renegotiate: false }
        end

        it { is_expected.to contain_file('rabbitmq.config').with_content(%r{secure_renegotiate,false}) }
      end

      describe 'ssl with ssl_reuse_sessions false' do
        let(:params) do
          { ssl: true,
            ssl_interface: '0.0.0.0',
            ssl_reuse_sessions: false }
        end

        it { is_expected.to contain_file('rabbitmq.config').with_content(%r{reuse_sessions,false}) }
      end

      describe 'ssl with ssl_honor_cipher_order false' do
        let(:params) do
          { ssl: true,
            ssl_interface: '0.0.0.0',
            ssl_honor_cipher_order: false }
        end

        it { is_expected.to contain_file('rabbitmq.config').with_content(%r{honor_cipher_order,false}) }
      end

      describe 'ssl admin options' do
        let(:params) do
          { ssl: true,
            ssl_management_port: 3141,
            ssl_cacert: '/path/to/cacert',
            ssl_cert: '/path/to/cert',
            ssl_key: '/path/to/key',
            ssl_management_verify: 'verify_peer',
            ssl_management_fail_if_no_peer_cert: true,
            admin_enable: true }
        end

        it 'sets rabbitmq_management ssl options to specified values' do
          is_expected.to contain_file('rabbitmq.config').with_content(%r{rabbitmq_management, \[})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{listener, \[})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{port, 3141\}})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{ssl, true\}})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{ssl_opts, \[})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{verify,verify_peer\},})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{fail_if_no_peer_cert,true\}})
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

      describe 'ssl admin options with dedicated admin-key and -certs' do
        let(:params) do
          { ssl: true,
            ssl_management_port: 3141,
            ssl_management_cacert: '/path/to/management_cacert',
            ssl_management_cert: '/path/to/management_cert',
            ssl_management_key: '/path/to/management_key',
            admin_enable: true }
        end

        it 'sets rabbitmq_management ssl options to specified values' do
          is_expected.to contain_file('rabbitmq.config').with_content(%r{rabbitmq_management, \[})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{listener, \[})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{port, 3141\},})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{ssl, true\},})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{ssl_opts, \[})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{cacertfile, "/path/to/management_cacert"\},})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{certfile, "/path/to/management_cert"\},})
          is_expected.to contain_file('rabbitmq.config').with_content(%r{keyfile, "/path/to/management_key"\}})
        end

        it 'sets ssl options in the rabbitmqadmin.conf' do
          is_expected.to contain_file('rabbitmqadmin.conf').with_content(
            %r{ssl_ca_cert_file\s=\s/path/to/management_cacert}
          )
          is_expected.to contain_file('rabbitmqadmin.conf').with_content(
            %r{ssl_cert_file\s=\s/path/to/management_cert}
          )
          is_expected.to contain_file('rabbitmqadmin.conf').with_content(
            %r{ssl_key_file\s=\s/path/to/management_key}
          )
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
              with_content(%r{^RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS="-proto_dist inet6_tcp"$}). \
              with_content(%r{^RABBITMQ_CTL_ERL_ARGS="-proto_dist inet6_tcp"$})
          end
        end

        context 'with other quoted erl args' do
          let(:params) do
            { ipv6: true,
              environment_variables: { 'RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS' => '"some quoted args"',
                                       'RABBITMQ_CTL_ERL_ARGS' => '"other quoted args"' } }
          end

          it 'enables inet6 distribution and quote properly' do
            is_expected.to contain_file('rabbitmq-env.config'). \
              with_content(%r{^RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS="some quoted args -proto_dist inet6_tcp"$}). \
              with_content(%r{^RABBITMQ_CTL_ERL_ARGS="other quoted args -proto_dist inet6_tcp"$})
          end
        end

        context 'with other unquoted erl args' do
          let(:params) do
            { ipv6: true,
              environment_variables: { 'RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS' => 'foo',
                                       'RABBITMQ_CTL_ERL_ARGS' => 'bar' } }
          end

          it 'enables inet6 distribution and quote properly' do
            is_expected.to contain_file('rabbitmq-env.config'). \
              with_content(%r{^RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS="foo -proto_dist inet6_tcp"$}). \
              with_content(%r{^RABBITMQ_CTL_ERL_ARGS="bar -proto_dist inet6_tcp"$})
          end
        end

        context 'with SSL and without other erl args' do
          let(:params) do
            { ipv6: true,
              ssl_erl_dist: true }
          end

          it 'enables inet6 distribution' do
            is_expected.to contain_file('rabbitmq-env.config'). \
              with_content(%r{^RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS=" -pa /usr/lib64/erlang/lib/ssl-7.3.3.1/ebin -proto_dist inet6_tls"$}). \
              with_content(%r{^RABBITMQ_CTL_ERL_ARGS=" -pa /usr/lib64/erlang/lib/ssl-7.3.3.1/ebin -proto_dist inet6_tls"$})
          end
        end

        context 'with SSL and other quoted erl args' do
          let(:params) do
            { ipv6: true,
              ssl_erl_dist: true,
              environment_variables: { 'RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS' => '"some quoted args"',
                                       'RABBITMQ_CTL_ERL_ARGS' => '"other quoted args"' } }
          end

          it 'enables inet6 distribution and quote properly' do
            is_expected.to contain_file('rabbitmq-env.config'). \
              with_content(%r{^RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS="some quoted args -pa /usr/lib64/erlang/lib/ssl-7.3.3.1/ebin  -proto_dist inet6_tls"$}). \
              with_content(%r{^RABBITMQ_CTL_ERL_ARGS="other quoted args -pa /usr/lib64/erlang/lib/ssl-7.3.3.1/ebin  -proto_dist inet6_tls"$})
          end
        end

        context 'with SSL and with other unquoted erl args' do
          let(:params) do
            { ipv6: true,
              ssl_erl_dist: true,
              environment_variables: { 'RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS' => 'foo',
                                       'RABBITMQ_CTL_ERL_ARGS' => 'bar' } }
          end

          it 'enables inet6 distribution and quote properly' do
            is_expected.to contain_file('rabbitmq-env.config'). \
              with_content(%r{^RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS="foo -pa /usr/lib64/erlang/lib/ssl-7.3.3.1/ebin  -proto_dist inet6_tls"$}). \
              with_content(%r{^RABBITMQ_CTL_ERL_ARGS="bar -pa /usr/lib64/erlang/lib/ssl-7.3.3.1/ebin  -proto_dist inet6_tls"$})
          end
        end
      end

      describe 'config_variables options' do
        let(:params) do
          { config_variables: {
            'hipe_compile' => true,
            'vm_memory_high_watermark' => 0.4,
            'frame_max' => 131_072,
            'collect_statistics' => 'none',
            'auth_mechanisms' => "['PLAIN', 'AMQPLAIN']"
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
              'ensure' => 'absent',
              'provider' => 'rabbitmqctl'
            )
          end
        end
      end

      describe 'rabbitmq-loopback_users by default' do
        it 'sets the loopback_users parameter in the config file' do
          is_expected.to contain_file('rabbitmq.config'). \
            with_content(%r{\{loopback_users, \[<<"guest">>\]\}})
        end
      end

      describe 'rabbitmq-loopback_users allow connections via loopback interfaces' do
        let(:params) { { loopback_users: [] } }

        it 'sets the loopback_users parameter in the config file' do
          is_expected.to contain_file('rabbitmq.config'). \
            with_content(%r{\{loopback_users, \[\]\}})
        end
      end

      describe 'rabbitmq-loopback_users allow connections via loopback interfaces to a group of users' do
        let(:params) { { loopback_users: %w[user1 user2] } }

        it 'sets the loopback_users parameter in the config file' do
          is_expected.to contain_file('rabbitmq.config'). \
            with_content(%r{\{loopback_users, \[<<"user1">>, <<"user2">>\]\}})
        end
      end

      ##
      ## rabbitmq::service
      ##
      describe 'service with default params' do
        it {
          is_expected.to contain_service('rabbitmq-server').with(
            'ensure' => 'running',
            'enable' => 'true',
            'hasstatus' => 'true',
            'hasrestart' => 'true',
            'name' => name
          )
        }
      end

      context 'on systems with systemd', if: os_facts[:systemd] do
        it do
          is_expected.to contain_service('rabbitmq-server').
            that_requires('Class[systemd::systemctl::daemon_reload]')
        end
      end

      describe 'service with ensure stopped' do
        let :params do
          { service_ensure: 'stopped' }
        end

        it {
          is_expected.to contain_service('rabbitmq-server').with(
            'ensure' => 'stopped',
            'enable' => false
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
end

# rubocop:enable RSpec/RepeatedExampleGroupDescription
# rubocop:enable RSpec/RepeatedExampleGroupBody
