# debian-container - minbase

Minimal Debian container image.

*At least, ought to be minimal*. :)

## tarball

Usage (executing from top-most repository directory):

`minbase/tarball.sh {distro} {suite} [output filename]`

If output filename isn't specified then temporary file is created
and it's name printed to `stdout`.

**NB**:
output file is ALWAYS uncompressed tarball despite of provided filename.

Examples:

- `minbase/tarball.sh debian stable debian-stable.tar`
- `minbase/tarball.sh debian 11 debian-11.tar`
- `minbase/tarball.sh ubuntu jammy ubuntu-jammy.tar`
- `minbase/tarball.sh ubuntu 22.04 ubuntu-22.04.tar`

### prerequisites

- relevant version of `mmdebstrap` ([ref](https://gitlab.mister-muffin.de/josch/mmdebstrap))

## container image

Usage (executing from top-most repository directory):

`minbase/image.sh {distro} {suite} {image}`

Examples:

- `minbase/image.sh debian stable debian:stable-min`
- `minbase/image.sh debian 11 debian:11-min`
- `minbase/image.sh ubuntu jammy ubuntu:jammy-min`
- `minbase/image.sh ubuntu 22.04 ubuntu:22.04-min`

### prerequisites

Same as for `tarball.sh` plus

- `buildah` ([ref](https://github.com/containers/buildah))
