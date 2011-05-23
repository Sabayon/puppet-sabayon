require 'facter/lsb'

Facter.add(:operatingsystem) do
    confine :kernel => :linux
    confine :has_entropy => true

    setcode do
      if FileTest.exists?("/etc/sabayon-release")
        "Sabayon"
      end
   end
end

