## Based on: https://gitlab.com/csprenger/docker-qt-gcc

FROM ubuntu:rolling

ENV QT_PATH="/opt/qt"
ENV QT_TMP_PATH="/tmp/qt"
ENV PATH="${PATH}:${QT_PATH}/5.8/gcc_64/bin"

RUN apt-get update
RUN apt-get -qq install --no-install-recommends libgl1-mesa-dev libglib2.0-0 libpulse-dev g++ make git ca-certificates curl xvfb xauth libx11-xcb1 libfontconfig1 libdbus-1-3

RUN mkdir $QT_TMP_PATH
RUN curl -Lo ${QT_TMP_PATH}/installer.run https://download.qt.io/official_releases/online_installers/qt-unified-linux-x64-online.run
ADD qt-installer-script.qs ${QT_TMP_PATH}/qt-installer-script.qs
RUN chmod +x ${QT_TMP_PATH}/installer.run && QT_QPA_PLATFORM=minimal xvfb-run ${QT_TMP_PATH}/installer.run --script ${QT_TMP_PATH}/qt-installer-script.qs

RUN rm -rf ${QT_PATH}/Examples
RUN rm -rf ${QT_PATH}/Docs
RUN rm -rf ${QT_PATH}/Tools

ADD qt-make-test.sh ${QT_TMP_PATH}/qt-make-test.sh
RUN chmod +x ${QT_TMP_PATH}/qt-make-test.sh && ${QT_TMP_PATH}/qt-make-test.sh

RUN rm -rf /tmp/*
RUN rm -rf /var/lib/apt/lists/*

ADD qt-installer-update-script.qs ${QT_PATH}/qt-installer-update-script.qs
ADD qt-installer-update.sh ${QT_PATH}/qt-installer-update.sh
ADD qt-installer-modify-script.qs ${QT_PATH}/qt-installer-modify-script.qs
ADD qt-installer-modify.sh ${QT_PATH}/qt-installer-modify.sh

ENV BUILD_INSTALL_DIR="/tmp/qt-build/inst"
ADD qt-build.sh ${QT_PATH}/qt-build.sh
RUN chmod +x ${QT_PATH}/qt-build.sh
ENTRYPOINT ${QT_PATH}/qt-build.sh