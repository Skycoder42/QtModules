#!/usr/bin/env python3
# $1 repo id
# $2 Version
# $3 Qt Version (e.g. "5.10.0")
import datetime
import io
import json
import os
import zipfile

import requests
import shutil
import subprocess
import sys
import tarfile
import tempfile

from os.path import join as pjoin


pkg_base_xml = """<?xml version="1.0" encoding="UTF-8"?>
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

pkg_src_xml = """<?xml version="1.0" encoding="UTF-8"?>
<Package>
	<Name>{}</Name>
	<DisplayName>{} Sources</DisplayName>
	<Version>{}</Version>
	<ReleaseDate>{}</ReleaseDate>
	<Virtual>true</Virtual>
	<AutoDependOn>{}, {}</AutoDependOn>
	<Dependencies>{}</Dependencies>
</Package>"""

pkg_doc_xml = """<?xml version="1.0" encoding="UTF-8"?>
<Package>
	<Name>{}</Name>
	<DisplayName>{} Documentation</DisplayName>
	<Version>{}</Version>
	<ReleaseDate>{}</ReleaseDate>
	<Virtual>true</Virtual>
	<AutoDependOn>{}, {}</AutoDependOn>
	<Dependencies>{}, qt.tools</Dependencies>
	<Script>installscript.qs</Script>
</Package>"""

pkg_doc_qs = """// constructor
function Component()
{{
}}

Component.prototype.createOperations = function()
{{
    component.createOperations();
    if (typeof registerQtCreatorDocumentation === "function")
    	registerQtCreatorDocumentation(component, "/Docs/Qt-{}/");
}}"""

pkg_arch_xml = """<?xml version="1.0" encoding="UTF-8"?>
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

pkg_arch_qs = """// constructor
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
    if (installer.value("os") == "x11")
        platform = "linux";
    if (installer.value("os") == "win")
        platform = "windows";
    if (installer.value("os") == "mac")
        platform = "mac";

    component.addOperation("QtPatch",
                            platform,
                            "@TargetDir@" + "/{}/{}",
                            "QmakeOutputInstallerKey=" + resolveQt5EssentialsDependency(),
                            "{}");
}}"""


def cfg_if(config, key, default=None):
	return config[key] if key in config else default


def qt_vid(qt_version):
	return qt_version.replace(".", "")


def url_extract(sdir, url, as_zip=False):
	sources_req = requests.get(url)
	if as_zip:
		with zipfile.ZipFile(io.BytesIO(sources_req.content)) as archive:
			archive.extractall(sdir)
	else:
		with tarfile.open(fileobj=io.BytesIO(sources_req.content)) as archive:
			archive.extractall(sdir)


def prepare_sources(sdir, repo, mod_name, vers):
	print("Downloading an preparing sources")
	# download sources
	mod_url = "https://github.com/" + repo + "/archive/" + vers + ".tar.gz"
	out_dir = pjoin(sdir, "Src", mod_name.lower())
	url_extract(sdir, mod_url)
	shutil.move(pjoin(sdir, mod_name + "-" + vers), out_dir)

	# prepare sources
	os.remove(pjoin(out_dir, ".travis.yml"))
	os.remove(pjoin(out_dir, "appveyor.yml"))
	# DEBUG shutil.move(pjoin(out_dir, "deploy.json"), pjoin(sdir, "deploy.json"))
	shutil.copy2("/home/sky/Programming/QtLibraries/QtDataSync/deploy.json", pjoin(sdir, "deploy.json"))

	return out_dir


def prepare_headers(tdir, mdir, mods, version):
	syncqt_req = requests.get("https://code.qt.io/cgit/qt/qtbase.git/plain/bin/syncqt.pl")
	syncqt_pl = pjoin(tdir, "syncqt.pl")
	with open(syncqt_pl, "wb") as file:
		file.write(syncqt_req.content)
	os.chmod(syncqt_pl, 0o755)
	for mod in mods:
		subprocess.run([
			syncqt_pl,
			"-module", mod,
			"-version", version,
			"-outdir", mdir,
			mdir
		], check=True)


def get_binary_imp(sdir, repo, vers, qt_vers, excludes, arch, as_zip):
	for exclude in excludes:
		if exclude in arch:
			return False

	bin_url="https://github.com/" + repo + "/releases/download/" + vers + "/build_" + arch + "_" + qt_vers
	if as_zip:
		bin_url += ".zip"
	else:
		bin_url += ".tar.xz"
	print("Downloading and extracting " + arch)
	url_extract(sdir, bin_url, as_zip)
	return True


def get_binaries(sdir, repo, vers, qt_vers, excludes):
	use_arch = []
	for arch in ["android_armv7", "android_x86", "clang_64", "doc", "gcc_64", "ios", "static_linux", "static_osx"]:
		if get_binary_imp(sdir, repo, vers, qt_vers, excludes, arch, False):
			use_arch.append(arch)
	for arch in ["mingw53_32", "msvc2015", "msvc2015_64", "msvc2017_64", "winrt_armv7_msvc2017", "winrt_x64_msvc2017", "winrt_x86_msvc2017", "static_win"]:
		if get_binary_imp(sdir, repo, vers, qt_vers, excludes, arch, True):
			use_arch.append(arch)
	return use_arch


def pkg_meta(pdir):
	return pjoin(pdir, "meta")


def pkg_data(pdir):
	return pjoin(pdir, "data")


def pkg_prepare(rdir, pkg_base):
	pkg_dir = pjoin(rdir, pkg_base)
	os.mkdir(pkg_dir)
	return pkg_dir


def pkg_add_package_xml(pdir, template, *format_args):
	meta_dir = pkg_meta(pdir)
	os.makedirs(meta_dir, exist_ok=True)
	with open(pjoin(meta_dir, "package.xml"), "w") as file:
		file.write(template.format(*format_args))


