# debian
FROM debian:11

# タイムゾーンをJSTにする。
RUN apt-get install -y tzdata && \
    ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

ENV SAMBA_VERSION samba-4.15.3

ENV DEBIAN_FRONTEND noninteractive

# Samba4インスト
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get -y install acl attr autoconf bison build-essential \
       debhelper dnsutils docbook-xml docbook-xsl flex gdb krb5-user \
       libacl1-dev libaio-dev libattr1-dev libblkid-dev libbsd-dev \
       libcap-dev libcups2-dev libgnutls28-dev libjson-perl wget \
       libldap2-dev libncurses5-dev libpam0g-dev libparse-yapp-perl \
       libpopt-dev libreadline-dev perl perl-modules pkg-config \
       python-all-dev python-dev libdbus-1-dev python3-markdown \
       xsltproc zlib1g-dev libjansson-dev python3-distutils git \
       libpython3-dev liblmdb-dev  pkg-config libgnutls28-dev python3-dns python3-dnspython \
       libarchive-dev libacl1-dev libldap2-dev libpam0g-dev libgpgme11-dev \
    && rm -rf /var/lib/apt/lists/* 
RUN mkdir /usr/local/src/samba \
    && wget https://download.samba.org/pub/samba/stable/$SAMBA_VERSION.tar.gz \
    && tar xvzfp $SAMBA_VERSION.tar.gz -C /usr/local/src/samba \
    && rm $SAMBA_VERSION.tar.gz
RUN cd /usr/local/src/samba/$SAMBA_VERSION \
    && ./configure --with-utmp --with-ads \
    && make \
    && make install
RUN mkdir /usr/local/samba/external

# Expose ports
EXPOSE 37/udp \
       53 \
       88 \
       135/tcp \
       137/udp \
       138/udp \
       139 \
       389 \
       445 \
       464 \
       636/tcp \
       1024-5000/tcp \
       3268/tcp \
       3269/tcp

# Set up script and run
COPY init.sh /init.sh
RUN chmod +x /init.sh
ENTRYPOINT ["/init.sh"]
CMD ["/usr/local/samba/sbin/samba","-i","-M","prefork"]
