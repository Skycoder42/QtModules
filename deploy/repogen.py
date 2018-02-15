#!/usr/bin/env python3
# $1 repo id
# $2 Version
# $3 Qt Version (e.g. "5.10.0")
# $4 install root
import datetime
import glob
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


def prepare_sources(tdir, repo, mod_name, vers):
	print("  -> Downloading source tarball")
	# download sources
	out_dir = pjoin(tdir, mod_name + "-" + vers)
	mod_url = "https://github.com/" + repo + "/archive/" + vers + ".tar.gz"
	url_extract(tdir, mod_url)

	# prepare sources
	os.remove(pjoin(out_dir, ".travis.yml"))
	os.remove(pjoin(out_dir, "appveyor.yml"))
	shutil.move(pjoin(out_dir, "deploy.json"), pjoin(tdir, "deploy.json"))

	return out_dir


def prepare_headers(tdir, mdir, mods, version):
	syncqt_req = requests.get("https://code.qt.io/cgit/qt/qtbase.git/plain/bin/syncqt.pl")
	syncqt_pl = pjoin(tdir, "syncqt.pl")
	with open(syncqt_pl, "wb") as file:
		file.write(syncqt_req.content)
	os.chmod(syncqt_pl, 0o755)
	for mod in mods:
		print("  -> Creating public includes for " + mod)
		subprocess.run([
			syncqt_pl,
			"-module", mod,
			"-version", version,
			"-outdir", mdir,
			mdir
		], check=True, stdout=subprocess.DEVNULL)


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


def create_base_pkg(rdir, sdir, pkg_base, config, version, qt_version):
	print("=> Creating meta package")
	pkg_dir = pkg_prepare(rdir, pkg_base)

	print("  -> Create meta data")
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

	shutil.copy2(pjoin(sdir, config["license"]["path"]),
				 pjoin(pkg_meta(pkg_dir), "LICENSE.txt"))


def create_src_pkg(rdir, sdir, pkg_base, config, version, qt_version):
	print("=> Creating source package")
	pkg_src = pkg_base + ".src"
	pkg_dir = pkg_prepare(rdir, pkg_src)

	print("  -> Creating meta data")
	pkg_qt_src = "qt.qt5.{}.src".format(qt_vid(qt_version))
	pkg_add_package_xml(pkg_dir, pkg_src_xml,
						pkg_src,
						config["title"],
						version,
						datetime.date.today(),
						pkg_base,
						pkg_qt_src,
						pkg_qt_src)

	print("  -> Moving sources")
	src_base_dir = pjoin(pkg_data(pkg_dir), qt_version, "Src")
	os.makedirs(src_base_dir, exist_ok=True)
	shutil.move(sdir, pjoin(src_base_dir, config["title"].lower()))


def create_doc_meta(rdir, pkg_base, config, version, qt_version):
	pkg_doc = pkg_base + ".doc"
	pkg_dir = pkg_prepare(rdir, pkg_doc)

	pkg_qt_doc = "qt.qt5.{}.doc".format(qt_vid(qt_version))
	pkg_add_package_xml(pkg_dir, pkg_doc_xml,
						pkg_doc,
						config["title"],
						version,
						datetime.date.today(),
						pkg_base,
						pkg_qt_doc,
						pkg_qt_doc)
	pkg_add_script(pkg_dir, pkg_doc_qs, qt_version)
	return pkg_dir


