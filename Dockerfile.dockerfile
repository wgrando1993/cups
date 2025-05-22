FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV CUPS_VERSION=2.4.12
ENV TZ "America/Sao_Paulo"
ENV USERNAME admin
ENV PASSWORD password

# 1) Instala dependências de build + runtime, incluindo CA para HTTPS
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    build-essential autoconf automake libtool pkg-config \
    libssl-dev libgnutls28-dev \
    zlib1g zlib1g-dev \
    libavahi-client-dev \
    printer-driver-all \
    printer-driver-cups-pdf \
    printer-driver-foo2zjs \
    foomatic-db-compressed-ppds \
    openprinting-ppds \
    libreoffice \
    libreoffice-common \
    libnss-mdns \
    hpijs-ppds \
    file \
    hp-ppd \
    hplip \
    dos2unix \
    cups cups-client cups-filters cups-browsed \
    curl avahi-daemon dbus \
    iputils-ping \
    vim \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN cd /opt && \
    wget https://github.com/OpenPrinting/cups/releases/download/v${CUPS_VERSION}/cups-${CUPS_VERSION}-source.tar.gz && \
    tar -xzf cups-${CUPS_VERSION}-source.tar.gz && \
    cd cups-${CUPS_VERSION} && \
    ./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --with-rcdir=/etc/init.d && \
    make -j$(nproc) && \
    make install && \
    cd / && rm -rf /opt/*

RUN sed -i 's/Listen localhost:631/Listen 0.0.0.0:631/' /etc/cups/cupsd.conf && \
 sed -i 's/Browsing Off/Browsing On/' /etc/cups/cupsd.conf && \
 sed -i 's/<Location \/>/<Location \/>\n  Allow All/' /etc/cups/cupsd.conf && \
 sed -i 's/<Location \/admin>/<Location \/admin>\n  Allow All\n  Require user @SYSTEM/' /etc/cups/cupsd.conf && \
 sed -i 's/<Location \/admin\/conf>/<Location \/admin\/conf>\n  Allow All/' /etc/cups/cupsd.conf && \
 echo "ServerAlias *" >> /etc/cups/cupsd.conf && \
 echo "DefaultEncryption Never" >> /etc/cups/cupsd.conf

RUN echo 'application/vnd.openxmlformats-officedocument.wordprocessingml.document docx' >> /etc/cups/raw.types && \
    echo 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet xlsx' >> /etc/cups/raw.types

RUN echo 'application/vnd.openxmlformats-officedocument.wordprocessingml.document application/pdf 100 doc2pdf' >> /etc/cups/raw.convs && \
    echo 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet application/pdf 100 doc2pdf' >> /etc/cups/raw.convs

RUN cp -a /etc/cups /etc/cups.default

# 4) Volumes para persistência de config, spool e logs
VOLUME ["/etc/cups", "/var/spool/cups", "/var/log/cups"]

# 5) Expõe a porta da interface web/admin do CUPS
EXPOSE 631 5353/udp

COPY doc2pdf.sh /usr/lib/cups/filter/doc2pdf
RUN dos2unix /usr/lib/cups/filter/doc2pdf \
    && chmod 755 /usr/lib/cups/filter/doc2pdf

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]