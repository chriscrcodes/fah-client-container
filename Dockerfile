# Base Image
FROM nvidia/cuda:9.2-base-ubuntu18.04

# Folding@home client version and binary file checksum
ARG FAH_VERSION_MAJOR="7.6"
ARG FAH_VERSION_MINOR="21"
ARG FAH_CHECKSUM="2827f05f1c311ee6c7eca294e4ffb856c81957e8f5bfc3113a0ed27bb463b094"

# Update repository and install prerequisites
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      ocl-icd-opencl-dev \
      clinfo \
      curl \
    # point at lib mapped in by container runtime
    && mkdir -p /etc/OpenCL/vendors \
    && echo "libnvidia-opencl.so.1" > /etc/OpenCL/vendors/nvidia.icd \
    # next line gets past the fahclient.postinst
    && mkdir -p /etc/fahclient && touch /etc/fahclient/config.xml \
    # download and verify checksum
    && curl -fsSL \
      https://download.foldingathome.org/releases/public/release/fahclient/debian-stable-64bit/v${FAH_VERSION_MAJOR}/fahclient_${FAH_VERSION_MAJOR}.${FAH_VERSION_MINOR}_amd64.deb \
      -o fah.deb \
    && echo "${FAH_CHECKSUM} fah.deb" \
      | sha256sum -c --strict - \
    # install and cleanup
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