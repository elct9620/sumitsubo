# The image an operator runs `sumi` from, assembled out of the executables the
# release already built. The build context is those artifacts and not this
# tree: nothing is compiled here, so a clean checkout has nothing to build.

# What a scratch image cannot supply. The executable is linked against glibc,
# so the loader named in its header and the libraries it asks for are staged
# here. `ldd` answers for whichever architecture this build is for, which is
# why no path is written down — they differ between the two.
#
# This base must carry a glibc no older than the one the executable was linked
# against, so it follows the runner the release builds on.
FROM ubuntu:24.04 AS runtime

# Docker spells an architecture differently from the targets a release ships,
# so this is where the two names meet.
ARG TARGETARCH
COPY . /dist
RUN set -eu; \
    case "$TARGETARCH" in \
      amd64) target=linux-x86_64 ;; \
      arm64) target=linux-aarch64 ;; \
      *) echo "no release target for $TARGETARCH" >&2; exit 1 ;; \
    esac; \
    # An artifact carries no file mode, so what arrives here is not executable.
    install -m 755 -D "/dist/sumi-$target/sumi" /rootfs/sumi; \
    for lib in $(ldd /rootfs/sumi | awk '{ for (i = 1; i <= NF; i++) if ($i ~ /^\//) print $i }'); do \
      install -m 755 -D "$lib" "/rootfs$lib"; \
    done

FROM scratch
COPY --from=runtime /rootfs /
# A run answers about the tree it is handed, so the mount point is where it
# starts. Nothing else is here: no shell, no `/etc`, no package manager.
WORKDIR /work
ENTRYPOINT ["/sumi"]
