#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

# SHELL FUNCTIONS
# ------------------------------------------------------------------------------

function __is_command {
    command -v "$1" 2>&1 > /dev/null
}

function __printerr {
    if [ $# -ne 0 ]; then
        printf '%s' "$1" >&2
        shift

        if [ $# -ne 0 ]; then
            for arg in $@; do
                printf ' %s' "$arg" >&2
            done
        fi
    else
        printf '\n' >&2
    fi
}

# SCRIPT FUNCTIONS
# ------------------------------------------------------------------------------

function __buid_image {
    local engine="$1"
    local image="$2"

    __printerr "> Build image '${image}'..."
    __printerr
    __printerr

    "${engine}" build --tag "${image}" .

    __printerr ' Build Completed'
    __printerr
    __printerr
}

function __push_image {
    local engine="$1"
    local image="$2"

    __printerr "> Push image '${image}'..."
    __printerr
    __printerr

    "${engine}" push "${image}"

    __printerr ' Push Completed'
    __printerr
    __printerr
}

function __tag_image {
    local engine="$1"
    local image="$2"
    local tag="$3"

    __printerr "> Add image '${image}' with '${tag}'..."
    __printerr
    __printerr

    "${engine}" tag "${image}" "${tag}"

    __printerr ' Tag added'
    __printerr
    __printerr
}

# SELECT ENGINE

if __is_command docker; then
    __ENGINE='docker'
elif __is_command podman; then
    __ENGINE='podman'
else
    __printerr 'Error: neither `docker` nor `podman` are installed on this system.'
    exit 1
fi

__NOT_BUILT=true

# LOAD ENVIRONMENT

source build.env

REGISTRY=($REGISTRY)
TAG=($TAG)

# BUILD AND TAG IMAGE

for r in "${REGISTRY[@]}"; do
    for t in "${TAG[@]}"; do
        if $__NOT_BUILT; then
            __buid_image "$__ENGINE" "${REGISTRY[0]}/${OWNER}/${IMAGE}:${TAG[0]}"
            __NOT_BUILT=false
        else
            __tag_image "$__ENGINE" \
                "${REGISTRY[0]}/${OWNER}/${IMAGE}:${TAG[0]}" \
                "${r}/${OWNER}/${IMAGE}:${t}"
        fi
    done

    if $LATEST; then
        __tag_image "$__ENGINE" \
            "${REGISTRY[0]}/${OWNER}/${IMAGE}:${TAG[0]}" \
            "${r}/${OWNER}/${IMAGE}:latest"
    fi
done

# PUSH

if $PUSH; then
    for r in ${REGISTRY[@]}; do
        for t in ${TAG[@]}; do
            __push_image "$__ENGINE" "${r}/${OWNER}/${IMAGE}:${t}"
        done

        if $LATEST; then
            __push_image "$__ENGINE" "${r}/${OWNER}/${IMAGE}:latest"
        fi
    done
fi

exit 0