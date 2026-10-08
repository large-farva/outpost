# Personal image

The `personal` branch adds tools for personal use without changing production.
It uses the same `recipes/recipe.yml` path, with its own package additions.
Merge updates from `main` into `personal`, never the other way around.
A personal branch in this public repository is still public.

## Build and switch

Pushes and manual builds on `personal` publish the signed image at
`ghcr.io/large-farva/outpost-personal:latest`. Pull requests do not publish.
There is no scheduled personal build, so trigger a build when you want refreshed
packages, even if the recipe has not changed.

## Docker

The recipe adds Fedora's Moby engine, Docker CLI, Compose, and Buildx. Podman
stays installed. `docker.socket` starts the engine on demand without exposing
an unauthenticated TCP API.

The offline image check verifies packages, CLI plugins, and socket enablement.
Starting containers and checking Docker networking still need a booted image.

## NVIDIA is pending

NVIDIA drivers have not been added yet. Do not rebase expecting NVIDIA's driver
to be available in this revision.

The inspected RTX 2060 Mobile supports NVIDIA's open kernel modules. The blocker
is the build path, not the GPU. BlueBuild's `akmods` module officially supports
Universal Blue bases, and the current upstream stock-kernel build matrix no
longer lists Fedora 43. An old driver payload is not enough to guarantee a match
with Outpost's kernel.

Before adding drivers, choose between keeping Fedora 43 and building matching
RPM Fusion modules during the image build, or moving the personal image to a
maintained NVIDIA-capable base. Neither the Fedora pin nor the base image has
been changed. Secure Boot enrollment, if needed on another machine, is separate
from Outpost's container-image signature.
