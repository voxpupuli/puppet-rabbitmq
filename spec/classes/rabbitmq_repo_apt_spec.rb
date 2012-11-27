require 'spec_helper'

describe 'rabbitmq::repo::apt' do
  describe 'repo without params' do
    it { should contain_apt__source('rabbitmq').with(
      'ensure'   => 'present',
      'location' => 'http://www.rabbitmq.com/debian/',
      'release'  => 'testing',
      'repos'    => 'main',
      'pin'      => false,
    ) }

    it { should_not contain_apt__pin('rabbitmq') }
  end

  describe 'repo with pinning' do
    let :params do
      {
        :pin => '100',
      }
    end

    it { should contain_apt__source('rabbitmq').with(
      'location'   => 'http://www.rabbitmq.com/debian/',
      'ensure'     => 'present',
      'release'    => 'testing',
      'repos'      => 'main',
      'key_source' => 'http://www.rabbitmq.com/rabbitmq-signing-key-public.asc',
      'pin'        => params[:pin],
    ) }


    it { should contain_apt__pin('rabbitmq').with(
        'priority' => params[:pin],
    ) }
  end
end

