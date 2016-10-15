# ssl.rb
Facter.add('ssldir') do
  setcode do
      ssldir = Facter::Core::Execution.exec('/opt/puppetlabs/bin/puppet config print ssldir').rstrip
      ssldir
  end
end
