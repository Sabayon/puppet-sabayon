Facter.add(:operatingsystem) do
   # Sabayon Linux is a variant of Gentoo so this resolution needs to come
   # before the Gentoo resolution.
   has_weight(100)
   confine kernel: :linux, lsbdistid: :sabayon

   setcode do
     'Sabayon'
   end
 end

