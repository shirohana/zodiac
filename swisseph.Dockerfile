# syntax = docker/dockerfile:1.4

ARG SWISSEPH_VERSION="2.10.03"

# Build the Swiss Ephemeris binary

FROM --platform=$BUILDPLATFORM alpine:3.19 AS builder
ARG SWISSEPH_VERSION

RUN --mount=type=cache,target=/var/cache/apk,sharing=locked \
  --mount=type=cache,target=/var/lib/apk,sharing=locked \
  apk add build-base make

WORKDIR /source
RUN wget "https://github.com/aloistr/swisseph/archive/refs/tags/v${SWISSEPH_VERSION}.tar.gz" -O- \
    | tar xz \
  && mv ./swisseph-${SWISSEPH_VERSION}/* . \
  && rmdir ./swisseph-${SWISSEPH_VERSION}
RUN make swetest

# Download the latest planet and main asteroid files

FROM --platform=$BUILDPLATFORM alpine:3.19 AS downloader

RUN --mount=type=cache,target=/var/cache/apk,sharing=locked \
  --mount=type=cache,target=/var/lib/apk,sharing=locked \
  apk add git

WORKDIR /download
RUN git clone --depth=1 --progress https://github.com/aloistr/swisseph.git . \
  && rm -rf .git

# Create executable image

FROM --platform=$TARGETPLATFORM alpine:3.19 AS runner
ARG SWISSEPH_VERSION
WORKDIR /swisseph

COPY --from=builder /source/LICENSE .
COPY --from=builder /source/swetest .
COPY --from=downloader /download/ephe/*.se1 .

ENV PATH="/swisseph:${PATH}"
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
CMD ["swetest", "-h"]
