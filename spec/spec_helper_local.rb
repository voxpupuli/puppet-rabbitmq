RSpec.shared_context 'default facts' do
  let(:facts) do
    { puppetversion: Puppet.version,
      staging_http_get: '',
      rabbitmq_version: '3.6.1' }
  end
end

RSpec.configure do |rspec|
  rspec.include_context 'default facts'
end

def with_debian_facts
  let :facts do
    super().merge(
      operatingsystemmajrelease: '6',
      lsbdistcodename: 'squeeze',
      lsbdistid: 'Debian',
      osfamily: 'Debian',
      os:
      {
        name: 'Debian',
        release: { full: '6.0' }
      }
    )
  end
end

def with_openbsd_facts
  # operatingsystemmajrelease is too broad
  # operatingsystemrelease may contain X.X-current
  # or other prefixes
  let :facts do
    super().merge(
      kernelversion: '5.9',
      osfamily: 'OpenBSD'
    )
  end
end

def with_redhat_facts
  let :facts do
    super().merge(
      operatingsystemmajrelease: '7',
      osfamily: 'Redhat',
      os:
      {
        name: 'CentOS',
        release: { major: '7' }
      }
    )
  end
end

def with_suse_facts
  let :facts do
    super().merge(osfamily: 'SUSE')
  end
end

def with_archlinux_facts
  let :facts do
    super().merge(osfamily: 'Archlinux')
  end
end

def with_distro_facts(distro)
  send("with_#{distro.downcase}_facts")
end
