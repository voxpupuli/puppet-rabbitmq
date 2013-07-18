# Fact: rabbitmq_erlang_cookie
#
# Purpose: To determine the current erlang cookie value.
#
# Resolution: Returns the cookie.
Facter.add(:rabbitmq_erlang_cookie) do
  confine :osfamily => %w[Debian RedHat Suse]

  case Facter.value(:osfamily)
  when 'Debian', 'RedHat', 'Suse'
    cookie = File.read('/var/lib/rabbitmq/.erlang.cookie')
  end
  cookie
end
