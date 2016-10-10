# Sabayon

#### Table of Contents

1. [Description](#description)
1. [Setup - The basics of getting started with sabayon](#setup)
    * [What the sabayon module affects](#what-the-sabayon-module-affects)
    * [Beginning with sabayon](#beginning-with-sabayon)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
1. [Limitations - OS compatibility, etc.](#limitations)
1. [Development - Guide for contributing to the module](#development)

## Description

This module extends puppet with support for the Sabayon Linux disttribution.

It adds support for:
* The Entropy package manager
* Managing `Sabayon Community Repository (SCR)` definitions using `enman`
* Entropy package masks and unmasks
* Using systemd as the default service provider

## Setup

### What the sabayon module affects

* `operatingsystem` fact:
   This module overrides the operatingsystem fact to `Sabayon` on Sabayon
   systems.
* `Service` provider:
   This module overrides the default provider for `service` resources to
   force use of `systemd`
* `Package` provider:
   This module overrides the default provider for `package` resources to
   force use of `entropy`

### Beginning with sabayon

The types and providers within this module can be used without any special
setup, as long as the required packages are already installed. To let this
module take care of installing the required packages, simply include the
`sabayon` class.

```puppet
class { 'sabayon': }
```

## Usage

### Installing packages using entropy

This module sets the `entropy` provider to be the default for Sabayon,
so no special configuration is required.

The provider supports package names in both the fully-qualified format, e.g.

```puppet
package { 'net-misc/openssh':
  ensure => installed,
}
```

Or the more verbose format:

```puppet
package { 'ssh-server':
  ensure   => installed,
  category => 'net-misc',
  name     => 'openssh',
}
```

The category specification is optional as long as the package name is unique.
For example you could install `pip` as that's (currently) unique, but you could
not install 'mysql' since there's no way to disambiguate between
`virtual/mysql` and `dev-db/mysql`.

### Managing enman repositories

```puppet
enman_repo { 'community':
  ensure => present,
}
```

### Masking packages

Entropy is very flexible in how to specify which packages can be masked,
and supports some or all of the following in the atom specification.

All of these parameters are optional, but at least one must be specified

* `package` (either fully qualified or unqualified package name)
* `operator` (`<`, `<=`, `=`, `>=`, `>`. applied to version)
* `version`
* `slot`
* `use`
* `tag`
* `repo`

The `entropy_mask` type also takes the following optional parameters:

* `target` (The path to the mask file, defaults to
  `/etc/entropy/packages/package.mask`)

#### Examples

To mask all packages within the `community` repository by default
and later unmask specific packages, you could use something like:

```puppet
entropy_mask { 'mask-community-by-default':
  repo => 'community',
}
```

Alternatively, you could mask newer versions of a package

```puppet
entropy_mask { 'mask-postgresql-9.5+':
  package  => 'app-shells/bash',
  operator => '>=',
  version  => '9.5',
}
```

Or mask a package with an undesirable set of use flags, e.g.
to ensure any installed version of openssh supports ldap, mask
all versions of openssh which don't include ldap support with:

```puppet
entropy_mask { 'openssh-without-ldap-support':
  package => 'net-misc/openssh',
  use     => '-ldap',
}
```

The `entropy_mask` type directly writes to the mask file, rather than using the
`equo mask` command line. This is so that entries can be removed again when 
using `ensure => absent`, something which `equo` doesn't yet provide support
for. All entries managed by puppet include the ` # Puppet Name: namevar`
trailing comment. Puppet will completely ignore the existence of other entries
in this file, which means you could manually manage other entries in the file
if you wished, although this is not recommended since puppet would not be able
to remove unmanaged entries if you later decide you want them to be managed.

### Unmasking packages

Unmasking packages works identically to masking packages, except using the
`entropy_unmask` resource. All the same parameters are supported.

Unmasks take precedence over masks, so assuming
in the example above you have masked everything in the `community` repository
you could enable installing a particular package from that repository again
using:

```puppet
entropy_unmask { 'sublime':
  package => 'app-editors/sublime-text',
}
```

The same caveats about managing the unmask file apply as with `entropy_mask`
above.

## Reference

### Classes

* `::sabayon` class to install required packages to support included types

### Types

* `enman_repo` Manages SCR repositories using enman
* `entropy_mask` Manages entropy package masks
* `entropy_unmask` Manages entropy package unmasks

## Limitations

This module is actively used by the developer against current Sabayon versions.
Due to the rolling release nature of Sabayon, the module is provided as-is and
cannot be guaranteed to always be in a working state. Updates are provided on a
best-efforts basis.

## Development

Pull requests welcome!

