Facter.add(:has_entropy) do
    confine :kernel => :linux
    setcode do
        FileTest.exists?("/usr/bin/equo")
    end
end

