require 'spec_helper'

describe 'rabbitmq' do
  let(:facts) {{ :osfamily => 'RedHat' }}

  context 'delete_guest_user' do
    describe 'should do nothing by default' do
      it { should_not contain_rabbitmq_user('guest') }
    end

    describe 'delete user when delete_guest_user set' do
      let(:params) {{ :delete_guest_user => true }}
      it 'removes the user' do
        should contain_rabbitmq_user('guest').with(
          'ensure'   => 'absent',
          'provider' => 'rabbitmqctl'
        )
      end
    end
  end

end