def create_arch_meta(rdir, pkg_base, arch, config, version, qt_version):
	embedded_keys = [
		"android_armv7",
		"android_x86",
		"ios",
		"winrt_x86_msvc2017",
		"winrt_x64_msvc2017",
		"winrt_armv7_msvc2017"
	]
	pkg_keys = {
		"mingw53_32": "win32_mingw53",
		"msvc2017_64": "win64_msvc2017_64",
		"winrt_x86_msvc2017": "win64_msvc2017_winrt_x86",
		"winrt_x64_msvc2017": "win64_msvc2017_winrt_x64",
		"winrt_armv7_msvc2017": "win64_msvc2017_winrt_armv7",
		"msvc2015_64": "win64_msvc2015_64",
		"msvc2015": "win32_msvc2015",
	}

	qt_arch = pkg_keys[arch] if arch in pkg_keys else arch
	pkg_arch = pkg_base + "." + qt_arch
	pkg_dir = pkg_prepare(rdir, pkg_arch)

	pkg_qt_arch = "qt.qt5.{}.{}".format(qt_vid(qt_version), qt_arch)
	pkg_add_package_xml(pkg_dir, pkg_arch_xml,
						pkg_arch,
						config["title"],
						qt_arch,
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
	return pkg_dir


def fix_lines(idir, arch, pattern, fix_fn):
	# find all files and fix them
	for file in glob.iglob(pjoin(idir, arch, "**", pattern), recursive=True):
		print("	>> Fixing " + os.path.basename(file))
		with open(file, "r") as infile:
			lines = infile.readlines()

		lines = fix_fn(lines)

		with open(file, "w") as outfile:
			outfile.writelines(lines)


def fix_arch_paths(idir, arch):
	def fix_prl(lines):
		# remove the first element
		lines[0] = "\n"
		# replace the QMAKE_PRL_LIBS
		for i in range(1, len(lines), 1):
			if lines[i].startswith("QMAKE_PRL_LIBS"):
				args = ["-L/home/qt/work/install/lib"]
				for arg in lines[i].split("=")[1].strip().split(" "):
					if not arg.startswith("-L"):
						args.append(arg)
				lines[i] = "QMAKE_PRL_LIBS = " + " ".join(args) + "\n"
		return lines

	def fix_la(lines):
		# replace the dependency_libs and libdir
		for i in range(0, len(lines), 1):
			if lines[i].startswith("dependency_libs"):
				args = ["-L/home/qt/work/install/lib"]
				for arg in lines[i].split("=")[1].strip()[1:-1].split(" "):
					if not arg.startswith("-L"):
						args.append(arg)
				lines[i] = "dependency_libs='" + " ".join(args) + "'\n"
			elif lines[i].startswith("libdir"):
				lines[i] = "libdir='=/home/qt/work/install/lib'\n"
		return lines

	def fix_pc(lines):
		# replace the first line
		if len(lines) > 0:
			lines[0] = "prefix=/home/qt/work/install\n"
		return lines

	# fix prl files
	fix_lines(idir, arch, "*.prl", fix_prl)
	# fix la files
	fix_lines(idir, arch, "*.la", fix_la)
	# fix pc files
	fix_lines(idir, arch, "*.pc", fix_pc)


def create_bin_pkg(rdir, pkg_base, repo, arch, config, version, qt_version, as_zip):
	for exclude in config["excludes"]:
		if exclude in arch:
			return

	print("=> Creating " + arch + " package")

	# prepare metadata
	print("  -> Creating meta data")
	if arch == "doc":
		pkg_dir = create_doc_meta(rdir, pkg_base, config, version, qt_version)
	else:
		pkg_dir = create_arch_meta(rdir, pkg_base, arch, config, version, qt_version)

	# download sources
	print("  -> Downloading and extracting data from github")
	bin_url = "https://github.com/" + repo + "/releases/download/" + version + "/build_" + arch + "_" + qt_version
	bin_url += ".zip" if as_zip else ".tar.xz"
	inst_dir = pjoin(pkg_data(pkg_dir), "Docs" if arch == "doc" else qt_version)
	url_extract(inst_dir, bin_url, as_zip)

	# fiuxp prl and la files
	if arch != "doc":
		print("  -> Fixing up build paths")
		fix_arch_paths(inst_dir, arch)


def create_all_pkgs(rdir, pkg_base, repo, config, version, qt_version):
	# tar packages
	for arch in ["android_armv7", "android_x86", "clang_64", "doc", "gcc_64", "ios", "static_linux", "static_osx"]:
		create_bin_pkg(rdir, pkg_base, repo, arch, config, version, qt_version, False)
	# zip packages
	for arch in ["mingw53_32", "msvc2015", "msvc2015_64", "msvc2017_64", "winrt_armv7_msvc2017", "winrt_x64_msvc2017",
				 "winrt_x86_msvc2017", "static_win"]:
		create_bin_pkg(rdir, pkg_base, repo, arch, config, version, qt_version, True)


def create_repo(rdir, pdir, pkg_base, *arch_pkgs):
	pkg_list = [pkg_base, pkg_base + ".src", pkg_base + ".doc"]
	for arch in arch_pkgs:
		pkg_list.append(pkg_base + "." + arch)
	repo_inc = ",".join(pkg_list)

	subprocess.run([
		"repogen",
		"--update-new-components",
		"-p", pdir,
		"-i", repo_inc,
		rdir
	], check=True, stdout=subprocess.DEVNULL)


def prepare_static_files(rdir, spkg, pkg_base, qt_version, *arch_pkgs):
	static_bin_dir = pjoin(rdir, spkg)
	if not os.path.exists(static_bin_dir):
		return
	static_bin_dir = pjoin(static_bin_dir, "static", "data", qt_version, "bin")

	print("  -> Preparing static tools")
	for arch in arch_pkgs:
		if arch.startswith("android") or \
				arch == "ios" or \
				"winrt" in arch:
			pkg_arch = pkg_base + "." + arch
			pkg_bin_dir = pjoin(rdir, pkg_arch, "data", qt_version)
			pkg_bin_dir = pjoin(pkg_bin_dir, os.listdir(pkg_bin_dir)[0])

			shutil.rmtree(pkg_bin_dir, ignore_errors=True)
			shutil.copytree(static_bin_dir, pkg_bin_dir)


def deploy_repo(ddir, rdir, osname, arch, pkg_base, config, qt_version, *arch_pkgs):
	dep_name = osname + "_" + arch
	print("=> Deploying for " + dep_name)

	# prepare static tools
	prepare_static_files(rdir, "static_" + osname, pkg_base, qt_version, *arch_pkgs)

	# create repo
	print("  -> Creating repository")
	out_dir = pjoin(ddir, "qt" + qt_vid(qt_version), config["title"].lower(), dep_name)
	os.makedirs(out_dir, exist_ok=True)
	create_repo(out_dir, rdir, pkg_base, *arch_pkgs)


def repogen(repo_id, version, qt_version, dep_dir):
	user = repo_id.split("/")[0]
	mod_name = repo_id.split("/")[1]
	mod_title = mod_name[2:]

	with tempfile.TemporaryDirectory() as tmp_dir:
		# step 1: download and prepare sources
		print("=> Downloading an preparing sources")
		src_dir = prepare_sources(tmp_dir, repo_id, mod_name, version)
		with open(pjoin(tmp_dir, "deploy.json")) as file:
			config = json.load(file)
		prepare_headers(tmp_dir, src_dir, cfg_if(config, "modules", mod_name), version)

		# step 2: create the meta and src repositories
		rep_dir = pjoin(tmp_dir, "pkg")
		os.mkdir(rep_dir)
		pkg_base = "qt.qt5.{}.{}.{}".format(qt_vid(qt_version), user.lower(), mod_title.lower())
		create_base_pkg(rep_dir, src_dir, pkg_base, config, version, qt_version)
		if "Src" not in config["excludes"]:
			create_src_pkg(rep_dir, src_dir, pkg_base, config, version, qt_version)

		# step 3: download and create binary repositories
		create_all_pkgs(rep_dir, pkg_base, repo_id, config, version, qt_version)

		# step 4: create the actual repositories (repogen)
		# linux
		deploy_repo(dep_dir, rep_dir, "linux", "x64", pkg_base, config, qt_version,
					"gcc_64",
					"android_armv7", "android_x86")
		# windows
		deploy_repo(dep_dir, rep_dir, "windows", "x86", pkg_base, config, qt_version,
					"win32_mingw53",
					"win64_msvc2017_64",
					"win64_msvc2017_winrt_x86", "win64_msvc2017_winrt_x64", "win64_msvc2017_winrt_armv7",
					"win64_msvc2015_64", "win32_msvc2015",
					"android_armv7", "android_x86")
		# macos
		deploy_repo(dep_dir, rep_dir, "mac", "x64", pkg_base, config, qt_version,
					"clang_64",
					"ios",
					"android_armv7", "android_x86")


if __name__ == '__main__':
	repogen(*sys.argv[1:5])
