# debian-container - minbase

Minimal Debian container image.

*At least, ought to be minimal*. :)

## how to

Images are built in three stages:

1. build intermediate minbase image for Debian testing.
2. build container packages with intermediate image from step 1.
3. build final images with packages from step 2.

See [`build-images.sh`](build-images.sh) for details.

## prerequisites

- relevant version of `mmdebstrap` ([ref](https://gitlab.mister-muffin.de/josch/mmdebstrap))
- `buildah` ([ref](https://github.com/containers/buildah))
- `podman` ([ref](https://github.com/containers/podman))

## internal scripts

This information isn't really helpful, but why no?

### tarball.sh / tarball.stage0.sh

Usage (executing from top-most repository directory):

`image/minbase/tarball.sh {distro} {suite} [output filename]`

If output filename isn't specified then temporary file is created
and it's name printed to `stdout`.

**NB**:
output file is ALWAYS uncompressed tarball despite of provided filename.

Examples:

- `minbase/tarball.sh debian stable debian-stable.tar`
- `minbase/tarball.sh debian 11 debian-11.tar`
- `minbase/tarball.sh ubuntu jammy ubuntu-jammy.tar`
- `minbase/tarball.sh ubuntu 22.04 ubuntu-22.04.tar`

### image.sh / image.stage0.sh

Usage (executing from top-most repository directory):

`image/minbase/image.sh {distro} {suite} {image}`

Examples:

- `minbase/image.sh debian stable debian:stable-min`
- `minbase/image.sh debian 11 debian:11-min`
- `minbase/image.sh ubuntu jammy ubuntu:jammy-min`
- `minbase/image.sh ubuntu 22.04 ubuntu:22.04-min`
