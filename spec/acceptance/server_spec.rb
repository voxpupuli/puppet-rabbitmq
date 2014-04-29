require 'spec_helper_acceptance'

describe 'rabbitmq server:' do
  it 'should run successfully' do
    pp = <<-EOS
    class { 'rabbitmq::server': }
    class { 'erlang': epel_enable => true}
    Class['erlang'] -> Class['rabbitmq::server']
    EOS

    # Apply twice to ensure no errors the second time.
    apply_manifest(pp, :catch_failures => true)
    apply_manifest(pp, :catch_changes => true)
  end
end

