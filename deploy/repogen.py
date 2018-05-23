#!/usr/bin/env python3
# $1 repo id
# $2 Version
# $3 Qt Version (e.g. "5.10.0")
# $4 install root

import datetime
import distutils.dir_util
import glob
import io
import json
import os
import re
import zipfile

import magic
import hashlib
import requests
import shutil
import subprocess
import sys
import tarfile
import tempfile

from os.path import join as pjoin


# workaround / hack to handle LTS releases
is_lts = False
lts_version = ""
qt_prefix = "qt.qt5."

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

pkg_sample_xml = """<?xml version="1.0" encoding="UTF-8"?>
<Package>
	<Name>{}</Name>
	<DisplayName>{} Examples</DisplayName>
	<Version>{}</Version>
	<ReleaseDate>{}</ReleaseDate>
	<Virtual>true</Virtual>
	<AutoDependOn>{}, {}</AutoDependOn>
	<Dependencies>{}</Dependencies>
</Package>"""

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

pkg_platform_xml_pre = """
<Updates>
 <ApplicationName>{{AnyApplication}}</ApplicationName>
 <ApplicationVersion>1.0.0</ApplicationVersion>
 <Checksum>true</Checksum>
 <PackageUpdate>
  <Name>{}{}.skycoder42</Name>
  <DisplayName>Skycoder42 Qt {} modules</DisplayName>
  <Description>
   Contains all my Qt {} modules, for a simple installation.
  </Description>
  <Version>1.0.0</Version>
  <ReleaseDate>{}</ReleaseDate>
  <Default>true</Default>
  <UpdateFile UncompressedSize="0" OS="Any" CompressedSize="0"/>
  <SHA1>{}</SHA1>
 </PackageUpdate>
 <RepositoryUpdate>"""
pkg_platform_xml_mid = """
  <Repository action="add" url="https://install.skycoder42.de/qtmodules/qt{}/{}/{}" displayname="Qt {} {} {} Repository"/>"""
pkg_platform_xml_post = """
 </RepositoryUpdate>
</Updates>"""


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
	if is_lts:
		vers = vers.split("-")[0]
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
			"-version", version.split("-")[0],  # only use the actual version, not the revision
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
			depends.append(qt_prefix + qt_vid(qt_version) + dep)
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

	# add special installs
	if "installs" in config:
		data_dir = pkg_data(pkg_dir)
		for from_path, to_path in config["installs"].items():
			fp = pjoin(sdir, from_path)
			tp = pjoin(data_dir, to_path)
			if os.path.isdir(fp):
				shutil.copytree(fp, tp, symlinks=True)
			else:
				shutil.copy2(fp, tp)


def create_src_pkg(rdir, sdir, pkg_base, config, version, qt_version):
	print("=> Creating source package")
	pkg_src = pkg_base + ".src"
	pkg_dir = pkg_prepare(rdir, pkg_src)

	print("  -> Creating meta data")
	pkg_qt_src = "{}{}.src".format(qt_prefix, qt_vid(qt_version))
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

	pkg_qt_doc = "{}{}.doc".format(qt_prefix, qt_vid(qt_version))
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


def create_sample_meta(rdir, pkg_base, config, version, qt_version):
	pkg_sample = pkg_base + ".examples"
	pkg_dir = pkg_prepare(rdir, pkg_sample)

	pkg_qt_sample = "{}{}.examples".format(qt_prefix, qt_vid(qt_version))
	pkg_add_package_xml(pkg_dir, pkg_sample_xml,
						pkg_sample,
						config["title"],
						version,
						datetime.date.today(),
						pkg_base,
						pkg_qt_sample,
						pkg_qt_sample)
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

	pkg_qt_arch = "{}{}.{}".format(qt_prefix, qt_vid(qt_version), qt_arch)
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
		print("    >> Fixing " + os.path.basename(file))
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


