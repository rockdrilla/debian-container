#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# (c) 2022-2023, Konstantin Demin

# yet another kaniko killer ;D

# common shell functions: begin

arg0="${0##*/}"

log() {
	if [ $# = 0 ] ; then
		echo "# ${arg0}: $(date +'%Y-%m-%d %H:%M:%S %z')"
	else
		echo "# ${arg0}: $*"
	fi >&2
}

log_verbose() {
	[ "${BUILD_IMAGE_VERBOSE}" = 1 ] || return 0
	log "$@"
}

have_cmd() { command -v "$1" >/dev/null 2>&1 ; }
git_ro() { GIT_OPTIONAL_LOCKS=0 command git "$@"; }

get_env() {
	printf '%s' "$1" | grep -Eqz '^[a-zA-Z_][a-zA-Z0-9_]*$' || {
		env printf "! %s: get_env: name looks suspicious: %q\n" "${arg0}" "$1" >&2
		return 0
	}
	sed -Enz "/^$1=(.+)\$/s,,\\1,p" /proc/self/environ | tr -d '\0' || :
}
get_env_b64() { get_env "$1" | base64 -d ; }

pod_run() {
	podman run --rm --entrypoint='["/bin/sh","-c"]' "$@"
}

ensure_arg0_file() {
	[ -z "${BUILD_IMAGE_ARG0_FILE}" ] || return 0
	BUILD_IMAGE_ARG0_FILE=$(umask 0077 ; mktemp)
	: "${BUILD_IMAGE_ARG0_FILE:?}"
	export BUILD_IMAGE_ARG0_FILE
}
append() {
	ensure_arg0_file
	printf '%s\0' "$@" >> "${BUILD_IMAGE_ARG0_FILE}"
}

append_arg() {
	case "$1" in
	*=*) append --build-arg "$1" ;;
	*)   append --build-arg "$1=$(get_env "$1")" ;;
	esac
}

ensure_secrets_dir() {
	[ -z "${BUILD_IMAGE_SECRETS_DIR}" ] || return 0
	BUILD_IMAGE_SECRETS_DIR=$(umask 0077 ; mktemp -d)
	: "${BUILD_IMAGE_SECRETS_DIR:?}"
	export BUILD_IMAGE_SECRETS_DIR
}
append_secret() {
	case "$1" in
	*=*)
		_secret_arg="${1%%=*}"
		_secret_path="${1#*=}"
	;;
	*)
		ensure_secrets_dir

		_secret_arg="$1"
		_secret_path=$(printf '%s' "${_secret_arg}" | sha1sum -bz | cut -c 1-16)
		_secret_path="${BUILD_IMAGE_SECRETS_DIR}/${_secret_path}"
		get_env "${_secret_arg}" > "${_secret_path}"
	;;
	esac

	if [ -z "${_secret_path}" ] ; then
		log "secrets: ${_secret_arg}: empty path, using /dev/null"
		append "--secret=id=${_secret_arg},src=/dev/null"
	elif [ -n "$(readlink -e "${_secret_path}")" ] ; then
		append "--secret=id=${_secret_arg},src=${_secret_path}"
	else
		log "secrets: ${_secret_arg}: skipping: non-existent path!"
	fi

	unset _secret_arg _secret_path
}

append_build_ctx() {
	append --build-context "$1"
}

append_ulimit() {
	append --ulimit "$1"
}

append_cap() {
	case "$1" in
	-*) append "--cap-drop=${1#-}" ;;
	+*) append "--cap-add=${1#+}" ;;
	*)  append "--cap-add=$1" ;;
	esac
}

