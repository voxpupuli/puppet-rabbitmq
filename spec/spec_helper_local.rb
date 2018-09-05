add_custom_fact :rabbitmq_version, '3.6.1'                              # puppet-rabbitmq
add_custom_fact :erl_ssl_path, '/usr/lib64/erlang/lib/ssl-7.3.3.1/ebin' # puppet-rabbitmq

def os_specific_facts(facts)
  case facts[:os]['family']
  when 'Archlinux'
    { service_provider: 'systemd', systemd: true }
  when 'Debian'
    case facts[:os]['release']['major']
    when '7'
      { service_provider: 'sysv', systemd: false }
    when '14.04'
      { service_provider: 'upstart', systemd: false }
    else
      { service_provider: 'systemd', systemd: true }
    end
  when 'RedHat'
    case facts[:os]['release']['major']
    when '6'
      { service_provider: 'sysv', systemd: false }
    else
      { service_provider: 'systemd', systemd: true }
    end
  else
    { service_provider: 'systemd', systemd: true }
  end
end
