#!/usr/bin/env python3
# $1 config file
import datetime
import json
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
Description: {} Library
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
		return modname.lower()
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
def get_source(sdir, mod_url):
	sources = requests.get(mod_url)
	with tarfile.open(fileobj=io.BytesIO(sources.content)) as archive:
		archive.extractall(sdir)


def pack_source(sdir, odir, mod_full_name):
	with tarfile.open(pjoin(odir, "src.tar.gz"), "w:gz") as archive:
		archive.add(sdir, arcname=mod_full_name)


def prepare_source(sdir, extra_conf):
	# install qpmx deps into a temporary cache
	env = os.environ.copy()
	env["HOME"] = pjoin(sdir, "src", "3rdparty")
	for root, dirs, files in os.walk(sdir):
		for file in files:
			if file == "qpmx.json":
				subprocess.Popen([
					"qpmx", "-d", root, "install"
				], env=env).communicate()
	# create the .git folder to generate fwd includes if not already present
	if not os.path.isdir(pjoin(sdir, "include")):
		os.mkdir(pjoin(sdir, ".git"))
	# apply the extra config
	with open(pjoin(sdir, ".qmake.conf"), "a") as qmakeconf:
		for conf in extra_conf:
			qmakeconf.write(conf + "\n")


def prepare_dist_source(dconf, mconf, ddir, mod_name, baseurl):
	# generate the version to use in the url
	if "urlrev" in dconf:
		urlrev = dconf["urlrev"]
	elif "revision" in dconf:
		urlrev = dconf["revision"]
	else:
		urlrev = 0
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
	qmake_conf = mconf[dconf["mode"]]["qmakeconf"]
	get_source(ddir, dist_url)
	for path in os.listdir(ddir):
		src_dir = pjoin(ddir, path)
		if os.path.isdir(src_dir):
			prepare_source(src_dir, qmake_conf)
			pack_source(src_dir, ddir, mod_name)
			shutil.rmtree(src_dir)


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


def create_deb_dir(dist, ddir, conf, mode, pkg_base, mod_name, mod_vers):
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
		with tarfile.open(pjoin(ddir, "src.tar.gz")) as src_archive:
			with src_archive.extractfile(pjoin(mod_name, license_conf["file"])) as license_file:
				for line in license_file.readlines():
					file.write(" " + line.decode("utf-8").strip() + "\n")
		file.write(file_copyright_foot.format(license_conf["copyright"]))

	# create control
	with open(pjoin(deb_dir, "control"), "w") as file:
		# read vars
		pkg_lib = pkg_base
		if mode == Mode.MODULE.value:
			pkg_lib += mod_vers.split(".")[0]
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
											  conf["module"]))
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
			file.write("\noverride_dh_{}:\n".format(key))
			for rule in rules:
				file.write("\t" + rule + "\n")


def main():
	# load the config
	with open(sys.argv[1]) as file:
		config = json.load(file)

	with tempfile.TemporaryDirectory() as tmp_dir:
		# debug: override tmp_dir
		tmp_dir = "/tmp/debbuild"
		shutil.rmtree(tmp_dir, ignore_errors=True)
		os.mkdir(tmp_dir)

		# step 1: extract some variables
		if "urlbase" not in config:
			mod_baseurl = "https://github.com/{}/{}/archive/%version.tar.gz" \
				.format(config["author"], config["module"])
		else:
			mod_baseurl = config["urlbase"]

		for distro, dconf in config["distros"].items():
			dist_dir = pjoin(tmp_dir, distro)
			os.mkdir(dist_dir)

			# common stuff
			pkg_mode = dconf["mode"]
			pkg_base = pkgbase(config["module"], dconf["mode"])
			mod_version = dconf["version"]
			if "revision" in dconf:
				mod_version += "-" + str(dconf["revision"])
			else:
				mod_version += "-1"
			mod_fullname = config["module"] + "-" + mod_version

			# step 1: generate sources for all distros
			prepare_dist_source(dconf, config["configs"], dist_dir, mod_fullname, mod_baseurl)

			# step 2: generate the debian dir
			create_deb_dir(distro, dist_dir, config, pkg_mode, pkg_base, mod_fullname, mod_version)

			# step 3: setup and run docker to generate the build files
			subprocess.run([
				pjoin(os.path.dirname(os.path.realpath(__file__)), "debdocker.sh"),
				dist_dir
			], check=True)

			# debug:
			exit(0)


if __name__ == "__main__":
	main()
