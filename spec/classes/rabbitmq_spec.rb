require 'spec_helper'

describe 'rabbitmq' do

  context 'on unsupported distributions' do
    let(:facts) {{ :osfamily => 'Unsupported' }}

    it 'we fail' do
      expect { subject }.to raise_error(/not supported on an Unsupported/)
    end
  end

  context 'on supported distributions' do
    let(:facts) {{ :osfamily => 'Debian', :lsbdistcodename => 'squeeze' }}

    it { should contain_class('rabbitmq::install') }
    it { should contain_class('rabbitmq::config') }
    it { should contain_class('rabbitmq::service') }

    context 'on Debian' do
      let(:facts) {{ :osfamily => 'Debian', :lsbdistcodename => 'squeeze' }}
      it 'includes rabbitmq::repo::apt' do
        should contain_class('rabbitmq::repo::apt')
      end
    end

    context 'on Redhat' do
      let(:facts) {{ :osfamily => 'RedHat' }}
      it 'includes rabbitmq::repo::rhel' do
        should contain_class('rabbitmq::repo::rhel')
      end
    end

    context 'with admin_enable set to true' do
      let(:params) {{ :admin_enable => true }}
      it 'we enable the admin interface by default' do
        should contain_class('rabbitmq::install::rabbitmqadmin')
        should contain_rabbitmq_plugin('rabbitmq_management').with(
          'require' => 'Class[Rabbitmq::Install]',
          'notify'  => 'Class[Rabbitmq::Service]'
        )
      end
    end

    context 'with admin_enable set to false' do
      let(:params) {{ :admin_enable => false }}
      it 'doesnt enable the admin interface' do
        should_not contain_class('rabbitmq::install::rabbitmqadmin')
        should_not contain_rabbitmq_plugin('rabbitmq_management')
      end
    end

    context 'with erlang_manage set to true' do
      let(:params) {{ :erlang_manage => true }}
      it 'includes erlang' do
        should contain_class('erlang')
      end
    end

    context 'with erlang_manage set to false' do
      let(:params) {{ :erlang_manage => false }}
      it 'doesnt include erlang' do
        should_not contain_class('erlang')
      end
    end

  end
end
