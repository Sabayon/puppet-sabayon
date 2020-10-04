# Sabayon

[![Travis-CI](https://travis-ci.com/Sabayon/puppet-sabayon.svg?branch=master)](https://travis-ci.com/github/Sabayon/puppet-sabayon)

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

This module extends puppet with support for the Sabayon Linux distribution.

It adds support for:
* The Entropy package manager
* Managing `Sabayon Community Repository (SCR)` definitions using `enman`
* Enabling and disabling entropy repositories
* Entropy package masks and unmasks
* Splitdebug installs for packages
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

### Prerequisites

* `sys-apps/lsb-release` is required for the operatingsystem fact to work

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

Install an available SCR repository using enman. The title is taken to be the
repository name by default, and must be available via enman. Use an `ensure`
value of `present` to install the repo, and `absent` to remove it.

Repositories recorded in [enman-db](https://github.com/Sabayon/enman-db) can be
added by name. Local repositories can be added via URL. When using an URL, the
`name` property must match the name of the repo defined at the URL, to prevent
puppet trying to re-add the repo on every run.

```puppet
enman_repo { 'community':
  ensure => present,
}

enman_repo { 'myrepo':
  ensure => present,
  url    => 'https://example.com/myrepo',
}
```

### Enabling and disabling entropy repositories

Installed repositories (whether system or SCR repositories) can be enabled and
disabled using the `entropy_repo` type. 

To enable a repository, use:
```puppet
entropy_repo { 'sabayon-limbo':
  enabled => 'true',
}
```

To disable a repository (only if present), use:
```puppet
if 'sabayon-limbo' in $facts['entropy_repos'] {
  entropy_repo { 'sabayon-limbo':
    enabled => 'false',
  }
}
```

This type cannot currently install or remove repositories, only control the
enabled state of existing repositories. The repository being managed must
already exist on the system.

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

### Enabling splitdebug for packages

Entropy splits debug information for packages into separate objects which are
installed at the same time as the package only if splitdebug is enabled
globally, or for specific packages listed in the `package.splitdebug` file.

This type behaves similarly to masks/unmasks and manages entries in the
splitdebug file to define packages for which debug information should be
installed. All the same parameters are supported as with `entropy_mask`.

```puppet
entropy_splitdebug { 'kernel':
  package => 'sys-kernel/linux-sabayon',
}
```

The same caveats about managint the splitdebug file apply as with the
`entropy_mask` type above.

### Enabling splitdebug masks for packages

This type inverts the `entropy_splitdebug` behaviour, and prevents splitdebug
from being installed for matching packages even when otherwise enabled by an
`entropy_splitdebug` entry. Masks take precedence, and anything matched by an
`entropy_splitdebug_mask` entry will never have debug information installed.
All the same parameters are supported as with `entropy_mask`.

```puppet
entropy_splitdebug_mask { 'kernel-4.8':
  package => 'sys-kernel/linux-sabayon',
  slot    => '4.8',
}
```

The same caveats about managint the splitdebug file apply as with the
`entropy_mask` type above.

### Managing package keywords

The `entropy_keywords` type allows managing entries in the `package.keywords`
file, which can set missing keywords on packages. A typical example is when
installing a `9999` version package straight from source control which hasn't
been marked as supported on any platform.

Parameters:
* `keyword`: The package keyword to apply. Defaults to the OS architecutre,
  e.g. `amd64` if not specified, but other typical values might be `~amd64`,
  `-*` or `**`.
* `package`: Name of the package, maybe qualified or unqualified.
* `operator`: (`<`, `<=`, `=`, `>=`, `>`, applied to version)
* `version`: Restrict the keyword to a specifc version or range of versions
* `repo`: Restrict the keyword to packages from a specific repo

At least one of `package` or `repo` must be specified.

```puppet
entropy_keywords { 'sublime-live':
  package => 'app-text/sublime-text',
  version => '9999',
  keyword => '**',
}
```

For more info on package keywords, see https://wiki.gentoo.org/wiki/KEYWORDS

## Reference

### Classes

* `::sabayon` class to install required packages to support included types

### Types

* `enman_repo`: Manages SCR repositories using enman
* `entropy_repo`: Enables/Disables repositories
* `entropy_mask`: Manages entropy package masks
* `entropy_unmask`: Manages entropy package unmasks
* `entropy_splitdebug` Manages entropy package debug information
* `entropy_splitdebug_mask` Manages entropy package debug information masks

### Facts

#### `entropy_repos`

Provides a structured fact identifying the entropy repos present on the system
including their enabled/disabled state, and whether they are enman or entropy
repositories.

Example (in yaml format for readability):
```yaml
---
sabayonlinux.org:
  repo_type: "entropy"
  enabled: "true"
sabayon-limbo:
  repo_type: "entropy"
  enabled: "false"
community:
  repo_type: "enman"
  enabled: "true"
```

#### `locale`

Identifies the system-wide default locale, as set by `eselect`.

This is used internally by the entropy package provider to run `equo` commands
using the correct locale.

#### `operatingsystem`

Overrides the detection of the operating system on Sabayon systems to `Sabayon`.

### Tasks

This module includes tasks for ad-hoc use with Puppet Bolt or Choria.

### `cleanup`

This task executes `equo cleanup` command on the target nodes, which frees up
disk space used by cached package downloads. It does not accept any parameters,
and does not support running noop mode.

## Limitations

This module is actively used by the developer against current Sabayon versions.
Due to the rolling release nature of Sabayon, the module is provided as-is and
cannot be guaranteed to always be in a working state. Updates are provided on a
best-efforts basis.

## Development

Pull requests welcome!

## Contributors

* [https://github.com/ace13](ace13)

