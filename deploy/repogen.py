#!/usr/bin/env python3
# $1 modules folder (e.g. "5.9")
# $2 Module Name (e.g. "MyModule" [results in "mymodule", "QtMyModule", "Qt My Module", etc])
# $3 comma seperate dependencies (e.g. "qt.58.examples, qt.tools.qtcreator")
# $4 tool names (comma seperated)
# $5 Description
# $6 Version
# $7 License file
# $8 License name
# $9 skip packages (comma seperated)

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
	<Dependencies>{}</Dependencies>
	<Version>{}</Version>
	<ReleaseDate>{}</ReleaseDate>
	<Licenses>
		<License name="{}" file="LICENSE.txt" />
	</Licenses>
	<Default>true</Default>
</Package>"""

docPkgXml = """<?xml version="1.0" encoding="UTF-8"?>
<Package>
	<Name>{}</Name>
	<DisplayName>{} Documentation</DisplayName>
	<Version>{}</Version>
	<ReleaseDate>{}</ReleaseDate>
	<Virtual>true</Virtual>
	<AutoDependOn>{}</AutoDependOn>
	<Dependencies>qt.tools</Dependencies>
	<Script>installscript.qs</Script>
</Package>"""

docPkgScript = """// constructor
function Component()
{{
}}

Component.prototype.createOperations = function()
{{
    component.createOperations();
    if (typeof registerQtCreatorDocumentation === "function")
    	registerQtCreatorDocumentation(component, "/Docs/Qt-{}/");
}}"""

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
depends = sys.argv[3]
tools = sys.argv[4].split(",")
if tools == [""]:
	tools = []
desc = sys.argv[5]
vers = sys.argv[6]
licenseFile = sys.argv[7]
licenseName = sys.argv[8]
skipPacks = sys.argv[9].split(",") if len(sys.argv) > 9 else []

qtDir = os.path.basename(baseDir)
modTitle = "Qt " + " ".join(re.findall(r"[A-Z][a-z0-9]*", modName))
modBase = modName.lower()
qtVers = qtDir.replace(".", "")
pkgBase = "qt.{}.skycoder42.{}".format(qtVers, modBase)

def createBasePkg():
	pkgBasePath = os.path.join("packages", pkgBase)
	pkgBaseMeta = os.path.join(pkgBasePath, "meta")
	pkgBaseData = os.path.join(pkgBasePath, "data")
	pkgBaseXml = os.path.join(pkgBaseMeta, "package.xml")
	pkgBaseLicense = os.path.join(pkgBaseMeta, "LICENSE.txt")

	print("Creating meta package", pkgBase)
	os.mkdir(pkgBasePath)
	os.mkdir(pkgBaseData)
	os.mkdir(pkgBaseMeta)

	pgkBaseXmlFile = open(pkgBaseXml, "w")
	pgkBaseXmlFile.write(fullPkgXml.format(pkgBase, modTitle, desc, depends, vers, datetime.date.today(), licenseName))
	pgkBaseXmlFile.close()

	shutil.copy(licenseFile, pkgBaseLicense)

def createDocPkg():
	docName = "Qt-{}".format(baseDir);
	baseDocDir = os.path.join(baseDir, docName)
	pkgDoc = pkgBase + ".doc"
	pkgDocPath = os.path.join("packages", pkgDoc)
	pkgDocMeta = os.path.join(pkgDocPath, "meta")
	pkgDocData = os.path.join(pkgDocPath, "data/Docs")
	pkgDocDataDoc = os.path.join(pkgDocData, docName)
	pkgDocXml = os.path.join(pkgDocMeta, "package.xml")
	pkgDocScript = os.path.join(pkgDocMeta, "installscript.qs")

	print("Creating documentation package", pkgDoc)
	os.mkdir(pkgDocPath)
	os.mkdir(pkgDocMeta)
	os.makedirs(pkgDocData)

	pgkDocXmlFile = open(pkgDocXml, "w")
	pgkDocXmlFile.write(docPkgXml.format(pkgDoc, modTitle, vers, datetime.date.today(), pkgBase))
	pgkDocXmlFile.close()

	pgkDocScriptFile = open(pkgDocScript, "w")
	pgkDocScriptFile.write(docPkgScript.format(baseDir))
	pgkDocScriptFile.close()

	shutil.copytree(baseDocDir, pkgDocDataDoc)

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

	print("Creating sub package", pkg)
	os.mkdir(pkgPath)
	os.mkdir(pkgMeta)
	os.makedirs(pkgData)

	pgkXmlFile = open(pkgXml, "w")
	pgkXmlFile.write(subPkgXml.format(pkg, modTitle, dirName, vers, datetime.date.today(), pkgBase, pkgKit, pkgKit))
	pgkXmlFile.close()

	pgkScriptFile = open(pkgScript, "w")
	pgkScriptFile.write(subPkgScript.format(pkgKit, pkgFolder, patchName))
	pgkScriptFile.close()

	shutil.copytree(baseDataDir, pkgDataKit, symlinks=True)

def prepareTools(masterPath, fixPkgs, suffix, doCopy):
	if len(tools) == 0:
		return

	for fixPkgInfo in fixPkgs:
		fixPkgName = fixPkgInfo[0];
		fixPkgDir = fixPkgInfo[1];
		if fixPkgName not in skipPacks:
			fixPkg = pkgBase + "." + fixPkgName
			fixPkgPath = os.path.join("packages", fixPkg, "data", qtDir, fixPkgDir)
			binPath = os.path.join(fixPkgPath, "bin")
			os.makedirs(binPath, exist_ok=True);
			for toolName in tools:
				tool = toolName + suffix
				toolBasePath = os.path.join(binPath, toolName)
				toolPath = os.path.join(binPath, tool)

				if os.path.lexists(toolBasePath):
					os.remove(toolBasePath)
				if os.path.lexists(toolPath):
					os.remove(toolPath)

				if doCopy:
					shutil.copy(os.path.join(baseDir, masterPath, "bin", tool), toolPath)
				else:
					os.symlink(os.path.join("../..", masterPath, "bin", tool), toolPath)

def repogen(archName, pkgList):
	repoPath = os.path.join("./repositories", archName)
	pkgFullList = [pkgBase, pkgBase + ".doc"]
	for pkgItem in pkgList:
		pkgFullList.append(pkgBase + "." + pkgItem)
	repoInc = ",".join(pkgFullList)

	if not os.path.exists(repoPath):
		print("WARNING: No existing repository found! It will be created as a new one, and not updated")

	subprocess.run(["repogen", "--update-new-components", "-p", "./packages", "-i", repoInc, repoPath])

# unpack packages
if os.path.exists("archives"):
	scriptDir = os.path.dirname(__file__)
	subprocess.run([os.path.join(scriptDir, "unpack.sh"), baseDir])

# create packages
shutil.rmtree("packages", ignore_errors=True)
os.mkdir("packages")
createBasePkg()
if "doc" not in skipPacks:
	createDocPkg()
if "android_armv7" not in skipPacks:
	createSubPkg("android_armv7", "android_armv7", "emb-arm-qt5")
if "android_x86" not in skipPacks:
	createSubPkg("android_x86", "android_x86", "emb-arm-qt5")
if "clang_64" not in skipPacks:
	createSubPkg("clang_64", "clang_64", "qt5")
if "gcc_64" not in skipPacks:
	createSubPkg("gcc_64", "gcc_64", "qt5")
if "ios" not in skipPacks:
	createSubPkg("ios", "ios", "emb-arm-qt5")
if "mingw53_32" not in skipPacks:
	createSubPkg("mingw53_32", "win32_mingw53", "qt5")
if "msvc2017_64" not in skipPacks:
	createSubPkg("msvc2017_64", "win64_msvc2017_64", "qt5")
if "winrt_x86_msvc2017" not in skipPacks:
	createSubPkg("winrt_x86_msvc2017", "win64_msvc2017_winrt_x86", "emb-arm-qt5")
if "winrt_x64_msvc2017" not in skipPacks:
	createSubPkg("winrt_x64_msvc2017", "win64_msvc2017_winrt_x64", "emb-arm-qt5")
if "winrt_armv7_msvc2017" not in skipPacks:
	createSubPkg("winrt_armv7_msvc2017", "win64_msvc2017_winrt_armv7", "emb-arm-qt5")
if "msvc2015_64" not in skipPacks:
	createSubPkg("msvc2015_64", "win64_msvc2015_64", "qt5")
if "msvc2015" not in skipPacks:
	createSubPkg("msvc2015", "win32_msvc2015", "qt5")

# build repositories
prepareTools("gcc_64", [
	["android_armv7", "android_armv7"],
	["android_x86", "android_x86"]
], "", False)
repogen("linux_x64", [
	"gcc_64",
	"android_armv7",
	"android_x86"
])

prepareTools("msvc2017_64", [
	["win64_msvc2017_winrt_x86", "winrt_x86_msvc2017"],
	["win64_msvc2017_winrt_x64", "winrt_x64_msvc2017"],
	["win64_msvc2017_winrt_armv7", "winrt_armv7_msvc2017"],
	["android_armv7", "android_armv7"],
	["android_x86", "android_x86"]
], ".exe", True)
repogen("windows_x86", [
	"win32_mingw53",
	"win64_msvc2017_64",
	"win64_msvc2017_winrt_x86",
	"win64_msvc2017_winrt_x64",
	"win64_msvc2017_winrt_armv7",
	"win64_msvc2015_64",
	"win32_msvc2015",
	"android_armv7",
	"android_x86"
])

prepareTools("clang_64", [
	["ios", "ios"],
	["android_armv7", "android_armv7"],
	["android_x86", "android_x86"]
], "", False)
repogen("mac_x64", [
	"clang_64",
	"ios",
	"android_armv7",
	"android_x86"
])