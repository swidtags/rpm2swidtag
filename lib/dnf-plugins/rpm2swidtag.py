
from dnf import Plugin
from dnfpluginscore import logger
from subprocess import run, PIPE
import platform
from os import path
import re
from dnf.cli.commands.rpm2swidtag import rpm2swidtagCommand

class rpm2swidtag(Plugin):

	name = rpm2swidtagCommand.name
	dirname = rpm2swidtagCommand.dirname
	dir = rpm2swidtagCommand.dir
	swidtags_d = rpm2swidtagCommand.swidtags_d
	swidtags_d_symlink = rpm2swidtagCommand.swidtags_d_symlink

	RPM2SWIDTAG = rpm2swidtagCommand.RPM2SWIDTAG
	SWIDQ = "/usr/bin/swidq"

	def __init__(self, base, cli):
		super().__init__(base, cli)
		self.install_set = None
		self.remove_set = None
		if cli:
			cli.register_command(rpm2swidtagCommand)

	def resolved(self):
		self.install_set = self.base.transaction.install_set
		self.remove_set = self.base.transaction.remove_set

	def transaction(self):
		if not path.islink(self.swidtags_d_symlink) or not path.isdir(self.swidtags_d_symlink):
			return

		hostname = platform.uname()[1]
		for i in self.install_set:
			logger.debug('Will rpm2swidtag for %s' % i)
			if run([self.RPM2SWIDTAG, "--tag-creator", hostname, "--output-dir", path.join(self.dir, "."), str(i)]).returncode == 0:
				run([self.SWIDQ, "--rpm", str(i)])

		for i in self.remove_set:
			logger.debug('Will remove rpm2swidtag-generated .swidtag for %s' % i)
			swidtag = run([self.SWIDQ, "--rpm", str(i)], stdout=PIPE, encoding="utf-8")
			if swidtag.returncode != 0:
				continue
			for l in swidtag.stdout.splitlines():
				m = re.search(r'^(\S+) (\S+)$', l)
				if not m:
					continue
				rpm2swidtagCommand._unlink(m.group(2))
				component_of = run([self.SWIDQ, "-a", m.group(1) + "-component-of-*"], stdout=PIPE, encoding="utf-8")
				if component_of.returncode != 0:
					continue
				for ll in component_of.stdout.splitlines():
					m = re.search(r'^- (\S+) (\S+)$', ll)
					if not m:
						continue
					rpm2swidtagCommand._unlink(m.group(2))

	@staticmethod
	def _unlink(file):
		run(["/usr/bin/rm", "-v", file])
