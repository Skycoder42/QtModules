FROM ubuntu:rolling

RUN apt-get update && apt-get -qq upgrade
RUN apt-get -qq install --no-install-recommends ca-certificates qtbase5-dev libqt5sql5-psql libqt5websockets5 qt5-qmake qtbase5-dev-tools build-essential git

ENV QT_SELECT=qt5

ADD qt-make-test.sh /tmp/qt/qt-make-test.sh
RUN chmod +x /tmp/qt/qt-make-test.sh && /tmp/qt/qt-make-test.sh

RUN rm -rf /tmp/*
RUN rm -rf /var/lib/apt/lists/*

ENV BUILD_INSTALL_DIR="/tmp/qt-build/inst"
ADD qt-build.sh /root/qt-build.sh
RUN chmod +x /root/qt-build.sh
ENTRYPOINT /root/qt-build.sh