def fix_sample_paths(idir):
	patterns = [
		re.compile("^.*\\.la$"),
		re.compile("^.*\\.prl$"),
		re.compile("^.*\\.a$"),
		re.compile("^.*\\.so$"),
		re.compile("^.*\\.la$"),
		re.compile("^.*\\.so(\\.\\d+)+$")
	]

	for root, dirs, files in os.walk(idir):
		for file in files:
			ma = magic.detect_from_filename(pjoin(root, file))
			if ma.mime_type == "application/x-executable":
				print("    >> Removing sample binary " + file)
				os.remove(pjoin(root, file))
			elif ma.mime_type == "application/x-sharedlib":
				print("    >> Removing sample binary " + file)
				os.remove(pjoin(root, file))
			else:
				for pattern in patterns:
					if pattern.fullmatch(file):
						print("    >> Removing sample binary " + file)
						os.remove(pjoin(root, file))


def create_bin_pkg(rdir, pkg_base, repo, arch, config, version, url_version, qt_version, as_zip):
	for exclude in config["excludes"]:
		if exclude in arch:
			return

	print("=> Creating " + arch + " package")

	# prepare metadata
	print("  -> Creating meta data")
	if arch == "doc":
		pkg_dir = create_doc_meta(rdir, pkg_base, config, version, qt_version)
	elif arch == "examples":
		pkg_dir = create_sample_meta(rdir, pkg_base, config, version, qt_version)
	else:
		pkg_dir = create_arch_meta(rdir, pkg_base, arch, config, version, qt_version)

	# download sources
	print("  -> Downloading and extracting data from github")
	if is_lts:
		bin_url = "https://github.com/Skycoder42/QtModules-LTS/releases/download/" + lts_version + "/" + config["title"].lower() + "_build_" + arch + "_" + qt_version
	else:
		bin_url = "https://github.com/" + repo + "/releases/download/" + url_version + "/build_" + arch + "_" + qt_version
	bin_url += ".zip" if as_zip else ".tar.xz"
	if arch == "doc":
		inst_dir = pjoin(pkg_data(pkg_dir), "Docs")
	elif arch == "examples":
		inst_dir = pjoin(pkg_data(pkg_dir), "Examples")
	else:
		inst_dir = pjoin(pkg_data(pkg_dir), qt_version)
	url_extract(inst_dir, bin_url, as_zip)

	# fiuxp prl and la files, clean samples etc.
	if arch == "examples":
		print("  -> Removing binaries from documentation")
		fix_sample_paths(inst_dir)
	elif arch != "doc":
		print("  -> Fixing up build paths")
		fix_arch_paths(inst_dir, arch)


def create_all_pkgs(rdir, pkg_base, repo, config, version, url_version, qt_version):
	# tar packages
	for arch in ["android_armv7", "android_x86", "clang_64", "doc", "examples", "gcc_64", "ios", "static_linux", "static_osx"]:
		create_bin_pkg(rdir, pkg_base, repo, arch, config, version, url_version, qt_version, False)
	# zip packages
	for arch in ["mingw53_32", "msvc2015", "msvc2015_64", "msvc2017_64", "winrt_armv7_msvc2017", "winrt_x64_msvc2017",
				 "winrt_x86_msvc2017", "static_win"]:
		create_bin_pkg(rdir, pkg_base, repo, arch, config, version, url_version, qt_version, True)


def create_repo(rdir, pdir, pkg_base, *arch_pkgs):
	pkg_list = [
		pkg_base,
		pkg_base + ".src",
		pkg_base + ".doc",
		pkg_base + ".examples"
	]
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


def prepare_static_files(rdir, os_static, pkg_base, qt_version, *arch_pkgs):
	inverse_pkg_keys = {
		"win64_msvc2017_winrt_x86": "winrt_x86_msvc2017",
		"win64_msvc2017_winrt_x64": "winrt_x64_msvc2017",
		"win64_msvc2017_winrt_armv7": "winrt_armv7_msvc2017"
	}

	# fix static os
	if os_static == "static_mac":
		os_static = "static_osx"
	if os_static == "static_windows":
		os_static = "static_win"

	# generate static copy paths
	pkg_static = pkg_base + "." + os_static
	static_kit_dir = pjoin(rdir, pkg_static)
	if not os.path.exists(static_kit_dir):
		return
	static_kit_dir = pjoin(static_kit_dir, "data", qt_version, os_static)

	for arch in arch_pkgs:
		if arch.startswith("android") or arch == "ios" or "winrt" in arch:
			print("  -> Preparing static tools for " + arch)
			pkg_arch = pkg_base + "." + arch
			pkg_data_dir = pjoin(rdir, pkg_arch, "data")
			pkg_backup_dir = pkg_data_dir + ".bkp"

			orig_arch = inverse_pkg_keys[arch] if arch in inverse_pkg_keys else arch
			pkg_kit_dir = pjoin(pkg_data_dir, qt_version, orig_arch)
			if not os.path.exists(pkg_kit_dir):
				raise Exception("Missing path: " + pkg_kit_dir)

			# create or restore original data
			if not os.path.exists(pkg_backup_dir):
				print("    >> Create original data backup")
				shutil.copytree(pkg_data_dir, pkg_backup_dir, symlinks=True)
			else:
				print("    >> Restore original data backup")
				shutil.rmtree(pkg_data_dir)
				shutil.copytree(pkg_backup_dir, pkg_data_dir, symlinks=True)

			# copy in the static stuff
			print("    >> Copy static tools")
			distutils.dir_util._path_created = {}  # clear copy dir-cache, because it was deleted before
			distutils.dir_util.copy_tree(static_kit_dir, pkg_kit_dir, preserve_symlinks=True)


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


