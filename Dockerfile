# Use the latest Amazon Linux 2 image as the base image
FROM amazonlinux:2 as build

ARG LPYTHON_VERSION=0.20.0

RUN yum -y update && \
    yum -y install python3.10 curl tar bzip2 binutils-devel git gcc10 gcc10-c++ && \
    yum clean all && \
    rm -rf /var/cache/yum

WORKDIR /lpython

# Create symbolic links for gcc10-cc and gcc-c++ compilers
RUN ln -s /usr/bin/gcc10-cc /usr/bin/cc && \
    ln -s /usr/bin/gcc10-c++ /usr/bin/c++

# Install Conda (required to build lpython from source)
RUN curl -fsSLo Miniforge3.sh "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh" && \
    bash Miniforge3.sh -b -p ./conda

# Install lpython from source
RUN git clone https://github.com/lcompilers/lpython.git && \
    cd lpython && \
    source "/lpython/conda/etc/profile.d/conda.sh" && \
    conda env create -f environment_unix.yml && \
    conda activate lp && \
    ./build0.sh && \
    ./build1.sh && \
    ctest && \
    ./run_tests.py

FROM amazonlinux:2 as final

RUN yum -y update && \
    yum -y install htop vim python3.10 httpd && \
    yum clean all && \
    rm -rf /var/cache/yum

COPY --from=build /lpython/lpython/inst/bin /usr/local/bin
COPY --from=build /lpython/lpython/inst/share /usr/local/share

EXPOSE 80

CMD ["/usr/sbin/httpd", "-D", "FOREGROUND"]
