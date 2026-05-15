#!/usr/bin/env bash

set -eu

usage () {
    echo "USAGE: ./mailmap-update.sh <libarena-repo> <linux-repo>"
    exit 1
}

LIBARENA_REPO="${1-""}"
LINUX_REPO="${2-""}"

if [ -z "${LIBARENA_REPO}" ] || [ -z "${LINUX_REPO}" ]; then
    echo "Error: libarena or linux repos are not specified"
    usage
fi

LIBARENA_MAILMAP="${LIBARENA_REPO}/.mailmap"
LINUX_MAILMAP="${LINUX_REPO}/.mailmap"

tmpfile="$(mktemp)"
cleanup() {
    rm -f "${tmpfile}"
}
trap cleanup EXIT

grep_lines() {
    local pattern="$1"
    local file="$2"
    grep "${pattern}" "${file}" || true
}

while read -r email; do
    grep_lines "${email}$" "${LINUX_MAILMAP}" >> "${tmpfile}"
done < <(git log --format='<%ae>' | sort -u)

sort -u "${tmpfile}" > "${LIBARENA_MAILMAP}"
