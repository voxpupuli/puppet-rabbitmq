require 'spec_helper'

describe 'rabbitmq::repo::rhel' do
  describe 'package with params' do
    let :params do
      {
        :key        => "http://www.rabbitmq.com/rabbitmq-signing-key-public.asc",
        :version    => "2.8.4",
        :relversion => "1", 
      }
    end
    it { should contain_exec("rpm --import #{params[:key]}").with(
      'path' => ["/bin","/usr/bin","/sbin","/usr/sbin"],
    ) }
    it { should contain_package('rabbitmq-server').with(
      'provider' => 'rpm',
      'ensure' => 'installed',
      'source' => "http://www.rabbitmq.com/releases/rabbitmq-server/v#{params[:version]}/rabbitmq-server-#{params[:version]}-#{params[:relversion]}.noarch.rpm",
      'require' => "Exec[rpm --import #{params[:key]}]",
    ) }
  end
end

