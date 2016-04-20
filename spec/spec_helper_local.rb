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

def with_openbsd_facts
  # operatingsystemmajrelease is too broad
  # operatingsystemrelease may contain X.X-current
  # or other prefixes
  let :facts do
    {
      :osfamily                  => 'OpenBSD',
      :kernelversion             => '5.9',
      :staging_http_get          => ''
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