append_volume() {
	case "$1" in
	/*) append --volume "$1" ;;
	*)  append --volume "${PWD}/$1" ;;
	esac
}

append_env() {
	case "$1" in
	*=*) append --env "$1" ;;
	*-)  append --unsetenv "${1%-}" ;;
	*)   append --env "$1" ;;
	esac
}

append_label() { append --label "${BUILD_IMAGE_LABEL_PREFIX}$1"; }

append_annotation() {
	append --annotation "$1"
}

process_file_sh_style() {
	sed -E -e '/^\s*(#|$)/d' "$@"
}

build_image_cleanup() {
	if [ -n "${BUILD_IMAGE_ARG0_FILE}" ] ; then
		rm -f "${BUILD_IMAGE_ARG0_FILE}"
		unset BUILD_IMAGE_ARG0_FILE
	fi

	if [ -n "${BUILD_IMAGE_SECRETS_DIR}" ] ; then
		rm -rf "${BUILD_IMAGE_SECRETS_DIR}"
		unset BUILD_IMAGE_SECRETS_DIR
	fi
}
build_image() {
	if [ -n "${BUILD_IMAGE_PLATFORM}" ] ; then
		append --platform "${BUILD_IMAGE_PLATFORM}"
	else
		[ -z "${BUILD_IMAGE_OS}" ]      || append --os      "${BUILD_IMAGE_OS}"
		[ -z "${BUILD_IMAGE_ARCH}" ]    || append --arch    "${BUILD_IMAGE_ARCH}"
		[ -z "${BUILD_IMAGE_VARIANT}" ] || append --variant "${BUILD_IMAGE_VARIANT}"
	fi

	: "${BUILD_IMAGE_NETWORK:=host}"
	case "${BUILD_IMAGE_NETWORK}" in
	none) append --http-proxy=false ;;
	esac
	append "--net=${BUILD_IMAGE_NETWORK}"

	# (always) passthrough GitLab CI/CD env
	if [ -n "${CI:+1}" ] ; then
		append_arg CI
	fi

	while [ "${BUILD_IMAGE_AUTO_LABELS:-1}" = 1 ] ; do
		[ "${BUILD_IMAGE_NAME_AUTO}" = 0 ] || break

		append_label "git.file=$(git_ro rev-parse --show-prefix 2>/dev/null || :)${BUILD_IMAGE_SCRIPT}"

		case "${BUILD_IMAGE_CI_KIND:-gitlab}" in
		gitlab )
			[ -z "${CI_PROJECT_URL}" ]     || append_label "git.project=${CI_PROJECT_URL}"
			[ -z "${CI_COMMIT_SHA}" ]      || append_label "git.commit=${CI_COMMIT_SHA}"
			[ -z "${CI_COMMIT_REF_NAME}" ] || append_label "git.ref=${CI_COMMIT_REF_NAME}"
			[ -z "${CI_COMMIT_TAG}" ]      || append_label "git.tag=${CI_COMMIT_TAG}"
			[ -z "${CI_COMMIT_REF_SLUG}" ] || append_label "git.refslug=${CI_COMMIT_REF_SLUG}"
			[ -z "${CI_PIPELINE_IID}" ]    || append_label "ci.pipeline=${CI_PIPELINE_IID}"
		;;
		* )
			log "unhandled BUILD_IMAGE_CI_KIND='${BUILD_IMAGE_CI_KIND}' - no auto-labels"
		;;
		esac
		break
	done

	for _i in ${BUILD_IMAGE_ARGS} ; do
		[ -n "${_i}" ] || continue
		append_arg "${_i}"
	done ; unset _i

	for _i in ${BUILD_IMAGE_SECRETS} ; do
		[ -n "${_i}" ] || continue
		append_secret "${_i}"
	done ; unset _i

	for _i in ${BUILD_IMAGE_CONTEXTS} ; do
		[ -n "${_i}" ] || continue
		append_build_ctx "${_i}"
	done ; unset _i

	for _i in ${BUILD_IMAGE_ULIMITS} ; do
		[ -n "${_i}" ] || continue
		append_ulimit "${_i}"
	done ; unset _i

	for _i in ${BUILD_IMAGE_CAPABILITIES} ; do
		[ -n "${_i}" ] || continue
		append_cap "${_i}"
	done ; unset _i

	for _i in ${BUILD_IMAGE_VOLUMES} ; do
		[ -n "${_i}" ] || continue
		append_volume "${_i}"
	done ; unset _i

	# append arguments
	[ $# = 0 ] || append "$@"

	if [ -z "${BUILD_IMAGE_ARG0_FILE}" ] ; then
		log "nothing to do: arg0_file was not created"
		return 1
	fi
	if ! [ -s "${BUILD_IMAGE_ARG0_FILE}" ] ; then
		log "nothing to do: arg0_file is empty"
		return 1
	fi

	set +e
	xargs -0 -r ${BUILD_IMAGE_VERBOSE:+-t} -a "${BUILD_IMAGE_ARG0_FILE}" \
	buildah bud
	_r=$?

	build_image_cleanup

	return ${_r}
}

build_image_ex() {
	for _i in ${BUILD_IMAGE_ENV} ; do
		[ -n "${_i}" ] || continue
		append_env "${_i}"
	done ; unset _i

	for _n in ${BUILD_IMAGE_ENV_FILE} ; do
		[ -n "${_n}" ] || continue

		for _f in "${_n}" ${BUILD_IMAGE_WORKDIR:+"${BUILD_IMAGE_WORKDIR}${_n}"} ; do
			[ -n "${_f}" ] || continue

			log_verbose "env: trying file ${_f}"
			[ -s "${_f}" ] || continue

			log "env: processing file ${_f}"

			while read -r _i ; do
				[ -n "${_i}" ] || continue
				append_env "${_i}"
			done <<-EOF
			$(process_file_sh_style "${_f}")
			EOF
			unset _i

			break
		done ; unset _f
	done ; unset _n

	for _i in ${BUILD_IMAGE_LABELS} ; do
		[ -n "${_i}" ] || continue
		append_label "${_i}"
	done ; unset _i

	for _n in ${BUILD_IMAGE_LABELS_FILE} ; do
		[ -n "${_n}" ] || continue

		for _f in "${_n}" ${BUILD_IMAGE_WORKDIR:+"${BUILD_IMAGE_WORKDIR}${_n}"} ; do
			[ -n "${_f}" ] || continue

			log_verbose "labels: trying file ${_f}"
			[ -s "${_f}" ] || continue

			log "labels: processing file ${_f}"

			while read -r _i ; do
				[ -n "${_i}" ] || continue
				append_label "${_i}"
			done <<-EOF
			$(process_file_sh_style "${_f}")
			EOF
			unset _i

			break
		done ; unset _f
	done ; unset _n

	for _i in ${BUILD_IMAGE_ANNOTATIONS} ; do
		[ -n "${_i}" ] || continue
		append_annotation "${_i}"
	done ; unset _i

	for _n in ${BUILD_IMAGE_ANNOTATIONS_FILE} ; do
		[ -n "${_n}" ] || continue

		for _f in "${_n}" ${BUILD_IMAGE_WORKDIR:+"${BUILD_IMAGE_WORKDIR}${_n}"} ; do
			[ -n "${_f}" ] || continue

			log_verbose "annotations: trying file ${_f}"
			[ -s "${_f}" ] || continue

			log "annotations: processing file ${_f}"

			while read -r _i ; do
				[ -n "${_i}" ] || continue
				append_annotation "${_i}"
			done <<-EOF
			$(process_file_sh_style "${_f}")
			EOF
			unset _i

			break
		done ; unset _f
	done ; unset _n

	build_image "$@"
}

push_image_by_ref() {
	log "push: ${1:?}"
	podman push "$1" || return 1

	while read -r _image ; do
		[ -n "${_image}" ] || continue

		log "copy: $1 -> ${_image}"
		skopeo copy "docker://$1" "docker://${_image}" || continue
	done <<-EOF
	$(podman images --format='{{.Repository}}:{{.Tag}}' --filter "reference=$1" | grep -Fxv -e "$1" || :)
	EOF
	unset _image
}

# TODO: push_image_by_id() is needed or not?

adjust_script_name() {
	if [ "$1" = "${1##*/}" ] ; then
		printf '%s' "./$1"
	else
		printf '%s' "$1"
	fi
}

