# Fact: rabbitmq_erlang_cookie
#
# Purpose: To determine the current erlang cookie value.
#
# Resolution: Returns the cookie.
Facter.add(:rabbitmq_erlang_cookie) do
  confine :osfamily => %w[Debian RedHat Suse]
  setcode do
    File.read('/var/lib/rabbitmq/.erlang.cookie')
  end
end
