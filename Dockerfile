# First stage: Install the latest version of CMake
FROM ubuntu:latest AS cmake-stage

ENV DEBIAN_FRONTEND=noninteractive

# Install wget and dependencies
RUN apt-get update && apt-get install -y wget

# Create the target directory for CMake
RUN mkdir -p /opt/cmake && chmod -R 777 /opt/cmake

# Download and install CMake
RUN wget https://github.com/Kitware/CMake/releases/latest/download/cmake-3.31.2-linux-x86_64.sh && \
    chmod +x cmake-3.31.2-linux-x86_64.sh && \
    ./cmake-3.31.2-linux-x86_64.sh --skip-license --prefix=/opt/cmake && \
    rm -f cmake-3.31.2-linux-x86_64.sh

# Verify CMake installation
RUN /opt/cmake/bin/cmake --version

# Second stage: Install CUDA 12.6 and dependencies, then build voxcraft-sim
FROM nvcr.io/nvidia/cuda:12.4.0-devel-ubuntu22.04

# Set non-interactive mode and preconfigure timezone to avoid prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Preconfigure timezone settings
RUN ln -fs /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone

# Copy CMake from the previous stage
COPY --from=cmake-stage /opt/cmake /opt/cmake

# Update PATH to use the newly installed CMake
ENV PATH="/opt/cmake/bin:${PATH}"

# Set working directory
WORKDIR /root

# Install Miniconda and dependencies
RUN apt-get update && apt-get install -y \
    wget git libboost-all-dev screen tzdata && \
    rm -rf /var/lib/apt/lists/*

# Install Miniconda
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    mkdir /root/.conda && \
    bash Miniconda3-latest-Linux-x86_64.sh -b && \
    rm -f Miniconda3-latest-Linux-x86_64.sh

# Set PATH for Conda
ENV PATH="/root/miniconda3/bin:${PATH}"

# Install required dependencies via Conda
RUN conda install -y -c anaconda cmake

# Clone and build voxcraft-sim using the updated CMake
RUN git clone https://github.com/JacksonKiino-Terburg/voxcraft-sim.git && \
    cd voxcraft-sim && \
    mkdir build && cd build && \
    /opt/cmake/bin/cmake .. && make -j 10