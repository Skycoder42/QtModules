#!/bin/sh

DIR=`mktemp -d`
cd $DIR

gcc -v
echo
qmake -v

echo "#include <QCoreApplication>\n" \
     "#include <QDebug>\n" \
     "\n" \
     "int main(int argc, char *argv[])\n" \
     "{\n" \
     "    QCoreApplication a(argc, argv);\n" \
     "    qDebug() << a.arguments();\n" \
     "    return a.arguments().size() - 3;\n" \
     "}\n" \
     > test.cpp

echo "QT = core\n" \
     "TARGET = test\n" \
     "TEMPLATE = app\n" \
     "SOURCES += test.cpp\n" \
     > test.pro

qmake test.pro
make

./test baum 42

