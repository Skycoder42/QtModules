FROM ubuntu:rolling

ADD build.sh /tmp/qt/build.sh
ADD qt-installer-script.qs /tmp/qt/qt-installer-script.qs
RUN /tmp/qt/build.sh

ADD qt-installer-update-script.qs /opt/qt/qt-installer-update-script.qs
ADD qt-installer-update.sh /opt/qt/qt-installer-update.sh
ADD qt-installer-modify-script.qs /opt/qt/qt-installer-modify-script.qs
ADD qt-installer-modify.sh /opt/qt/qt-installer-modify.sh
ADD qt-build.sh /opt/qt/qt-build.sh

ENV PATH="${PATH}:/opt/qt:/opt/qt/5.8/gcc_64/bin"
ENV BUILD_INSTALL_DIR="/tmp/qt-build/inst"
ENV QPM_PATH="."

CMD /opt/qt/qt-build.sh