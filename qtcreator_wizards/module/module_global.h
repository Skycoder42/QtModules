%{Cpp:LicenseTemplate}\
#ifndef %{GLOBGUARD}
#define %{GLOBGUARD}

#include <QtCore/qglobal.h>

#if defined(QT_BUILD_%{ModuleDefine}_LIB)
#	define Q_%{ModuleDefine}_EXPORT Q_DECL_EXPORT
#else
#	define Q_%{ModuleDefine}_EXPORT Q_DECL_IMPORT
#endif

#endif // %{GLOBGUARD}\
