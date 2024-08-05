# First stage: Build the application
FROM gradle:8.9.0-jdk21 AS build

# Set the working directory
WORKDIR /app

# Copy the Gradle project files and source code
COPY ./build.gradle  /app/
COPY ./settings.gradle /app/
COPY ./src /app/src

# Run the build
RUN gradle build

# Main stage
FROM alpine:3.20.0

# Copy necessary files from the build stage
COPY --from=build /app/build/libs/*.jar /app.jar
COPY ./scripts /scripts
COPY ./pipeline /pipeline
COPY ./src/main/resources/static/fonts/*.ttf /usr/share/fonts/opentype/noto/

ARG VERSION_TAG

# Set Environment Variables
ENV DOCKER_ENABLE_SECURITY=false \
        VERSION_TAG=$VERSION_TAG \
        JAVA_TOOL_OPTIONS="$JAVA_TOOL_OPTIONS -XX:MaxRAMPercentage=75" \
        HOME=/home/stirlingpdfuser \
        PUID=1000 \
        PGID=1000 \
        UMASK=022

# Install necessary packages
RUN echo "@testing https://dl-cdn.alpinelinux.org/alpine/edge/main" | tee -a /etc/apk/repositories && \
        echo "@testing https://dl-cdn.alpinelinux.org/alpine/edge/community" | tee -a /etc/apk/repositories && \
        echo "@testing https://dl-cdn.alpinelinux.org/alpine/edge/testing" | tee -a /etc/apk/repositories && \
        apk upgrade --no-cache -a && \
        apk add --no-cache \
        ca-certificates \
        tzdata \
        tini \
        bash \
        curl \
        shadow \
        su-exec \
        openssl \
        openssl-dev \
        openjdk21-jre \
        # Doc conversion
        libreoffice \
        # pdftohtml
        poppler-utils \
        # OCR MY PDF (unpaper for descew and other advanced features)
        ocrmypdf \
        tesseract-ocr-data-eng \
        # CV
        py3-opencv \
        # python3/pip
        python3 \
        py3-pip && \
        python3 -m venv /opt/venv && \
        . /opt/venv/bin/activate && \
        pip install --no-cache-dir --upgrade pip setuptools wheel && \
        pip install --no-cache-dir unoconv WeasyPrint && \
        mv /usr/share/tessdata /usr/share/tessdata-original && \
        mkdir -p $HOME /configs /logs /customFiles /pipeline/watchedFolders /pipeline/finishedFolders && \
        fc-cache -f -v && \
        chmod +x /scripts/* && \
        chmod +x /scripts/init.sh && \
        # User permissions
        addgroup -S stirlingpdfgroup && adduser -S stirlingpdfuser -G stirlingpdfgroup && \
        chown -R stirlingpdfuser:stirlingpdfgroup $HOME /scripts /usr/share/fonts/opentype/noto /configs /customFiles /pipeline && \
        chown stirlingpdfuser:stirlingpdfgroup /app.jar && \
        tesseract --list-langs

# Set the PATH to include the virtual environment
ENV PATH="/opt/venv/bin:$PATH"

EXPOSE 8080/tcp

# Set user and run command
ENTRYPOINT ["tini", "--", "/scripts/init.sh"]
CMD ["java", "-Dfile.encoding=UTF-8", "-jar", "/app.jar"]
