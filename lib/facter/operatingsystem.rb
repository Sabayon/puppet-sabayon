Facter.add(:operatingsystem) do
   # Sabayon Linux is a variant of Gentoo so this resolution needs to come
   # before the Gentoo resolution.
   has_weight(100)
   confine :kernel => :linux

   setcode do
     distid = Facter.value(:lsbdistid)
     if distid == "Sabayon"
       'Sabayon'
     end
   end
 end

