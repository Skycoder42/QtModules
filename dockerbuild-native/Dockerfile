FROM ubuntu:rolling

RUN apt-get update
RUN apt-get -qq upgrade
RUN apt-get -qq install --no-install-recommends libqt5core5a libqt5concurrent5 libqt5network5 libqt5sql5 libqt5sql5-psql libqt5websockets5 libqt5xml5 qt5-qmake qtbase5-dev-tools build-essential git

ENV QT_SELECT=qt5

RUN qmake -v