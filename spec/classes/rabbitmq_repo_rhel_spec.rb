require 'spec_helper'

describe 'rabbitmq::repo::rhel' do
  describe 'imports the key' do
    let(:params) {{ :key => 'http://www.rabbitmq.com/rabbitmq-signing-key-public.asc' }}

    it { should contain_exec("rpm --import #{params[:key]}").with(
      'path' => ['/bin','/usr/bin','/sbin','/usr/sbin']
    ) }
  end
end
