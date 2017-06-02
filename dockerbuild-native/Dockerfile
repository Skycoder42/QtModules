FROM ubuntu:latest

ADD build.sh /tmp/qt/build.sh
RUN chmod +x /tmp/qt/build.sh && /tmp/qt/build.sh

ADD qt-build.sh /opt/qt/qt-build.sh

ENV BUILD_INSTALL_DIR="/tmp/qt-build/inst"
ENV QPM_PATH="."

CMD /opt/qt/qt-build.sh