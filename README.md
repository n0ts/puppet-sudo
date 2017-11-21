# Sudo

[![Build Status](https://travis-ci.org/boxen/puppet-sudo.svg)](https://travis-ci.org/boxen/puppet-sudo)

Type/provider for managing sudoers file.

Examples of usage can be found in the tests directory. The type also has rdocs.

Sudoers supports ensure => (present|absent)

*TODO(stuff that I will fix soon)

  1. Setting up autorequires for existing aliases, but this order would only be followed if both records were created.
  2 Shouldn't log flush or to_line events because they occur too often (working on this per issue with parsedfile).

LIMITATIONS (things I will not fix soon):
  1. No support for parsing multi-line files (with \). I may add this in the next revision.
  2. Forced to use comments to specify NAMEVAR for user specs. This means that there is no way to determine if an added line is the same as an existing line.
  3. Dependencies are only applied between records at creation time. It is not possible to insert a new record before an existing one. There is probably a good way to fix this, but I need more time to look into it. Currently discussing with dev, this may require a feature request in parsedfile??
  4. Performance issue with parsedfile- seems to be runing to_line way too many times, also flushing way too often
