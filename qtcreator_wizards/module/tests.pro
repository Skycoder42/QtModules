TEMPLATE = subdirs

CONFIG += no_docs_target

SUBDIRS += auto

@if '%{UseQDoc}' === ''
docTarget.target = doxygen
QMAKE_EXTRA_TARGETS += docTarget
@endif
