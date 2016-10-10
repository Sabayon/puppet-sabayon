# == Class: Sabayon
#
# Installs the tools needed to manage Sabayon hosts using puppet
#
class sabayon {

    # Enman is used to manage SCR repositories
    package {
        'app-admin/enman':
            ensure   => installed,
            category => 'app-admin',
            name     => 'enman';
    }

}
