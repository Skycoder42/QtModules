#!/usr/bin/env python3
# $1 config file
# $2.. distros

import datetime
import json
import pathlib
import sys
import tempfile

import os
from os.path import join as pjoin
import requests
import tarfile
import io
import subprocess
import shutil
from enum import Enum


class Mode(Enum):
	STANDARD = "standard"
	MODULE = "module"
	OPT = "opt"


file_source_format = "3.0 (quilt)\n"
file_compat = "9\n"
file_rules = """#!/usr/bin/make -f
export HOME := $(CURDIR)/src/3rdparty/

%:
	dh $@ --parallel
"""
file_copyright_head = """Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: {}
Source: {}

Files: *
Copyright: {}
License: {}
"""
file_copyright_foot = """
Files: debian/*
Copyright: {}
License: GPL-2+
 This package is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 .
 This package is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 .
 You should have received a copy of the GNU General Public License
 along with this program. If not, see <https://www.gnu.org/licenses/>
 .
 On Debian systems, the complete text of the GNU General
 Public License version 2 can be found in "/usr/share/common-licenses/GPL-2".
"""
file_control_source = """Source: {}
Priority: optional
Maintainer: {} <{}>
Build-Depends: {}
Standards-Version: {}
Section: {}
Homepage: {}
"""
file_control_module = """
Package: {}
Architecture: any
Depends: ${{shlibs:Depends}}, ${{misc:Depends}}
Description: {} {}
"""
file_control_dev = """
Package: {}-dev
Section: libdevel
Architecture: any
Depends: {} (= ${{binary:Version}}), ${{shlibs:Depends}}, ${{misc:Depends}}
Description: {} Library (dev)
 Developer package to build against the library.
"""


def pkgbase(modname, mode):
	if mode == Mode.MODULE.value:
		return "libqt5" + modname[2:].lower()
	elif mode == Mode.OPT.value:
		return modname.lower() + "-opt"
	elif mode == Mode.STANDARD.value:
		return modname.lower()
	else:
		raise Exception("Undefined mode: " + mode)


def standards_version(distro):
	if distro == "artful":
		return "4.1.1"
	elif distro == "bionic":
		return "4.1.1"  # TODO use correct versions
	elif distro == "xenial":
		return "3.9.7"
	else:
		raise Exception("Unknown distro: " + distro)


# basic: download and prepare the sources
def get_source(sdir, mod_url, asOrig=False):
	sources = requests.get(mod_url)
	if asOrig:
		pname = pjoin(sdir, os.path.basename(mod_url))
		with open(pname, "wb") as file:
			file.write(sources.content)
		with tarfile.open(pname) as archive:
				archive.extractall(sdir)
	else:
		with tarfile.open(fileobj=io.BytesIO(sources.content)) as archive:
			archive.extractall(sdir)


def pack_source(sdir, odir, mod_full_name, pkg_name):
	out_path = pjoin(odir, mod_full_name)
	os.rename(sdir, out_path)
	with tarfile.open(pjoin(odir, pkg_name + ".orig.tar.gz"), "w:gz") as archive:
		archive.add(out_path, arcname=mod_full_name)


def patch_source(sdir, pdir, dist):
	patch_file = pjoin(pdir, dist + ".patch")
	pwd = os.path.dirname(sdir)
	with open(patch_file) as infile:
		subprocess.run(["patch", "-p0"], cwd=pwd, check=True, stderr=subprocess.PIPE, stdin=infile)


def prepare_source(sdir, extra_conf, src_cmds, dist, patch):
	# apply patches
	if patch != "":
		patch_source(sdir, patch, dist)
	# install qpmx deps into a temporary cache
	env = os.environ.copy()
	env["HOME"] = pjoin(sdir, "src", "3rdparty")
	for root, dirs, files in os.walk(sdir):
		for file in files:
			if file == "qpmx.json":
				subprocess.run([
					"qpmx", "-d", root, "install"
				], env=env)
	# create the .git folder to generate fwd includes if not already present
	if not os.path.isdir(pjoin(sdir, "include")):
		os.mkdir(pjoin(sdir, ".git"))
	# apply the extra config
	with open(pjoin(sdir, ".qmake.conf"), "a") as qmakeconf:
		for conf in extra_conf:
			qmakeconf.write(conf + "\n")
	# run special source commands
	for cmd in src_cmds:
		if subprocess.call(cmd.split(" "), cwd=sdir) != 0:
			raise Exception("Subcommand \"" + cmd + "\" failed")