run_script() {
	[ -n "$1" ] || return 0
	[ -s "$1" ] || return 0
	_r=0
	if [ -x "$1" ] ; then
		"$@" || _r=$?
	else
		__BUILD_IMAGE_X=1 \
		"$0" "$@" || _r=$?
	fi
	[ "${_r}" = 0 ] || log "run_script: '$*' returned ${_r}"
	return ${_r}
}

handle_auto_images() {
	[ "${BUILD_IMAGE_NAME_AUTO}" = 1 ] || return 0
	log "REMOVING auto-images (if any)"
	podman images --format='{{.Id}}' \
	  --filter "reference=${BUILD_IMAGE_NAME}" \
	  ${BUILD_IMAGE_BASE_NAME:+ --filter "reference=${BUILD_IMAGE_BASE_NAME}" } \
	| sort -uV | xargs -r podman image rm
}

# common shell functions: end

# run proxy script (if any)

if [ -n "${__BUILD_IMAGE_X}" ] ; then
	unset __BUILD_IMAGE_X
	script=$(adjust_script_name "$1")
	arg0="${1##*/}"
	shift
	. "${script}"
	exit
fi

# in case of sourcing

case "${0##*/}" in
build-image.sh) ;;
*)
	unset __BUILD_IMAGE_X
	__BUILD_IMAGE_X=1
