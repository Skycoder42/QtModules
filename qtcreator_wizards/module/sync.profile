%modules = (
    "%{QtModuleName}" => "$basedir/src/%{ModuleBase}",
);

# Force generation of camel case headers for classes inside QtDataSync namespaces
$publicclassregexp = "%{QtModuleName}::.+";