def pkg_add_script(pdir, template, *format_args):
	meta_dir = pkg_meta(pdir)
	os.makedirs(meta_dir, exist_ok=True)
	with open(pjoin(meta_dir, "installscript.qs"), "w") as file:
		file.write(template.format(*format_args))


def pkg_copy_data(pdir, sdir, arch, qt_version):
	src_dir = pjoin(sdir, arch)
	target_dir = pjoin(pkg_data(pdir), qt_version, arch)
	shutil.copytree(src_dir, target_dir, symlinks=True)


def create_base_pkg(rdir, msdir, pkg_base, config, version, qt_version):
	print("Creating meta package")
	pkg_dir = pkg_prepare(rdir, pkg_base)

	depends = []
	for dep in config["dependencies"]:
		if dep[0] == ".":
			depends.append("qt.qt5.{}".format(qt_vid(qt_version)) + dep)
		else:
			depends.append(dep)

	pkg_add_package_xml(pkg_dir, pkg_base_xml,
						pkg_base,
						config["title"],
						config["description"],
						", ".join(depends),
						version,
						datetime.date.today(),
						config["license"]["name"])

	shutil.copy2(pjoin(msdir, config["license"]["path"]),
				 pjoin(pkg_meta(pkg_dir), "LICENSE.txt"))


def create_src_pkg(rdir, sdir, pkg_base, config, version, qt_version):
	print("Creating source package")
	pkg_src = pkg_base + ".src"
	pkg_dir = pkg_prepare(rdir, pkg_src)

	pkg_qt_src = "qt.qt5.{}.src".format(qt_vid(qt_version))
	pkg_add_package_xml(pkg_dir, pkg_src_xml,
						pkg_base,
						config["title"],
						version,
						datetime.date.today(),
						pkg_base,
						pkg_qt_src,
						pkg_qt_src)

	pkg_copy_data(pkg_dir, sdir, "Src", qt_version)


def create_doc_pkg(rdir, sdir, pkg_base, config, version, qt_version):
	print("Creating doc package")
	pkg_doc = pkg_base + ".doc"
	pkg_dir = pkg_prepare(rdir, pkg_doc)

	pkg_qt_doc = "qt.qt5.{}.doc".format(qt_vid(qt_version))
	pkg_add_package_xml(pkg_dir, pkg_doc_xml,
						pkg_base,
						config["title"],
						version,
						datetime.date.today(),
						pkg_base,
						pkg_qt_doc,
						pkg_qt_doc)
	pkg_add_script(pkg_dir, pkg_doc_qs, qt_version)

	shutil.copytree(pjoin(sdir, "Qt-" + qt_version),
					pjoin(pkg_data(pkg_dir), "Doc", "Qt-" + qt_version),
					symlinks=True)


def create_arch_pkg(rdir, sdir, pkg_base, arch, config, version, qt_version):
	embedded_keys = [
		"android_armv7",
		"android_x86",
		"ios",
		"winrt_x86_msvc2017",
		"winrt_x64_msvc2017",
		"winrt_armv7_msvc2017"
	]

	print("Creating " + arch + " package")
	pkg_arch = pkg_base + "." + arch
	pkg_dir = pkg_prepare(rdir, pkg_arch)

	pkg_qt_arch = "qt.qt5.{}.{}".format(qt_vid(qt_version), arch)
	pkg_add_package_xml(pkg_dir, pkg_arch_xml,
						pkg_base,
						config["title"],
						arch,
						version,
						datetime.date.today(),
						pkg_base,
						pkg_qt_arch,
						pkg_qt_arch)
	pkg_add_script(pkg_dir, pkg_arch_qs,
				   pkg_qt_arch,
				   qt_version,
				   arch,
				   "emb-arm-qt5" if arch in embedded_keys else "qt5")

	pkg_copy_data(pkg_dir, sdir, arch, qt_version)


def repogen(repo_id, version, qt_version):
	user = repo_id.split("/")[0]
	mod_name = repo_id.split("/")[1]
	mod_title = mod_name[2:]

	with tempfile.TemporaryDirectory() as tmp_dir:
		#debug
		tmp_dir = "/tmp/repogen"
		shutil.rmtree(tmp_dir, ignore_errors=True)
		os.mkdir(tmp_dir)

		# general
		src_dir = pjoin(tmp_dir, "src")
		os.mkdir(src_dir)

		# step 1: download and prepare sources, download binaries
		mod_src_dir = prepare_sources(src_dir, repo_id, mod_name, version)
		with open(pjoin(src_dir, "deploy.json")) as file:
			config = json.load(file)
		prepare_headers(src_dir, mod_src_dir, cfg_if(config, "modules", mod_name), version)
		use_arch = get_binaries(src_dir, repo_id, version, qt_version, cfg_if(config, "excludes", []))

		# step 2: create the repositories
		rep_dir = pjoin(tmp_dir, "repos")
		os.mkdir(rep_dir)
		pkg_base = "qt.qt5.{}.{}.{}".format(qt_vid(qt_version), user.lower(), mod_title.lower())
		create_base_pkg(rep_dir, mod_src_dir, pkg_base, config, version, qt_version)
		if "Src" not in config["excludes"]:
			create_src_pkg(rep_dir, src_dir, pkg_base, config, version, qt_version)
		for arch in use_arch:
			if arch == "doc":
				create_doc_pkg(rep_dir, src_dir, pkg_base, config, version, qt_version)
			else:
				create_arch_pkg(rep_dir, src_dir, pkg_base, arch, config, version, qt_version)


if __name__ == '__main__':
	repogen(*sys.argv[1:4])
