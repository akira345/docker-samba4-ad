# ubuntu
FROM ubuntu:24.04

# タイムゾーンをJSTにする。
RUN apt-get update && apt-get install -y wget tzdata && \
    ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

ENV SAMBA_VERSION samba-4.18.5

ENV DEBIAN_FRONTEND noninteractive

# Samba4インスト
RUN mkdir /usr/local/src/samba \
    && wget https://download.samba.org/pub/samba/stable/$SAMBA_VERSION.tar.gz \
    && tar xvzfp $SAMBA_VERSION.tar.gz -C /usr/local/src/samba \
    && rm $SAMBA_VERSION.tar.gz
RUN cd /usr/local/src/samba/$SAMBA_VERSION/bootstrap/generated-dists/ubuntu2204 \
    && ./bootstrap.sh \
    && cd ../../../ \
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
