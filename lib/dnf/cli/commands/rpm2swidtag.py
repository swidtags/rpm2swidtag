
from dnf.cli import commands

import argparse
import platform
from subprocess import run
from os import path, makedirs

class rpm2swidtagCommand(commands.Command):
	aliases = [ "rpm2swidtag" ]
	summary = "Generate SWID tag files for installed rpms"

	name = 'rpm2swidtag'
	dirname = "%s-generated" % name
	dir = "/var/lib/swidtag/%s-generated" % name
	swidtags_d = "/etc/swid/swidtags.d"
	swidtags_d_symlink = path.join(swidtags_d, dirname)

	RPM2SWIDTAG = "/usr/bin/rpm2swidtag"
	UNLINK = "/usr/bin/rm"

	def configure(self):
		self.cli.demands.available_repos = False
		self.cli.demands.sack_activation = False
		self.cli.demands.resolving = False
		self.cli.demands.root_user = True

	@staticmethod
	def set_argparser(parser):
		subparser = parser.add_subparsers(parser_class=argparse.ArgumentParser, dest="rpm2swidtagcmd")
		subparser.add_parser("enable", help="enable rpm2swidtag plugin")
		subparser.add_parser("enable-regen", help="enable + generate SWID tags for already installed rpms")
		subparser.add_parser("disable", help="disable rpm2swidtag plugin")
		subparser.add_parser("disable-purge", help="disable + remove all tags generated by rpm2swidtag plugin")

	def run(self):
		if self.opts.rpm2swidtagcmd in ( "enable", "enable-regen" ):
			if self.opts.rpm2swidtagcmd == "enable-regen":
				self._purge_dir()
				hostname = platform.uname()[1]
				print("Running %s --all ..." % self.RPM2SWIDTAG)
				run([self.RPM2SWIDTAG, "--regid", hostname, "--output-dir", path.join(self.dir, "."), "--all"])
			elif not path.isdir(self.dir):
				makedirs(self.dir)
			if not path.islink(self.swidtags_d_symlink):
				if not path.exists(self.swidtags_d):
					makedirs(self.swidtags_d)
				self._symlink(self.dir, self.swidtags_d_symlink)
		elif self.opts.rpm2swidtagcmd in ( "disable", "disable-purge" ):
			if self.opts.rpm2swidtagcmd == "disable-purge" and path.isdir(self.dir):
				self._purge_dir()
			if path.islink(self.swidtags_d_symlink):
				self._unlink(self.swidtags_d_symlink)
		else:
			print("dnf rpm2swidtag [enable | enable-regen | disable | disable-purge]")

	@staticmethod
	def _unlink(file):
		run([__class__.UNLINK, "-v", file])

	def _purge_dir(self):
		run([self.UNLINK, "-fr", self.dir])

	@staticmethod
	def _symlink(dest, src):
		run(["/usr/bin/ln", "-sv", dest, src])
