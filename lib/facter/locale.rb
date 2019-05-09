Facter.add(:locale) do
  confine osfamily: :gentoo
  setcode do
    Facter::Core::Execution.exec('eselect --colour=no --brief locale show').strip
  end
end