;;
esac

# build-image.sh itself begin

if [ -z "${__BUILD_IMAGE_X}" ] ; then

set -f

usage() {
	cat >&2 <<-EOF
		Usage: ${arg0} <script/directory> [.. <image name>]
	EOF
	exit ${1:-1}
}

if [ $# -eq 0 ] ; then
	usage 0
fi

: "${1:?}"

BUILD_IMAGE_SCRIPT=
BUILD_IMAGE_WORKDIR=

if [ -f "$1" ] ; then
	BUILD_IMAGE_SCRIPT="$1"
	BUILD_IMAGE_WORKDIR=$(dirname "$1")'/'
	if [ "${BUILD_IMAGE_WORKDIR}" = './' ] ; then
		BUILD_IMAGE_WORKDIR=
	fi
elif [ -d "$1" ] ; then
	BUILD_IMAGE_WORKDIR=$(printf '%s' "$1" | sed -zE 's#/*$#/#')
	if [ "${BUILD_IMAGE_WORKDIR}" = './' ] ; then
		BUILD_IMAGE_WORKDIR=
	fi

	if [ -z "${BUILD_IMAGE_SCRIPT}" ] ; then
		BUILD_IMAGE_SCRIPT=
		for f in 'build-image.script' 'Containerfile' 'Dockerfile' ; do
			[ -s "${BUILD_IMAGE_WORKDIR}$f" ] || continue
			BUILD_IMAGE_SCRIPT="${BUILD_IMAGE_WORKDIR}$f"
			break
		done
		if [ -z "${BUILD_IMAGE_SCRIPT}" ] ; then
			log "directory doesn't contain recipes: ${BUILD_IMAGE_WORKDIR:-./}"
			usage
		fi
	else
		if ! [ -s "${BUILD_IMAGE_SCRIPT}" ] ; then
			log "recipe does not exist: ${BUILD_IMAGE_SCRIPT}"
			usage
		fi
	fi
else
	log "invalid script/directory argument: $1"
	usage
fi

# 1st argument is handled
# remaining arguments are image names (may be asbent though)
shift

case "${BUILD_IMAGE_SCRIPT##*/}" in
*Containerfile* | *Dockerfile* ) ;;
*) : "${BUILD_IMAGE_SCRIPT_CUSTOM:=1}" ;;
esac
: "${BUILD_IMAGE_SCRIPT_CUSTOM:=0}"
export BUILD_IMAGE_SCRIPT_CUSTOM

: "${BUILD_IMAGE_CONTEXT:=${BUILD_IMAGE_WORKDIR}}"
[ -n "${BUILD_IMAGE_CONTEXT}" ] || BUILD_IMAGE_CONTEXT=.
BUILD_IMAGE_CONTEXT=$(printf '%s' "${BUILD_IMAGE_CONTEXT}" | sed -zE 's#/*$#/#')
if [ "${BUILD_IMAGE_CONTEXT}" = './' ] ; then
	BUILD_IMAGE_CONTEXT=
fi
export BUILD_IMAGE_CONTEXT BUILD_IMAGE_SCRIPT BUILD_IMAGE_SCRIPT_CUSTOM

# handle first image name or use "autogenerated" local one

BUILD_IMAGE_NAME_AUTO=0
: "${BUILD_IMAGE_PUSH:=1}"
if [ -n "$1" ] ; then
	BUILD_IMAGE_NAME="$1"
else
	BUILD_IMAGE_NAME=$(mktemp -u build-image-XXXXXXXXXX)
	BUILD_IMAGE_NAME_AUTO=1
	BUILD_IMAGE_PUSH=0
fi

