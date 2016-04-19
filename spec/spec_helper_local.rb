def with_debian_facts
  let :facts do
    {
      :lsbdistid        => 'Debian',
      :lsbdistcodename  => 'squeeze',
      :osfamily         => 'Debian',
      :staging_http_get => ''
    }
  end
end

def with_redhat_facts
  let :facts do
    {
      :osfamily                  => 'Redhat',
      :operatingsystemmajrelease => '7',
      :staging_http_get          => ''
    }
  end
end
