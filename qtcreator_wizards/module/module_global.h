%{Cpp:LicenseTemplate}\
#ifndef %{GLOBGUARD}
#define %{GLOBGUARD}

#include <QtCore/qglobal.h>

#ifndef QT_STATIC
#  if defined(QT_BUILD_%{ModuleDefine}_LIB)
#    define Q_%{ModuleDefine}_EXPORT Q_DECL_EXPORT
#  else
#    define Q_%{ModuleDefine}_EXPORT Q_DECL_IMPORT
#  endif
#else
#  define Q_%{ModuleDefine}_EXPORT
#endif

#endif // %{GLOBGUARD}\
