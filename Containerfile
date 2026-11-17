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
    make \
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
    flac \
    mp3val \
    jq \
    fq \
    libxml2-utils \
    xmlstarlet \
    python3 \
    python3-pip \
    python3-venv \
    python3-lxml \
    openssl \
    acl \
    attr \
    b3sum \
    rhash \
    openjdk-21-jre-headless \
    unzip \
    gnuplot \
    pdftk-java \
    czkawka-cli \
    pandoc \
    libharfbuzz-subset0 \
    pkg-config \
    djvulibre-bin \
    libdjvulibre-dev \
    libdjvulibre-text \
    tesseract-ocr \
    tesseract-ocr-fra \
    libtiff-tools \
    && rm -rf /var/lib/apt/lists/*

#     ocrodjvu \

#    texlive \
#    librsvg2-bin \

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
ARG EPUBCHECK_VERSION=5.4.0
ARG JWAT_VERSION=0.7.1
ARG SIARD_VERSION=2.2.167

# Répertoires des outils Java
RUN mkdir -p /opt/droid /opt/tika /opt/siegfried /opt/jhove /opt/verapdf

# DROID : identification des formats par signatures PRONOM
RUN wget -O /tmp/droid.zip \
      "https://github.com/digital-preservation/droid/releases/download/${DROID_VERSION}/droid-binary-${DROID_VERSION}-bin.zip" \
    && unzip -q /tmp/droid.zip -d /opt/droid \
    && rm -f /tmp/droid.zip \
    && find /opt/droid -type f -name 'droid.sh' -exec chmod +x {} \; \
    && ln -s "$(find /opt/droid -type f -name 'droid.sh' -print -quit)" /usr/local/bin/droid

# JHOVE : identification et validation de fichiers
WORKDIR /tmp
COPY params/jhove-install.xml .
RUN wget -O /tmp/jhove-installer.jar \
      "https://software.openpreservation.org/releases/jhove/jhove-${JHOVE_VERSION}.jar" \
    && java -jar jhove-installer.jar jhove-install.xml \
    && rm -f /tmp/jhove-installer.jar /tmp/jhove-install.xml

# VERAPDF : validation des fichiers PDF
WORKDIR /tmp
COPY params/verapdf-install.xml .
RUN wget -O /tmp/verapdf-installer.zip \
     https://software.verapdf.org/releases/${VERAPDF_MAJOR_VERSION}/verapdf-greenfield-${VERAPDF_VERSION}-installer.zip \
    && unzip -q verapdf-installer.zip \
    && java -jar ./verapdf-greenfield-${VERAPDF_VERSION}/verapdf-izpack-installer-${VERAPDF_VERSION}.jar verapdf-install.xml \
    && rm -f /tmp/verapdf-installer.zip /tmp/verapdf-install.xml \
    && rm -rf /tmp/verapdf-greenfield-${VERAPDF_VERSION}

# Apache Tika : détection, métadonnées et extraction de texte
RUN wget -O /tmp/tika.zip \
      "https://dlcdn.apache.org/tika/${TIKA_VERSION}/tika-app-${TIKA_VERSION}.zip" \
    && unzip -q /tmp/tika.zip -d /opt/tika \
    && ln -s /opt/tika/tika-app-${TIKA_VERSION}.jar /opt/tika/tika-app.jar \
    && rm -f /tmp/tika.zip \
    && printf '%s\n' \
       '#!/bin/sh' \
       'cd /opt/tika' \
       'exec java -jar /opt/tika/tika-app.jar "$@"' \
       > /usr/local/bin/tika \
    && chmod 755 /usr/local/bin/tika

# Apache PDFBox : outils de manipulation des PDF
RUN mkdir -p /opt/pdfbox \
    && wget -O /opt/pdfbox/pdfbox-app-${PDFBOX_VERSION}.jar \
       "https://repo.maven.apache.org/maven2/org/apache/pdfbox/pdfbox-app/${PDFBOX_VERSION}/pdfbox-app-${PDFBOX_VERSION}.jar" \
    && printf '%s\n' \
       '#!/bin/sh' \
       'exec java -jar /opt/pdfbox/pdfbox-app-'${PDFBOX_VERSION}'.jar "$@"' \
       > /usr/local/bin/pdfbox \
    && chmod 755 /usr/local/bin/pdfbox

#Epubcheck : validation des epubcheck
RUN wget -O /tmp/epubcheck.zip \
      "https://github.com/w3c/epubcheck/releases/download/v${EPUBCHECK_VERSION}/epubcheck-${EPUBCHECK_VERSION}.zip" \
    && unzip -q /tmp/epubcheck.zip -d /opt \
    && ln -s /opt/epubcheck-${EPUBCHECK_VERSION} /opt/epubcheck \
    && rm -f /tmp/epubcheck.zip \
    && printf '%s\n' \
       '#!/bin/sh' \
       'cd /opt/epubcheck' \
       'exec java -jar /opt/epubcheck/epubcheck.jar "$@"' \
       > /usr/local/bin/epubcheck \
    && chmod 755 /usr/local/bin/epubcheck

#JWAT-tools : manipulation des WARC
RUN wget -O /tmp/jwattools.zip \
      "https://github.com/netarchivesuite/jwat-tools/releases/download/jwat-tools-${JWAT_VERSION}/jwat-tools-${JWAT_VERSION}.zip" \
    && unzip -q /tmp/jwattools.zip -d /opt \
    && ln -s /opt/jwat-tools-${JWAT_VERSION} /opt/jwattools \
    && rm -f /tmp/jwattools.zip \
    && printf '%s\n' \
       '#!/bin/sh' \
       'cd /opt/jwattools' \
       'exec java -Xms256m -Xmx1024m -cp "/opt/jwattools/lib/*" org.jwat.tools.JWATTools "$@"' \
       > /usr/local/bin/jwattools \
    && chmod 755 /usr/local/bin/jwattools

# SIARD Suite : archivage des SGBDR
RUN wget -O /tmp/siard-cmd.zip \
      "https://github.com/sfa-siard/siard-suite/releases/download/v${SIARD_VERSION}/SIARD-Suite-v${SIARD_VERSION}-siard-cmd.zip" \
    && unzip -q /tmp/siard-cmd -d /tmp \
    && unzip -q /tmp/siard-cmd-${SIARD_VERSION}.zip -d /opt \
    && ln -s /opt/siard-cmd-2.2.167 /opt/siard-cmd \
    && rm -f /tmp/siard-cmd*.zip /tmp/siard-cmd*.tar \
    && printf '%s\n' \
       '#!/bin/sh' \
       'cd /opt/siard-cmd' \
       'exec java -Xms256m -Xmx1024m -cp "/opt/siard-cmd/lib/*" ch.admin.bar.siard2.cmd.SiardFromDb "$@"' \
       > /usr/local/bin/siard \
    && chmod 755 /usr/local/bin/siard


# Siegfried with the static builds
RUN wget -O /tmp/siegfried.zip \
      "https://github.com/richardlehane/siegfried/releases/download/v${SIEGFRIED_VERSION}/siegfried_${SIEGFRIED_DASH}_linux64_static.zip" \
    && unzip -q /tmp/siegfried.zip -d /opt/siegfried \
    && rm /tmp/siegfried.zip

# Installation des schémas XSD
COPY xml/ /opt/xml-schemas/
ENV XML_CATALOG_FILES="/opt/xml-schemas/catalog.xml"

# Installations des programmes basés sur Python dans un environnement Python isolé
# BagIt, jpylyzer, eml2pdf, ocrdjvu
RUN python3 -m venv /opt/python-venv \
    && /opt/python-venv/bin/pip install --no-cache-dir bagit \
    && ln -s /opt/python-venv/bin/bagit.py /usr/local/bin/bagit \
    && /opt/python-venv/bin/pip install --no-cache-dir jpylyzer==${JPYLYZER_VERSION} \
    && ln -s /opt/python-venv/bin/jpylyzer /usr/local/bin/jpylyzer \
    && /opt/python-venv/bin/pip install --no-cache-dir eml2pdf \
    && ln -s /opt/python-venv/bin/eml2pdf /usr/local/bin/eml2pdf \
    && ln -s /opt/python-venv/bin/weasyprint /usr/local/bin/weasyprint
    
# RUN /opt/python-venv/bin/pip install --no-cache-dir djvulibre-python
#    && /opt/python-venv/bin/pip install --no-cache-dir ocrodjvu \
#    && ln -s /opt/python-venv/bin/ocrodjvu /usr/local/bin/ocrodjvu \

#    && cd /usr/lib \
#    && ln -s /lib/x86_64-linux-gnu/libdjvulibre.so.21 libdjvulibre.so.21 

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

# Message d'aide au démarrage de shells interactifs
RUN printf '\n\
#Preservation container welcome message\n\
if [[ $- == *i* ]] && [[ -x /usr/local/bin/help-container ]]; then\n\
    /usr/local/bin/help-container\n\
fi\n\
' >> /etc/bash.bashrc

# Les fichiers sources restent accessibles via /mnt/input.
# Le montage hôte déterminera les permissions effectives.
USER analyst

RUN mkdir -p /home/analyst/.local/share/pandoc/defaults
COPY params/readme.yaml /home/analyst/.local/share/pandoc/defaults/readme.yaml
COPY params/readme-style.css /home/analyst/.local/share/pandoc/readme-style.css

# Télécharger les signatures Siegfried pendant la construction
# RUN sf -home "/home/analyst/.local/share/siegfried" -update

CMD ["/bin/bash"]