def create_meta_pkgs(qt_version, mod_info, dep_dir):
	with tempfile.TemporaryDirectory() as tmp_dir:
		print("=> Generating platform packages")
		mod_base = "{}{}.skycoder42".format(qt_prefix, qt_vid(qt_version))
		os.mkdir(pjoin(tmp_dir, mod_base))

		for platform in ["linux_x64", "windows_x86", "mac_x64"]:
			print("  -> Creating platform package " + platform)
			meta_dir = pjoin(dep_dir, "qt" + qt_vid(qt_version), platform)
			if os.path.isdir(meta_dir):
				continue

			os.makedirs(meta_dir)

			# add the 7z archive
			data_dir = pjoin(meta_dir, mod_base)
			os.mkdir(data_dir)
			subprocess.run([
				"7z", "a", pjoin(data_dir, "1.0.0meta.7z")
			], cwd=tmp_dir, check=True, stdout=subprocess.DEVNULL)
			hasher = hashlib.sha1()
			with open(pjoin(data_dir, "1.0.0meta.7z"), "rb") as zfile:
				hasher.update(zfile.read())
			checksum = hasher.hexdigest()

			# create xml file
			with open(pjoin(meta_dir, "Updates.xml"), "w") as file:
				file.write(pkg_platform_xml_pre.format(qt_prefix, qt_vid(qt_version),
													   qt_version,
													   qt_version,
													   datetime.date.today(),
													   checksum))
				for mod_name, version in mod_info:
					file.write(pkg_platform_xml_mid.format(qt_vid(qt_version), mod_name.lower(), platform,
														   qt_version, mod_name, platform))
				file.write(pkg_platform_xml_post)


def repogen(repo_id, version, qt_version, dep_dir, no_metagen=False):
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
		pkg_base = "{}{}.{}.{}".format(qt_prefix, qt_vid(qt_version), user.lower(), mod_title.lower())
		create_base_pkg(rep_dir, src_dir, pkg_base, config, version, qt_version)
		if "Src" not in config["excludes"]:
			create_src_pkg(rep_dir, src_dir, pkg_base, config, version, qt_version)

		# step 3: download and create binary repositories
		create_all_pkgs(rep_dir, pkg_base, repo_id, config, version, version, qt_version)

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

	# step 5 (optional): create the meta pkgs
	if not no_metagen:
		create_meta_pkgs(qt_version, [(mod_name, version)], dep_dir)


def repogen_lts(qt_version, dep_dir):
	# set globals
	global is_lts, lts_version, qt_prefix
	is_lts = True
	lts_version = qt_version + "-lts"
	qt_prefix = "qt."

	mod_info = [
		("QtJsonSerializer", "3.1.2"),
		("QtRestClient", "1.2.6"),
		("QtDataSync", "4.0.1"),
		("QtAutoUpdater", "2.1.4")
	]

	for mod_name, version in mod_info:
		repogen("Skycoder42/" + mod_name, version + "-" + qt_version.split(".")[-1], qt_version, dep_dir, True)

	create_meta_pkgs(qt_version, mod_info, dep_dir)


if __name__ == '__main__':
	if sys.argv[1] == "lts":
		repogen_lts(*sys.argv[2:4])
	else:
		repogen(*sys.argv[1:5])
