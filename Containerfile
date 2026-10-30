FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    coreutils \
    findutils \
    grep \
    sed \
    gawk \
    file \
    util-linux \
    bsdextrautils \
    binutils \
    xxd \
    less \
    nano \
    vim-tiny \
    tree \
    diffutils \
    patch \
    dos2unix \
    curl \
    wget \
    ca-certificates \
    git \
    rsync \
    tar \
    gzip \
    bzip2 \
    xz-utils \
    zip \
    unzip \
    p7zip-full \
    zstd \
    libimage-exiftool-perl \
    mediainfo \
    ffmpeg \
    jq \
    libxml2-utils \
    xmlstarlet \
    python3 \
    python3-pip \
    python3-venv \
    openssl \
    acl \
    attr \
    b3sum \
    rhash \
    openjdk-21-jre-headless \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Versions des outils de préservation
ARG DROID_VERSION=6.9.14
ARG TIKA_VERSION=4.2.0
ARG SIEGFRIED_VERSION=1.11.9
# ARG SIEGFRIED_DASH=${SIEGFRIED_VERSION//./-}
ARG SIEGFRIED_DASH=1-11-9
ARG JHOVE_VERSION=1.34
ARG VERAPDF_MAJOR_VERSION=1.30
ARG VERAPDF_VERSION=1.30.3
ARG PDFBOX_VERSION=3.0.8
ARG JPYLYZER_VERSION=2.2.1

# Répertoires des outils Java
RUN mkdir -p /opt/droid /opt/tika /opt/siegfried /opt/jhove /opt/verapdf

# DROID : identification des formats par signatures PRONOM
RUN wget -O /tmp/droid.zip \
      "https://github.com/digital-preservation/droid/releases/download/${DROID_VERSION}/droid-binary-${DROID_VERSION}-bin.zip" \
    && unzip -q /tmp/droid.zip -d /opt/droid \
    && rm /tmp/droid.zip \
    && find /opt/droid -type f -name 'droid.sh' \
       -exec chmod +x {} \;

# JHOVE : identification et validation de fichiers
WORKDIR /tmp
COPY params/jhove-install.xml .
RUN wget -O /tmp/jhove-installer.jar \
      "https://software.openpreservation.org/releases/jhove/jhove-${JHOVE_VERSION}.jar" \
    && java -jar jhove-installer.jar jhove-install.xml \
    && rm /tmp/jhove-installer.jar /tmp/jhove-install.xml

# VERAPDF : validation des fichiers PDF
WORKDIR /tmp
COPY params/verapdf-install.xml .
RUN wget -O /tmp/verapdf-installer.zip \
     https://software.verapdf.org/releases/${VERAPDF_MAJOR_VERSION}/verapdf-greenfield-${VERAPDF_VERSION}-installer.zip \
    && unzip -q verapdf-installer.zip \
    && java -jar ./verapdf-greenfield-${VERAPDF_VERSION}/verapdf-izpack-installer-${VERAPDF_VERSION}.jar verapdf-install.xml \
    && rm /tmp/verapdf-installer.zip /tmp/verapdf-install.xml \
    && rm -rf /tmp/verapdf-greenfield-${VERAPDF_VERSION}

# Apache Tika : détection, métadonnées et extraction de texte
RUN wget -O /tmp/tika.zip \
      "https://dlcdn.apache.org/tika/${TIKA_VERSION}/tika-app-${TIKA_VERSION}.zip" \
    && unzip -q /tmp/tika.zip -d /opt/tika \
    && ln -s /opt/tika/tika-app-${TIKA_VERSION}.jar /opt/tika/tika-app.jar \
    && rm /tmp/tika.zip

# Apache PDFBox : outils de manipulation des PDF
RUN mkdir -p /opt/pdfbox \
    && wget -O /opt/pdfbox/pdfbox-app-${PDFBOX_VERSION}.jar \
       "https://repo.maven.apache.org/maven2/org/apache/pdfbox/pdfbox-app/${PDFBOX_VERSION}/pdfbox-app-${PDFBOX_VERSION}.jar" \
    && printf '%s\n' \
       '#!/bin/sh' \
       'exec java -jar /opt/pdfbox/pdfbox-app-'${PDFBOX_VERSION}'.jar "$@"' \
       > /usr/local/bin/pdfbox \
    && chmod 755 /usr/local/bin/pdfbox

# Siegfried with the static builds
RUN wget -O /tmp/siegfried.zip \
      "https://github.com/richardlehane/siegfried/releases/download/v${SIEGFRIED_VERSION}/siegfried_${SIEGFRIED_DASH}_linux64_static.zip" \
    && unzip -q /tmp/siegfried.zip -d /opt/siegfried \
    && rm /tmp/siegfried.zip

# Commandes accessibles depuis le PATH
RUN ln -s /opt/tika/tika-app-${TIKA_VERSION}.jar /usr/local/bin/tika \
    && ln -s "$(find /opt/droid -type f -name 'droid.sh' -print -quit)" /usr/local/bin/droid

# Installation des schémas XSD
COPY xml/ /opt/xml-schemas/
ENV XML_CATALOG_FILES="/opt/xml-schemas/catalog.xml"

# Installation de BagIt et jpylyzet dans un environnement Python isolé
RUN python3 -m venv /opt/python-venv \
    && /opt/python-venv/bin/pip install --no-cache-dir bagit \
    && ln -s /opt/python-venv/bin/bagit.py /usr/local/bin/bagit \
    && /opt/python-venv/bin/pip install --no-cache-dir jpylyzer==${JPYLYZER_VERSION} \
    && ln -s /opt/python-venv/bin/jpylyzer /usr/local/bin/jpylyzer

# Installation de BagIt dans un environnement Python isolé
# RUN python3 -m venv /opt/bagit-venv \
#    && /opt/bagit-venv/bin/pip install --no-cache-dir bagit \
#    && ln -s /opt/bagit-venv/bin/bagit.py /usr/local/bin/bagit

# Installation de jpylyzer
# RUN python3 -m venv /opt/jpylyzer-venv \
#     && /opt/jpylyzer-venv/bin/pip install --no-cache-dir jpylyzer==2.2.1 \
#    && ln -s /opt/jpylyzer-venv/bin/jpylyzer /usr/local/bin/jpylyzer

ENV PATH="/usr/local/bin:/opt/siegfried:/opt/jhove:/opt/verapdf:/opt/bagit-venv/bin:${PATH}"

# Répertoire de travail et points de montage
RUN mkdir -p /mnt/input /mnt/output /work \
    && groupadd --gid 1000 analyst \
    && useradd --uid 1000 --gid 1000 \
       --create-home --shell /bin/bash analyst \
    && chown analyst:analyst /work /mnt/output

WORKDIR /work
COPY scripts /usr/local/bin/
RUN chmod 755 /usr/local/bin/*

# Les fichiers sources restent accessibles via /mnt/input.
# Le montage hôte déterminera les permissions effectives.
USER analyst

# Télécharger les signatures Siegfried pendant la construction
# RUN sf -home "/home/analyst/.local/share/siegfried" -update

CMD ["/bin/bash"]
