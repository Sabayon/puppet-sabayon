# == Class: Sabayon
#
# Installs the tools needed to manage Sabayon hosts using puppet
#
class sabayon {

    # Enman is used to manage SCR repositories
    package {
        'enman':
            ensure   => installed,
            catgeory => 'app-admin',
            name     => 'enman';
    }

}
