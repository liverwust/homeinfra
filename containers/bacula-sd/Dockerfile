FROM debian:bookworm

ENV BACULA_VERSION=13.0.4
# Set this environment variable from the calling shell
#ENV BACULA_CUSTOMER=overrideme

# These steps come from
# https://www.bacula.org/packages/${BACULA_CUSTOMER}/debs/${BACULA_VERSION}/dists/bookworm/main/binary-amd64/INSTALL

# In order to use the Bacula Systems apt repository, you need to install the
# HTTPS backend for APT.
RUN apt-get install apt-transport-https

# Then, you need to download and install the gpg signature that validates
# packages.
RUN wget https://bacula.org/downloads/Bacula-4096-Distribution-Verification-key.asc
RUN apt-key add Bacula-4096-Distribution-Verification-key.asc

# Add to your /etc/apt/sources.list file the following entries:
RUN echo deb https://www.bacula.org/packages/${BACULA_CUSTOMER}/debs/${BACULA_VERSION} \
    bookworm main > /etc/apt/sources.list.d/bacula.list

# Once done, you can update the repository list with the following command.
RUN apt-get update

# If you have not previously install the database server, do so with:
RUN apt-get install dbconfig-common postgresql

# Then install the Bacula with PostgreSQL driver with:
RUN apt-get install bacula-postgresql

CMD /bin/bash
