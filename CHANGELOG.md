## Next

- Adds support for adding third party enman repo via URL
- Adds `sabayon::enman_repo` task for managing enman repositories via Bolt/Choria

## 2-10-12-08 Release 0.6.1

- Improve parsing of package versions with respect to PMS v7 spec

## 2019-05-10 Release 0.6.0

- Adds `cleanup` task
- Convert module to using PDK


## 2018-10-14 Release 0.5.0

- Update package install error handling for compatbility with
  puppet 6
- Add support for `pre_pre` package versions
- Update build-time gems

## 2017-03-13 Release 0.4.0

- Replace operatingsystem.rb native fact with executable fact to workaround
  [https://tickets.puppetlabs.com/browse/FACT-1528](FACT-1528) (ace13)

## 2016-10-16 Release 0.3.0

- Add `entropy_repo` type to enable/disable repositories
- Add `entropy_repos` fact

## 2016-10-13 Release 0.2.0

- Add `locale` fact
- Remove obsolete `has_entropy` fact
- Improve `entropy` package provider to set locale envvar directly
  and not shell out to a distributed script to set locale.

## 2016-10-13 Release 0.1.2

- Improved package regexes for valdiation and parsing
  (now following the Gentoo EAPI6 PMS document to ensure correctness)
- Removed validation for required parameters in `entropy_*` types

## 2016-10-13 Release 0.1.0

- Added support for additional types:
  - `entropy_splitdebug`
  - `entropy_splitdebug_mask`
  - `entropy_keywords`
- Added spec tests for most types and providers

## 2016-10-10 Release 0.0.2

- First forge release

