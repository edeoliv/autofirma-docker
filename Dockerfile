FROM debian:bookworm-slim AS autofirma_dl

RUN apt-get update && apt-get -y install curl unzip
RUN curl https://firmaelectronica.gob.es/content/dam/firmaelectronica/descargas-software/autofirma19/Autofirma_Linux_Debian.zip --output /tmp/autofirma.zip
RUN unzip /tmp/autofirma.zip autofirma_*.deb -d /tmp

FROM lscr.io/linuxserver/firefox:latest

# Install AutoFirma and desktop icon support for Labwc.
RUN apt-get update && apt-get -y install \
	openjdk-11-jdk \
	libnss3-tools \
	intel-media-va-driver-non-free \
	pcmanfm-qt && rm -rf /var/lib/apt/lists/*

# Copy AutoFirma from the previous stage.
COPY --from=autofirma_dl /tmp/autofirma_*.deb /tmp/

# Install deb even though we're on Alpine linux!
RUN dpkg -i /tmp/autofirma_*.deb

# Fix ugly java font rendering
RUN echo "export _JAVA_OPTIONS='-Dawt.useSystemAAFontSettings=gasp'" >> /etc/profile.d/jre.sh
RUN echo "export _JAVA_OPTIONS='-Dawt.useSystemAAFontSettings=gasp'" >> .bashrc
ENV _JAVA_OPTIONS="-Dawt.useSystemAAFontSettings=gasp"

# Autofirma configuration
COPY ./scripts/configure_autofirma.sh /usr/local/bin/configure_autofirma.sh
RUN /usr/local/bin/configure_autofirma.sh
RUN mkdir -p /etc/firefox/policies
COPY ./config/firefox/policies.json /etc/firefox/policies/policies.json

# Configure labwc and desktop icons
COPY ./config/labwc/autostart /defaults/autostart
COPY ./config/labwc/rc.xml /defaults/labwc.xml
RUN mkdir -p /defaults/Desktop
COPY ./config/desktop/autofirma.desktop /defaults/Desktop/
COPY ./config/desktop/firefox.desktop /defaults/Desktop/
ENV PIXELFLUX_WAYLAND=true

VOLUME /config/certificates

# Override the files copied by /init. Since it's run on the entrypoint, a build-time COPY won't work!
RUN echo "cp /defaults/autostart /config/.config/labwc/autostart" >> /init
RUN echo "cp /defaults/labwc.xml /config/.config/labwc/rc.xml" >> /init
RUN echo "cp /defaults/Desktop/* /config/Desktop/" >> /init
# RUN echo "bash /usr/local/bin/configure_firefox.sh" >> /init
