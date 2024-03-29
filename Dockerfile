FROM alpine:3.15.0 as build

ENV LC_ALL fr_FR.UTF-8

RUN apk add --no-cache libfixposix ncurses-terminfo busybox-extras

# Here we install GNU libc (aka glibc) and set C.UTF-8 locale as default.

RUN ALPINE_GLIBC_BASE_URL="https://github.com/sgerrand/alpine-pkg-glibc/releases/download" && \
    ALPINE_GLIBC_PACKAGE_VERSION="2.33-r0" && \
    ALPINE_GLIBC_BASE_PACKAGE_FILENAME="glibc-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_BIN_PACKAGE_FILENAME="glibc-bin-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_I18N_PACKAGE_FILENAME="glibc-i18n-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    apk add --no-cache --virtual=.build-dependencies ca-certificates && \
    echo \
        "-----BEGIN PUBLIC KEY-----\
        MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEApZ2u1KJKUu/fW4A25y9m\
        y70AGEa/J3Wi5ibNVGNn1gT1r0VfgeWd0pUybS4UmcHdiNzxJPgoWQhV2SSW1JYu\
        tOqKZF5QSN6X937PTUpNBjUvLtTQ1ve1fp39uf/lEXPpFpOPL88LKnDBgbh7wkCp\
        m2KzLVGChf83MS0ShL6G9EQIAUxLm99VpgRjwqTQ/KfzGtpke1wqws4au0Ab4qPY\
        KXvMLSPLUp7cfulWvhmZSegr5AdhNw5KNizPqCJT8ZrGvgHypXyiFvvAH5YRtSsc\
        Zvo9GI2e2MaZyo9/lvb+LbLEJZKEQckqRj4P26gmASrZEPStwc+yqy1ShHLA0j6m\
        1QIDAQAB\
        -----END PUBLIC KEY-----" | sed 's/   */\n/g' > "/etc/apk/keys/sgerrand.rsa.pub" && \
    busybox wget \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    apk add --no-cache \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    \
    rm "/etc/apk/keys/sgerrand.rsa.pub" && \
    /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 "$LANG" || true && \
    echo "export LANG=$LANG" > /etc/profile.d/locale.sh && \
    \
    apk del glibc-i18n && \
    apk del .build-dependencies && \
    rm \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME"

RUN CCL_VERSION="1.11.5" && \
    ARCH="linuxx86" && \
    FILENAME="ccl-$CCL_VERSION-$ARCH.tar.gz" && \
    DOWNLOAD_URL="https://github.com/Clozure/ccl/releases/download/v$CCL_VERSION/$FILENAME" && \
    busybox wget "$DOWNLOAD_URL" && \
    tar zxf $FILENAME && \
    mkdir /opt/ccl && \
    cp -r ccl/lx86cl64* ccl/x86-headers64 /opt/ccl && \
    ln -s /opt/ccl/lx86cl64 /usr/local/bin/ccl && \
    rm -rf ccl $FILENAME

RUN FILENAME="quicklisp.lisp" && \
    DOWNLOAD_URL="http://beta.quicklisp.org/$FILENAME" && \
    busybox wget "$DOWNLOAD_URL" && \
    ccl --load quicklisp.lisp \
        --eval '(quicklisp-quickstart:install)' \
        --eval '(quit)' && \
    echo \
        ";;; The following lines added by ql:add-to-init-file:\
        #-quicklisp\
        (let ((quicklisp-init (merge-pathnames \"quicklisp/setup.lisp\" (user-homedir-pathname))))\
        (when (probe-file quicklisp-init)\
            (load quicklisp-init)))" | sed 's/   */\n/g' >/root/.ccl-init.lisp && \
    rm $FILENAME

RUN NASIUM_LSE_TAG="nasium-lse--202202-1" && \
    FILENAME="$NASIUM_LSE_TAG.tar.gz" && \
    DOWNLOAD_URL="https://framagit.org/nasium-lse/nasium-lse/-/archive/$NASIUM_LSE_TAG/$FILENAME" && \
    busybox wget "$DOWNLOAD_URL" && \
    apk add --no-cache --virtual=.build-dependencies g++ make linux-headers libfixposix-dev git && \
    tar zxf $FILENAME && \
    rm $FILENAME && \
    ln -s nasium-lse-"$NASIUM_LSE_TAG"* nasium-lse && \
    cd nasium-lse && \
    NASIUM_LSE="$(pwd)" && \
    cd "${NASIUM_LSE}/dependencies/" && \
    git clone https://github.com/sionescu/libfixposix.git && \
    git clone https://framagit.org/com-informatimago/com-informatimago.git && \
    git clone https://github.com/marsijanin/iolib.termios.git && \
    sed -i 's/iolib\/base/iolib.base/' iolib.termios/iolib.termios.asd && \
    cd "${NASIUM_LSE}/src/" && \
    make cli && \
    apk del .build-dependencies


FROM alpine:3.15.0

ENV LC_ALL fr_FR.UTF-8

RUN apk add --no-cache libfixposix ncurses-terminfo busybox-extras

# Here we install GNU libc (aka glibc) and set C.UTF-8 locale as default.

RUN ALPINE_GLIBC_BASE_URL="https://github.com/sgerrand/alpine-pkg-glibc/releases/download" && \
    ALPINE_GLIBC_PACKAGE_VERSION="2.33-r0" && \
    ALPINE_GLIBC_BASE_PACKAGE_FILENAME="glibc-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_BIN_PACKAGE_FILENAME="glibc-bin-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_I18N_PACKAGE_FILENAME="glibc-i18n-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    apk add --no-cache --virtual=.build-dependencies ca-certificates && \
    echo \
        "-----BEGIN PUBLIC KEY-----\
        MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEApZ2u1KJKUu/fW4A25y9m\
        y70AGEa/J3Wi5ibNVGNn1gT1r0VfgeWd0pUybS4UmcHdiNzxJPgoWQhV2SSW1JYu\
        tOqKZF5QSN6X937PTUpNBjUvLtTQ1ve1fp39uf/lEXPpFpOPL88LKnDBgbh7wkCp\
        m2KzLVGChf83MS0ShL6G9EQIAUxLm99VpgRjwqTQ/KfzGtpke1wqws4au0Ab4qPY\
        KXvMLSPLUp7cfulWvhmZSegr5AdhNw5KNizPqCJT8ZrGvgHypXyiFvvAH5YRtSsc\
        Zvo9GI2e2MaZyo9/lvb+LbLEJZKEQckqRj4P26gmASrZEPStwc+yqy1ShHLA0j6m\
        1QIDAQAB\
        -----END PUBLIC KEY-----" | sed 's/   */\n/g' > "/etc/apk/keys/sgerrand.rsa.pub" && \
    busybox wget \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    apk add --no-cache \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    \
    rm "/etc/apk/keys/sgerrand.rsa.pub" && \
    /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 "$LANG" || true && \
    echo "export LANG=$LANG" > /etc/profile.d/locale.sh && \
    \
    apk del glibc-i18n && \
    apk del .build-dependencies && \
    rm \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME"

COPY --from=build /nasium-lse/src/lse /srv/lse/bin/
COPY --from=build /nasium-lse/servers/lse-inetd.sh /srv/lse/scripts/
COPY --from=build /nasium-lse/servers/inetd.conf /etc/
COPY run.sh /
RUN sed -i 's/lse/root/' /etc/inetd.conf && \
    chmod +x run.sh && \
    mkdir -p /srv/lse/files
CMD ["/run.sh"]