# 2nd argument (if any) is handled
# remaining arguments are auxiliary image names (may be absent)
if [ $# != 0 ] ; then shift ; fi

# readjust image name
IFS=: read -r _image _tag _extra <<-EOF
$(printf '%s' "${BUILD_IMAGE_NAME}" | tr '[:upper:]' '[:lower:]')
EOF
if [ -z "${_image}" ] ; then
	log "invalid image name format, got '${BUILD_IMAGE_NAME}'"
	usage
fi
BUILD_IMAGE_NAME="${_image}:${_tag:-latest}"
unset _image _tag _extra

export BUILD_IMAGE_NAME BUILD_IMAGE_NAME_AUTO BUILD_IMAGE_PUSH

# detect "base image" script/files (if any)

: "${BUILD_IMAGE_BASE:=1}"
export BUILD_IMAGE_BASE

if [ "${BUILD_IMAGE_BASE}" = 1 ] ; then
	: "${BUILD_IMAGE_BASE_SCRIPT:=${BUILD_IMAGE_SCRIPT}.base}"
	if [ -s "${BUILD_IMAGE_BASE_SCRIPT}" ] ; then
		export BUILD_IMAGE_BASE_SCRIPT
	else
		unset BUILD_IMAGE_BASE
	fi
fi

if [ "${BUILD_IMAGE_BASE}" = 1 ] ; then
	case "${BUILD_IMAGE_BASE_SCRIPT##*/}" in
	*Containerfile* | *Dockerfile* ) ;;
	*) : "${BUILD_IMAGE_BASE_SCRIPT_CUSTOM:=1}" ;;
	esac
	: "${BUILD_IMAGE_BASE_SCRIPT_CUSTOM:=0}"
	export BUILD_IMAGE_BASE_SCRIPT_CUSTOM
fi

if [ "${BUILD_IMAGE_BASE}" = 1 ] ; then
	: "${BUILD_IMAGE_BASE_DEPS:=${BUILD_IMAGE_BASE_SCRIPT}.deps}"
	if [ -f "${BUILD_IMAGE_BASE_DEPS}" ] ; then
		export BUILD_IMAGE_BASE_DEPS
	else
		unset BUILD_IMAGE_BASE_DEPS
	fi
fi

if [ "${BUILD_IMAGE_BASE}" = 1 ] ; then
	IFS=: read -r _image _tag _extra <<-EOF
	${BUILD_IMAGE_NAME}
	EOF
	: "${BUILD_IMAGE_BASE_NAME:=${_image}-base:${_tag:-latest}}"
	unset _image _tag _extra

	# readjust base image name
	IFS=: read -r _image _tag _extra <<-EOF
	${BUILD_IMAGE_BASE_NAME}
	EOF
	BUILD_IMAGE_BASE_NAME="${_image}:${_tag:-latest}"
	unset _image _tag _extra

	export BUILD_IMAGE_BASE_NAME
fi

# cleanup variables if "base image" is missing or somewhat "broken"
if [ "${BUILD_IMAGE_BASE}" != 1 ] ; then
	unset BUILD_IMAGE_BASE \
	BUILD_IMAGE_BASE_SCRIPT \
	BUILD_IMAGE_BASE_SCRIPT_CUSTOM \
	BUILD_IMAGE_BASE_DEPS \
	BUILD_IMAGE_BASE_REBUILD \
	BUILD_IMAGE_BASE_NAME
fi

