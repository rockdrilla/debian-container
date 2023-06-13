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

- 3.9.17
- 3.10.12
- 3.11.4

Images on Docker.io:
[minimal](https://hub.docker.com/r/rockdrilla/python-min/tags)
|
[standard](https://hub.docker.com/r/rockdrilla/python/tags)

### golang - minimal/standard

Golang image/packages - `image/golang/` ([dockerfile](image/golang/Dockerfile))

Versions:

- 1.19.10
- 1.20.5

Images on Docker.io:
[minimal](https://hub.docker.com/r/rockdrilla/golang-min/tags)
|
[standard](https://hub.docker.com/r/rockdrilla/golang/tags)

### nodejs - minimal/standard

NodeJs image/packages - `image/nodejs/` ([dockerfile](image/nodejs/Dockerfile))

Versions:

- 12.22.12
- 14.21.3
- 16.20.0
- 18.16.0

Images on Docker.io:
[minimal](https://hub.docker.com/r/rockdrilla/nodejs-min/tags)
|
[standard](https://hub.docker.com/r/rockdrilla/nodejs/tags)

### ansible-mini

Minimized Ansible image - `image/ansible-mini/` ([dockerfile](image/ansible-mini/Dockerfile))

Based on `python:3.11-bullseye`.

Versions:

- 7.6.x
- 8.0.x

Images on Docker.io:
[ansible-mini](https://hub.docker.com/r/rockdrilla/ansible-mini/tags)