def prepare_dist_source(dist, dconf, mconf, ddir, mod_name, pkg_name, baseurl, origurl=""):
	# generate the version to use in the url
	if origurl == "":
		if "urlrev" in dconf:
			urlrev = dconf["urlrev"]
		elif "revision" in dconf:
			urlrev = dconf["revision"]
		else:
			urlrev = 0
		if "urlver" in dconf:
			urlversion = dconf["urlver"]
		else:
			urlversion = dconf["version"]
		vsplit = urlversion.split(".")
		if urlrev != 0:
			urlversion += "-" + str(urlrev)

		# use the extracted stuff to prepare the url
		dist_url = baseurl
		for i in range(1, len(vsplit) + 1, 1):
			dist_url = dist_url.replace("$ver" + str(i), ".".join(vsplit[0:i]))
		dist_url = dist_url.replace("$version", urlversion)

		# download the sources
		xconf = mconf[dconf["mode"]]
		qmake_conf = xconf["qmakeconf"] if "qmakeconf" in xconf else []
		src_cmds = xconf["srccmds"] if "srccmds" in xconf else []
		get_source(ddir, dist_url)
		for path in os.listdir(ddir):
			src_dir = pjoin(ddir, path)
			if os.path.isdir(src_dir):
				prepare_source(src_dir, qmake_conf, src_cmds, dist, dconf["patch"] if "patch" in dconf else "")
				pack_source(src_dir, ddir, mod_name, pkg_name)
	else:
		# download the sources
		get_source(ddir, origurl, asOrig=True)
		for path in os.listdir(ddir):
			src_dir = pjoin(ddir, path)
			if os.path.isdir(src_dir):
				os.rename(src_dir, pjoin(ddir, mod_name))


# stuff to create the debian dir
def write_changelog(file, data, level=1):
	prefix = ("  " * level) + "* "
	for log in data:
		if isinstance(log, list):
			write_changelog(file, log, level + 1)
		else:
			file.write(prefix + log + "\n")


def write_description(file, description):
	desc_buffer = ""
	for word in description.split(" "):
		if len(desc_buffer) + len(word) >= 80:
			file.write(desc_buffer + "\n")
			desc_buffer = ""
		desc_buffer += " " + word

	if desc_buffer != " ":
		file.write(desc_buffer + "\n")


def write_inst_files(conf, ddir, pkg_name):
	with open(pjoin(ddir, pkg_name + ".dirs"), "w") as file:
		for dir in conf["dirs"]:
			file.write(dir + "\n")
	with open(pjoin(ddir, pkg_name + ".install"), "w") as file:
		for install in conf["install"]:
			file.write(install + "\n")


def create_deb_dir(dist, ddir, conf, mode, pkg_base, mod_vers):
	deb_dir = pjoin(ddir, "debian")
	os.mkdir(deb_dir)

	# create static files
	os.mkdir(pjoin(deb_dir, "source"))
	with open(pjoin(deb_dir, "source", "format"), "w") as file:
		file.write(file_source_format)
	with open(pjoin(deb_dir, "compat"), "w") as file:
		file.write(file_compat)

	# create changelog
	with open(pjoin(deb_dir, "changelog"), "w") as file:
		logok = False
		for log in conf["changelog"]:
			if log["version"] == mod_vers:
				logok = True
			elif not logok:
				continue

			if "urgency" in log:
				urgency = log["urgency"]
			else:
				urgency = "medium"
			file.write("{} ({}+{}) {}; urgency={}\n\n"
					   .format(pkg_base,
							   log["version"],
							   dist,
							   dist,
							   urgency))
			write_changelog(file, log["log"])
			file.write("\n -- {} <{}>  {}\n\n"
					   .format(conf["author"],
							   conf["email"],
							   datetime.datetime.now().strftime("%a, %d %b %Y %H:%M:%S +0100")))

	# create copyright
	with open(pjoin(deb_dir, "copyright"), "w") as file:
		license_conf = conf["license"]
		file.write(file_copyright_head.format(conf["module"],
											  conf["homepage"],
											  license_conf["copyright"],
											  license_conf["license"]))
		with open(pjoin(ddir, license_conf["file"])) as license_file:
			for line in license_file.readlines():
				file.write(" " + line.strip() + "\n")
		file.write(file_copyright_foot.format(license_conf["copyright"]))

	# create control
	with open(pjoin(deb_dir, "control"), "w") as file:
		# read vars
		pkg_lib = pkg_base
		if mode == Mode.MODULE.value:
			pkg_lib += mod_vers.split(".")[0]
			suffix = "Library"
		else:
			suffix = "Package"
		modconf = conf["configs"][mode]

		# write file
		file.write(file_control_source.format(pkg_base,
											  conf["author"],
											  conf["email"],
											  ", ".join(modconf["debpkg"]),
											  standards_version(dist),
											  conf["section"],
											  conf["homepage"]))

		file.write(file_control_module.format(pkg_lib,
											  conf["module"],
											  suffix))
		write_description(file, conf["description"])
		if mode == Mode.MODULE.value:
			file.write(file_control_dev.format(pkg_base,
											   pkg_lib,
											   conf["module"]))
			write_description(file, conf["description"])

	# create dirs and install files
	installs = modconf["install"]
	if "lib" in installs:
		write_inst_files(installs["lib"], deb_dir, pkg_lib)
	if "dev" in installs:
		write_inst_files(installs["dev"], deb_dir, pkg_base + "-dev")

	# create rules
	with open(pjoin(deb_dir, "rules"), "w") as file:
		file.write(file_rules)
		for key, rules in modconf["rules"].items():
			file.write("\noverride_dh_{}:".format(key))
			rule_body = False
			for rule in rules:
				if not rule_body and rule[0] == ":":
					file.write(" " + rule[1:])
				else:
					if not rule_body:
						file.write("\n")
						rule_body = True
					file.write("\t" + rule + "\n")
	os.chmod(pjoin(deb_dir, "rules"), 0o755)


