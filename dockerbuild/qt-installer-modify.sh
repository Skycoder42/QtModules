#!/bin/sh

tmpFile=$(mktemp)

componentsAdd="var componentsAdd = ["
for component in $QT_COMPONENTS_ADD; do
	componentsAdd+="\"$component\","
done
componentsAdd="${componentsAdd%,}];"
echo $componentsAdd > $tmpFile

componentsRemove="var componentsRemove = ["
for component in $QT_COMPONENTS_REMOVE; do
	componentsRemove+="\"$component\","
done
componentsRemove="${componentsRemove%,}];"
echo $componentsRemove >> $tmpFile

cat ${QT_PATH}/qt-installer-modify-script.qs >> $tmpFile

QT_QPA_PLATFORM=minimal ${QT_PATH}/MaintenanceTool --script "$tmpFile"