# detect changes in "base image" (if any)
while [ "${BUILD_IMAGE_BASE}" = 1 ] ; do
	case "${BUILD_IMAGE_BASE_REBUILD}" in
	skip | force) break ;;
	0) BUILD_IMAGE_BASE_REBUILD=skip  ; break ;;
	1) BUILD_IMAGE_BASE_REBUILD=force ; break ;;
	esac

	export BUILD_IMAGE_BASE_REBUILD=skip

	have_cmd git || {
		log "missing binary 'git' - unable to detect changes in base image"
		break
	}
	have_cmd git-changes.sh || {
		log "missing script 'git-changes.sh' - unable to detect changes in base image"
		break
	}

	case "${BUILD_IMAGE_CI_KIND:-gitlab}" in
	gitlab )
		[ -n "${CI_COMMIT_SHA}" ] || {
			log "CI_COMMIT_SHA is empty - unable to detect changes in base image"
			break
		}

		if printf '%s' "${CI_COMMIT_BEFORE_SHA}" | grep -Eqz '^0*$' ; then
			: "${BUILD_IMAGE_GIT_REMOTE:=origin}"
			: "${BUILD_IMAGE_GIT_BRANCH:=${CI_DEFAULT_BRANCH}}"

			[ -n "${BUILD_IMAGE_GIT_REMOTE}" ] || {
				log "BUILD_IMAGE_GIT_REMOTE is empty - unable to detect changes in base image"
				break
			}

			[ -n "${BUILD_IMAGE_GIT_BRANCH}" ] || {
				log "BUILD_IMAGE_GIT_BRANCH and/or CI_DEFAULT_BRANCH is empty - unable to detect changes in base image"
				break
			}

			CI_COMMIT_BEFORE_SHA="${BUILD_IMAGE_GIT_REMOTE}/${BUILD_IMAGE_GIT_BRANCH}"
		fi

		BUILD_IMAGE_GIT_REF_BASE=${CI_COMMIT_BEFORE_SHA}
		BUILD_IMAGE_GIT_REF_CURRENT=${CI_COMMIT_SHA}
	;;
	* )
		log "unhandled BUILD_IMAGE_CI_KIND='${BUILD_IMAGE_CI_KIND}' - unable to detect changes in base image"
		break
	;;
	esac

	[ -n "${BUILD_IMAGE_GIT_REF_BASE}" ] || {
		log "BUILD_IMAGE_GIT_REF_BASE is empty - unable to detect changes in base image"
		break
	}
	[ -n "${BUILD_IMAGE_GIT_REF_CURRENT}" ] || {
		log "BUILD_IMAGE_GIT_REF_CURRENT is empty - unable to detect changes in base image"
		break
	}
	export BUILD_IMAGE_GIT_REF_BASE BUILD_IMAGE_GIT_REF_CURRENT

	_change_list=$(mktemp)
	: "${_change_list:?}"

	# pass '' as last parameter to treat "${BUILD_IMAGE_BASE_SCRIPT}" as "pattern" not "pattern file"
	git-changes.sh "${BUILD_IMAGE_GIT_REF_BASE}" "${BUILD_IMAGE_GIT_REF_CURRENT}" \
	"${BUILD_IMAGE_BASE_SCRIPT}" '' \
	>> "${_change_list}"

	if [ -n "${BUILD_IMAGE_BASE_DEPS}" ] ; then
		# pass '' as last parameter to treat "${BUILD_IMAGE_BASE_DEPS}" as "pattern" not "pattern file"
		git-changes.sh "${BUILD_IMAGE_GIT_REF_BASE}" "${BUILD_IMAGE_GIT_REF_CURRENT}" \
		"${BUILD_IMAGE_BASE_DEPS}" '' \
		>> "${_change_list}"

		if [ -s "${BUILD_IMAGE_BASE_DEPS}" ] ; then
			git-changes.sh "${BUILD_IMAGE_GIT_REF_BASE}" "${BUILD_IMAGE_GIT_REF_CURRENT}" \
			"${BUILD_IMAGE_BASE_DEPS}" \
			>> "${_change_list}"
		fi
	fi

	if [ -s "${_change_list}" ] ; then
		log "there're detected changes in base image - rebuilding"

		export BUILD_IMAGE_BASE_REBUILD=force

		if [ "${BUILD_IMAGE_VERBOSE}" = 1 ] ; then
			log "changed files:"
			while read -r _line ; do
				[ -n "${_line}" ] || continue
				log "> ${_line}"
			done < "${_change_list}"
			unset _line
		fi
	else
		log "no changes were detected in base image (so far)"
	fi

	rm -f "${_change_list}" ; unset _change_list

	break
done

# hook scripts

: "${BUILD_IMAGE_SCRIPT_PRE:="${BUILD_IMAGE_WORKDIR}.build-image.pre"}"
BUILD_IMAGE_SCRIPT_PRE=$(adjust_script_name "${BUILD_IMAGE_SCRIPT_PRE}")

: "${BUILD_IMAGE_SCRIPT_POST:="${BUILD_IMAGE_WORKDIR}.build-image.post"}"
BUILD_IMAGE_SCRIPT_POST=$(adjust_script_name "${BUILD_IMAGE_SCRIPT_POST}")

# rebuild base image (if any)

unset BUILD_IMAGE_LABEL_PREFIX

