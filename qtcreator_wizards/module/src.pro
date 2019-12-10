TEMPLATE = subdirs

SUBDIRS += %{ModuleBase}
@if '%{Translations}' !== ''
SUBDIRS += translations
@endif

QMAKE_EXTRA_TARGETS += run-tests
