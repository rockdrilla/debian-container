# debian-container

Alternative Debian GNU/Linux container image approach.

Despite of name, Ubuntu is supported too (mostly).

## container images

### minimal

Minimal base image - `image/minbase/` ([readme](image/minbase/README.md))

Images on Quay.io:
[Debian](https://quay.io/repository/rockdrilla/debian-min?tab=tags)
|
[Ubuntu](https://quay.io/repository/rockdrilla/ubuntu-min?tab=tags)

Images on Docker.io:
[Debian](https://hub.docker.com/r/rockdrilla/debian-min/tags)
|
[Ubuntu](https://hub.docker.com/r/rockdrilla/ubuntu-min/tags)

### standard

Standard base image - `image/standard/` ([dockerfile](image/standard/Dockerfile))

Images on Quay.io:
[Debian](https://quay.io/repository/rockdrilla/debian?tab=tags)
|
[Ubuntu](https://quay.io/repository/rockdrilla/ubuntu?tab=tags)

Images on Docker.io:
[Debian](https://hub.docker.com/r/rockdrilla/debian/tags)
|
[Ubuntu](https://hub.docker.com/r/rockdrilla/ubuntu/tags)

### buildd

Package building image - `image/buildd/` ([dockerfile](image/buildd/Dockerfile))

Images on Quay.io:
[Debian](https://quay.io/repository/rockdrilla/debian-buildd?tab=tags)
|
[Ubuntu](https://quay.io/repository/rockdrilla/ubuntu-buildd?tab=tags)

Images on Docker.io:
[Debian](https://hub.docker.com/r/rockdrilla/debian-buildd/tags)
|
[Ubuntu](https://hub.docker.com/r/rockdrilla/ubuntu-buildd/tags)

### python - minimal/standard

Python image/packages - `image/python/` ([dockerfile](image/python/Dockerfile))

Versions:

- 3.9.16
- 3.10.9
- 3.11.1

Images on Quay.io:
[minimal](https://quay.io/repository/rockdrilla/python-min?tab=tags)
|
[standard](https://quay.io/repository/rockdrilla/python?tab=tags)

Images on Docker.io:
[minimal](https://hub.docker.com/r/rockdrilla/python-min/tags)
|
[standard](https://hub.docker.com/r/rockdrilla/python/tags)
