# debian-container

Alternative Debian GNU/Linux container image approach.

Despite of name, Ubuntu is supported too (mostly).

## container images

### minimal

Minimal base image - `image/minbase/` ([readme](image/minbase/README.md))

Images on Docker.io:
[Debian](https://hub.docker.com/r/rockdrilla/debian-min/tags)
|
[Ubuntu](https://hub.docker.com/r/rockdrilla/ubuntu-min/tags)

### standard

Standard base image - `image/standard/` ([dockerfile](image/standard/Dockerfile))

Images on Docker.io:
[Debian](https://hub.docker.com/r/rockdrilla/debian/tags)
|
[Ubuntu](https://hub.docker.com/r/rockdrilla/ubuntu/tags)

### buildd

Package building image - `image/buildd/` ([dockerfile](image/buildd/Dockerfile))

Images on Docker.io:
[Debian](https://hub.docker.com/r/rockdrilla/debian-buildd/tags)
|
[Ubuntu](https://hub.docker.com/r/rockdrilla/ubuntu-buildd/tags)

### python - minimal/standard

Python image/packages - `image/python/` ([dockerfile](image/python/Dockerfile))

Versions:

- 3.9.16
- 3.10.10
- 3.11.2

Images on Docker.io:
[minimal](https://hub.docker.com/r/rockdrilla/python-min/tags)
|
[standard](https://hub.docker.com/r/rockdrilla/python/tags)

### golang - minimal/standard

Golang image/packages - `image/golang/` ([dockerfile](image/golang/Dockerfile))

Versions:

- 1.18.10
- 1.19.7
- 1.20.2

Images on Docker.io:
[minimal](https://hub.docker.com/r/rockdrilla/golang-min/tags)
|
[standard](https://hub.docker.com/r/rockdrilla/golang/tags)
