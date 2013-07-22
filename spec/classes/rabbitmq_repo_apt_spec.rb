require 'spec_helper'

describe 'rabbitmq' do
  let(:facts)  {{ :osfamily => 'Debian' }}

  context 'with no pin' do
    let(:params) {{ :package_apt_pin => '' }}
    describe 'it sets up an apt::source' do

      it { should contain_apt__source('rabbitmq').with(
        'location'    => 'http://www.rabbitmq.com/debian/',
        'release'     => 'testing',
        'repos'       => 'main',
        'include_src' => false,
        'key'         => '056E8E56'
      ) }
    end
  end

  context 'with pin' do
    let(:params) {{ :package_apt_pin => '700' }}
    describe 'it sets up an apt::source and pin' do

      it { should contain_apt__source('rabbitmq').with(
        'location'    => 'http://www.rabbitmq.com/debian/',
        'release'     => 'testing',
        'repos'       => 'main',
        'include_src' => false,
        'key'         => '056E8E56'
      ) }

     it { should contain_apt__pin('rabbitmq').with(
       'packages' => 'rabbitmq-server',
       'priority' => '700'
     ) }

    end
  end

end
