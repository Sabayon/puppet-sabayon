require 'facter/util/operatingsystem'

Facter.add(:operatingsystem) do
  # Sabayon Linux is a variant of Gentoo so this resolution needs to come
  # before the Gentoo resolution.
  has_weight(10)
  confine :kernel => :linux

  setcode do
    release_info = Facter::Util::Operatingsystem.os_release
    if release_info['NAME'] == "Sabayon"
      'Sabayon'
    end
  end
end