def qt_vid(config, pkg_mode):
	if pkg_mode == Mode.OPT.value:
		qt_ver = config["configs"][pkg_mode]["qtver"]
		return qt_ver.replace(".", "")
	else:
		return ""


def main():
	# load the config
	with open(sys.argv[1]) as file:
		config = json.load(file)
	dists = sys.argv[2:]
	if "test" in config:
		noupdate = config["test"]
	else:
		noupdate = False

	with tempfile.TemporaryDirectory() as tmp_dir:
		# step 1: extract some variables
		if "urlbase" not in config:
			mod_baseurl = "https://github.com/{}/{}/archive/$version.tar.gz" \
				.format(config["author"], config["module"])
		else:
			mod_baseurl = config["urlbase"]

		for distro in dists:
			dconf = config["distros"][distro]

			dist_dir = pjoin(tmp_dir, distro)
			os.mkdir(dist_dir)

			# common stuff
			pkg_mode = dconf["mode"]
			pkg_base = pkgbase(config["module"], dconf["mode"])
			lib_version = dconf["version"]
			mod_version = lib_version
			if "revision" in dconf:
				mod_version += "-" + str(dconf["revision"])
			else:
				mod_version += "-1"
			mod_fullname = config["module"] + "-" + mod_version

			# step 1: generate sources
			prepare_dist_source(distro,
								dconf,
								config["configs"],
								dist_dir,
								mod_fullname,
								pkg_base + "_" + lib_version,
								mod_baseurl,
								dconf["orig"] if "orig" in dconf else "")

			# step 2: generate the debian dir
			create_deb_dir(distro,
						   pjoin(dist_dir, mod_fullname),
						   config,
						   pkg_mode,
						   pkg_base,
						   mod_version)

			# step 3: create the debbuild.sh file
			with open(pjoin(os.path.dirname(os.path.realpath(__file__)), "debbuild.sh")) as file:
				debbuild_str = file.read()
			debbuild_str = debbuild_str.format(distro,
											   mod_fullname,
											   pkg_mode,
											   " ".join(config["configs"][pkg_mode]["debpkg"]),
											   qt_vid(config, pkg_mode),
											   "y" if noupdate else "n")
			deb_sh = pjoin(dist_dir, "debbuild.sh")
			with open(deb_sh, "w") as file:
				file.write(debbuild_str)
			os.chmod(deb_sh, 0o755)

			# step 4: copy stuff into docker volume folder
			home = pathlib.Path.home()
			cache_dir = pjoin(home, ".cache", "debbuild")
			build_dir = pjoin(cache_dir, "build")
			shutil.rmtree(build_dir, ignore_errors=True)
			shutil.copytree(dist_dir, build_dir, symlinks=True)

			# step 5: prepare docker image and run
			subprocess.run([  # update the image
				"sudo", "docker", "pull", "ubuntu:" + distro
			], check=True)
			subprocess.run([  # create the container if not already existing (thus ignore errors)
				"sudo", "docker", "create",
				"--name", "docker_deb_build_" + distro,
				"-it",
				"--security-opt", "apparmor:unconfined",
				"--cap-add=SYS_ADMIN",
				"-v", cache_dir + ":/debbuild",
				"ubuntu:" + distro,
				"bash", "/debbuild/build/debbuild.sh"
			])
			subprocess.run([  # run the build script in the container
				"sudo", "docker", "start",
				"-ai",
				"docker_deb_build_" + distro
			], check=True)


if __name__ == "__main__":
	main()
