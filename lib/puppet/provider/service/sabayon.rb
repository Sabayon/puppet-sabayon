# Manage systemd services using /bin/systemctl

Puppet::Type.type(:service).provide :sabayon, parent: :systemd do
  desc 'Manages `systemd` services using `systemctl`.'

  defaultfor operatingsystem: :sabayon
end
