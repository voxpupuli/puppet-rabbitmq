require 'spec_helper'

describe 'rabbitmq' do
  let(:facts) {{ :osfamily => 'RedHat' }}
  describe 'imports the key' do
    let(:params) {{ :package_gpg_key => 'http://www.rabbitmq.com/rabbitmq-signing-key-public.asc' }}

    it { should contain_exec("rpm --import #{params[:package_gpg_key]}").with(
      'path' => ['/bin','/usr/bin','/sbin','/usr/sbin']
    ) }
  end
end