if [ "${BUILD_IMAGE_BASE_REBUILD}" = force ] ; then
	export BUILD_IMAGE_LABEL_PREFIX='base.'

	run_script "${BUILD_IMAGE_SCRIPT_POST}" pre base || {
		build_image_cleanup
		exit 1
	}

	[ -z "${BUILD_IMAGE_BASE_TARGET}" ] || append --target "${BUILD_IMAGE_BASE_TARGET}"

	result=0
	if [ "${BUILD_IMAGE_BASE_SCRIPT_CUSTOM}" = 1 ] ; then
		run_script "${BUILD_IMAGE_BASE_SCRIPT}" build base
		result=$?
	else
		BUILD_IMAGE_SCRIPT="${BUILD_IMAGE_BASE_SCRIPT}" \
		build_image_ex \
		  -t "${BUILD_IMAGE_BASE_NAME}" \
		  -f "${BUILD_IMAGE_BASE_SCRIPT}" \
		"${BUILD_IMAGE_CONTEXT:-.}"
		result=$?
	fi

	if [ ${result} -ne 0 ] ; then
		log "build FAILED, return code: ${result}"
		exit ${result}
	fi

	unset BUILD_IMAGE_LABEL_PREFIX

	# replace first "FROM" image with current base image
	# this is 1st argument in file "${BUILD_IMAGE_ARG0_FILE}"
	# since file is removed after build in build_image()/build_image_ex()
	append --from "${BUILD_IMAGE_BASE_NAME}"

	run_script "${BUILD_IMAGE_SCRIPT_POST}" post base || {
		build_image_cleanup
		handle_auto_images
		exit 1
	}
fi

run_script "${BUILD_IMAGE_SCRIPT_PRE}" pre main || {
	build_image_cleanup
	handle_auto_images
	exit 1
}

[ -z "${BUILD_IMAGE_TARGET}" ] || append --target "${BUILD_IMAGE_TARGET}"

result=0
if [ "${BUILD_IMAGE_SCRIPT_CUSTOM}" = 1 ] ; then
	run_script "${BUILD_IMAGE_SCRIPT}" build main
	result=$?
else
	if [ "${BUILD_IMAGE_BASE}" = 1 ] ; then
		build_image \
		  -t "${BUILD_IMAGE_NAME}" \
		  -f "${BUILD_IMAGE_SCRIPT}" \
		"${BUILD_IMAGE_CONTEXT:-.}"
		result=$?
	else
		build_image_ex \
		  -t "${BUILD_IMAGE_NAME}" \
		  -f "${BUILD_IMAGE_SCRIPT}" \
		"${BUILD_IMAGE_CONTEXT:-.}"
		result=$?
	fi
fi

if [ ${result} -ne 0 ] ; then
	log "build FAILED, return code: ${result}"
	handle_auto_images
	exit ${result}
fi

run_script "${BUILD_IMAGE_SCRIPT_POST}" post main || {
	handle_auto_images
	exit 1
}

# implicit iteration over "$@""
for _arg ; do
	case "${_arg}" in
	:*) _image="${BUILD_IMAGE_NAME%:*}${_arg}" ;;
	*:) _image="${_arg}${BUILD_IMAGE_NAME#*:}" ;;
	*) _image="${_arg}" ;;
	esac

	log "tag: ${BUILD_IMAGE_NAME} -> ${_image}"
	podman tag "${BUILD_IMAGE_NAME}" "${_image}"
done ; unset _arg _image

if [ "${BUILD_IMAGE_PUSH}" = 1 ] ; then
	if [ "${BUILD_IMAGE_BASE_REBUILD}" = force ] ; then
		push_image_by_ref "${BUILD_IMAGE_BASE_NAME}"
	fi

	push_image_by_ref "${BUILD_IMAGE_NAME}"
else
	log "NOT pushing image${*:+(s)}: ${BUILD_IMAGE_BASE_NAME:+${BUILD_IMAGE_BASE_NAME} }${BUILD_IMAGE_NAME}${*:+ $*}"
fi

# list images

podman images \
  --format='table {{.Size}} {{.ID}} {{.Repository}}:{{.Tag}}' \
  --filter "reference=${BUILD_IMAGE_NAME}" \
  ${BUILD_IMAGE_BASE_NAME:+--filter "reference=${BUILD_IMAGE_BASE_NAME}"}

handle_auto_images

# build-image.sh itself end

fi
