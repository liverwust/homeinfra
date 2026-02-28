FROM debian:bookworm

ENV DEBIAN_FRONTEND=noninteractive
ENV BACULA_VERSION=15.0.3
# Set BACULA_CUSTOMER from the calling shell like this:
# BACULA_CUSTOMER=xxx docker build --secret id=BACULA_CUSTOMER .

# These steps come from
# https://www.bacula.org/packages/${BACULA_CUSTOMER}/debs/${BACULA_VERSION}/dists/bookworm/main/binary-amd64/INSTALL

# In order to use the Bacula Systems apt repository, you need to install the
# HTTPS backend for APT.
RUN apt-get install -y apt-transport-https

# When using the debian:bookworm base image, we need wget and gnupg as well.
RUN apt-get update
RUN apt-get install -y wget gnupg

# Then, you need to download and install the gpg signature that validates
# packages.
RUN wget https://bacula.org/downloads/Bacula-4096-Distribution-Verification-key.asc
RUN apt-key add Bacula-4096-Distribution-Verification-key.asc

# Add to your /etc/apt/sources.list file the following entries:
RUN --mount=type=secret,id=BACULA_CUSTOMER,required=true \
    echo deb https://www.bacula.org/packages/$(cat /run/secrets/BACULA_CUSTOMER)/debs/${BACULA_VERSION} \
    bookworm main > /etc/apt/sources.list.d/bacula.list

# Once done, you can update the repository list with the following command.
RUN apt-get update

# Then install the Bacula with PostgreSQL driver with:
RUN apt-get install -y bacula

CMD ["-fP", "-c", "/opt/bacula/etc/bacula-sd.conf"]
ENTRYPOINT ["/opt/bacula/bin/bacula-sd"]
