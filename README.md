# debian-container

Alternative Debian GNU/Linux container image approach.

Despite of name, Ubuntu is supported too (mostly).

## container images

### minimal

Minimal base image - `image/minbase/` ([readme](image/minbase/README.md))

Images on Docker.io:
[Debian](https://hub.docker.com/r/rockdrilla/debian/tags)
|
[Ubuntu](https://hub.docker.com/r/rockdrilla/ubuntu/tags)

### minimal with "debug"

"Debug" base image - `image/minbase-debug/` ([dockerfile](image/minbase-debug/Dockerfile))

Images on Docker.io:
[Debian](https://hub.docker.com/r/rockdrilla/debian-debug/tags)
|
[Ubuntu](https://hub.docker.com/r/rockdrilla/ubuntu-debug/tags)

### buildd

Package building image - `image/buildd/` ([dockerfile](image/buildd/Dockerfile))

Images on Docker.io:
[Debian](https://hub.docker.com/r/rockdrilla/debian-buildd/tags)
|
[Ubuntu](https://hub.docker.com/r/rockdrilla/ubuntu-buildd/tags)

Build helper image - `image/buildd/` ([dockerfile](image/buildd/Dockerfile))

Images on Docker.io:
[Debian](https://hub.docker.com/r/rockdrilla/debian-buildd-helper/tags)
|
[Ubuntu](https://hub.docker.com/r/rockdrilla/ubuntu-buildd-helper/tags)

### python - minimal/standard

Python image/packages - `image/python/` ([dockerfile](image/python/Dockerfile))

Versions:

- 3.9.18
- 3.10.13
- 3.11.5

Images on Docker.io:
[raw .deb](https://hub.docker.com/r/rockdrilla/python-pkg/tags)
|
[minimal](https://hub.docker.com/r/rockdrilla/python-min/tags)
|
[+ package manager](https://hub.docker.com/r/rockdrilla/python/tags)
|
[+ development files](https://hub.docker.com/r/rockdrilla/python-dev/tags)

### golang - minimal/standard

Golang image/packages - `image/golang/` ([dockerfile](image/golang/Dockerfile))

Versions:

- 1.20.8
- 1.21.1

Images on Docker.io:
[raw .deb](https://hub.docker.com/r/rockdrilla/golang-pkg/tags)
|
[minimal (no CGO)](https://hub.docker.com/r/rockdrilla/golang-min/tags)
|
[+ GCC (with CGO)](https://hub.docker.com/r/rockdrilla/golang/tags)

### nodejs - minimal/standard

NodeJs image/packages - `image/nodejs/` ([dockerfile](image/nodejs/Dockerfile))

Versions:

- 12.22.12
- 14.21.3
- 16.20.2
- 18.18.0

*NB*: Node.js versions below 18.x are OBSOLETE and provided for backward compatibility.

Images on Docker.io:
[raw .deb](https://hub.docker.com/r/rockdrilla/nodejs-pkg/tags)
|
[minimal](https://hub.docker.com/r/rockdrilla/nodejs-min/tags)
|
[+ package manager](https://hub.docker.com/r/rockdrilla/nodejs/tags)
|
[+ development files](https://hub.docker.com/r/rockdrilla/nodejs-dev/tags)

### ansible-mini

Minimized Ansible image - `image/ansible-mini/` ([dockerfile](image/ansible-mini/Dockerfile))

Based on `python:3.11-bookworm`.

Versions:

- 8.4.x

Images on Docker.io:
[ansible-mini](https://hub.docker.com/r/rockdrilla/ansible-mini/tags)
