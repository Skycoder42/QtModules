#!/usr/bin/python
# $1 modules folder (e.g. "5.8")
# $2 Module Name (e.g. "MyModule" [results in "mymodule", "QtMyModule", "Qt My Module", etc])
# $3 Description
# $4 Version
# $5 License file
# $6 License name

import sys
import os
import shutil
import re
import datetime
import subprocess

# constants
fullPkgXml = """<?xml version="1.0" encoding="UTF-8"?>
<Package>
	<Name>{}</Name>
	<DisplayName>{}</DisplayName>
	<Description>{}</Description>
	<Version>{}</Version>
	<ReleaseDate>{}</ReleaseDate>
	<Licenses>
		<License name="{}" file="LICENSE.txt" />
	</Licenses>
	<Default>true</Default>
</Package>"""

subPkgXml = """<?xml version="1.0" encoding="UTF-8"?>
<Package>
	<Name>{}</Name>
	<DisplayName>{} {}</DisplayName>
	<Version>{}</Version>
	<ReleaseDate>{}</ReleaseDate>
	<Virtual>true</Virtual>
	<AutoDependOn>{}, {}</AutoDependOn>
	<Dependencies>{}</Dependencies>
	<Script>installscript.qs</Script>
</Package>"""

subPkgScript = """// constructor
function Component()
{{
}}

function resolveQt5EssentialsDependency()
{{
    return "{}" + "_qmakeoutput";
}}

Component.prototype.createOperations = function()
{{
    component.createOperations();

    var platform = "";
    if (installer.value("os") == "x11") {{
        platform = "linux";
    }}
    if (installer.value("os") == "win") {{
        platform = "windows";
    }}
    if (installer.value("os") == "mac") {{
        platform = "mac";
    }}

    component.addOperation("QtPatch",
                            platform,
                            "@TargetDir@" + "{}",
                            "QmakeOutputInstallerKey=" + resolveQt5EssentialsDependency(),
                            "{}");
}}"""

#read args
baseDir = sys.argv[1]
modName = sys.argv[2]
desc = sys.argv[3]
vers = sys.argv[4]
licenseFile = sys.argv[5]
licenseName = sys.argv[6]

qtDir = os.path.basename(baseDir)
modTitle = "Qt " + " ".join(re.findall(r"[A-Z][a-z0-9]*", modName))
modBase = modName.lower()
qtVers = qtDir.replace(".", "")
pkgBase = "qt.{}.skycoder42.{}".format(qtVers, modBase)

def createSubPkg(dirName, pkgName, patchName):	
	baseDataDir = os.path.join(baseDir, dirName)
	pkg = pkgBase + "." + pkgName
	pkgKit = "qt.{}.{}".format(qtVers, pkgName)
	pkgFolder = "/{}/{}/".format(qtDir, dirName)
	pkgPath = os.path.join("packages", pkg)
	pkgMeta = os.path.join(pkgPath, "meta")
	pkgData = os.path.join(pkgPath, "data", qtDir)
	pkgDataKit = os.path.join(pkgData, dirName)
	pkgXml = os.path.join(pkgMeta, "package.xml")
	pkgScript = os.path.join(pkgMeta, "installscript.qs")
	
	print(" Creating sub package", pkg)
	os.mkdir(pkgPath)
	os.mkdir(pkgMeta)
	os.makedirs(pkgData)
	
	pgkXmlFile = open(pkgXml, "w")
	pgkXmlFile.write(subPkgXml.format(pkg, modTitle, dirName, vers, datetime.date.today(), pkgBase, pkgKit, pkgKit))
	pgkXmlFile.close()	
	
	pgkScriptFile = open(pkgScript, "w")
	pgkScriptFile.write(subPkgScript.format(pkgKit, pkgFolder, patchName))
	pgkScriptFile.close()
	
	shutil.copytree(baseDataDir, pkgDataKit)

def repogen(archName, pkgList):
	repoPath = os.path.join("./repositories", archName)
	pkgFullList = [pkgBase]
	for pkgItem in pkgList:
		pkgFullList.append(pkgBase + "." + pkgItem)
	repoInc = ",".join(pkgFullList)
	
	print("Building repository for", archName)
	if not os.path.exists(repoPath):
		print("WARNING: No existing repository found! It will be created as a new one, and not updated")
		
	subprocess.run(["repogen", "--update-new-components", "-p", "./packages", "-i", repoInc, repoPath])

# create packages
shutil.rmtree("packages", ignore_errors=True)
os.mkdir("packages")

# meta package
pkgBasePath = os.path.join("packages", pkgBase)
pkgBaseMeta = os.path.join(pkgBasePath, "meta")
pkgBaseData = os.path.join(pkgBasePath, "data")
pkgBaseXml = os.path.join(pkgBaseMeta, "package.xml")
pkgBaseLicense = os.path.join(pkgBaseMeta, "LICENSE.txt")

print("Creating base package", pkgBase)
os.mkdir(pkgBasePath)
os.mkdir(pkgBaseData)
os.mkdir(pkgBaseMeta)

pgkBaseXmlFile = open(pkgBaseXml, "w")
pgkBaseXmlFile.write(fullPkgXml.format(pkgBase, modTitle, desc, vers, datetime.date.today(), licenseName))
pgkBaseXmlFile.close()

shutil.copy(licenseFile, pkgBaseLicense)

# sub packages
createSubPkg("android_armv7", "android_armv7", "emb-arm-qt5")
createSubPkg("android_x86", "android_x86", "emb-arm-qt5")
createSubPkg("clang_64", "clang_64", "qt5")
createSubPkg("gcc_64", "gcc_64", "qt5")
createSubPkg("ios", "ios", "emb-arm-qt5")
createSubPkg("mingw53_32", "win32_mingw53", "qt5")
createSubPkg("msvc2015", "win32_msvc2015", "qt5")
createSubPkg("msvc2015_64", "win64_msvc2015_64", "qt5")
createSubPkg("winrt_armv7_msvc2015", "win64_msvc2015_winrt_armv7", "emb-arm-qt5")
createSubPkg("winrt_x64_msvc2015", "win64_msvc2015_winrt_x64", "emb-arm-qt5")

# build repositories
repogen("linux_x64", ["gcc_64", "android_armv7", "android_x86"])
repogen("windows_x86", ["win32_mingw53", "win32_msvc2015", "win64_msvc2015_64", "win64_msvc2015_winrt_armv7", "win64_msvc2015_winrt_x64", "android_armv7", "android_x86"])
repogen("mac_x64", ["clang_64", "ios", "android_armv7", "android_x86"])
