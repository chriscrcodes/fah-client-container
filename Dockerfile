# Base Image
FROM nvidia/cuda:9.2-base-ubuntu18.04

# Folding@home client version and binary file checksum
ARG FAH_VERSION_MAJOR="7.6"
ARG FAH_VERSION_MINOR="9"
ARG FAH_CHECKSUM="267BB8DD2B4DA3FBE5AFFCCFA71B4E947BA37CBAD401735DE838E126A58C9EEC"

# Update repository and install prerequisites
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      ocl-icd-opencl-dev \
      clinfo \
      curl \
    && mkdir -p /etc/OpenCL/vendors \
    && echo "libnvidia-opencl.so.1" > /etc/OpenCL/vendors/nvidia.icd \
    && mkdir -p /etc/fahclient && touch /etc/fahclient/config.xml \
    && curl -fsSL \
      https://download.foldingathome.org/releases/public/release/fahclient/debian-stable-64bit/v${FAH_VERSION_MAJOR}/fahclient_${FAH_VERSION_MAJOR}.${FAH_VERSION_MINOR}_amd64.deb \
      -o fah.deb \
    && echo "${FAH_CHECKSUM} fah.deb" \
      | sha256sum -c --strict - \
    && DEBIAN_FRONTEND=noninteractive dpkg --install --force-depends fah.deb \
    && rm -rf fah.deb \
    && apt-get purge --autoremove -y curl \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Copy config.xml file
COPY config.xml /etc/fahclient/

# Run in Folding@home default folder
WORKDIR "/fah"
VOLUME ["/fah"]

# Expose port to control Folding@home client
EXPOSE 36330

# Start client
ENTRYPOINT ["/usr/bin/FAHClient", "--chdir", "/fah", "--config", "/etc/fahclient/config.xml"]