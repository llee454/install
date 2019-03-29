Install Package:
================

Synopsis:
---------

The install package provides a number of untilities to simplify the configuration, compilation, installation, and uninstallation of gnu software packages. The package provides three core perl scripts: install, installPackages, and uninstall. Install uses configure/make to install software packages. installPackages uses install to install multiple packages. uninstall uses make to uninstall software packages that were installed using install.
The package requires that the target software package uses the configure/make system. It also requires that gmake, perl, and a number of perl modules are avaiable.

Directory Structure:
--------------------

The install package assumes that gnu source packages will be stored in a 'sources' directory ('srcs' by default). Individual source packages are stored in subdirectories under the main 'sources' directory (for example the berkley database package, 'db-x.xx.x.tar.bz2' would be stored as 'srcs/db/db-x.xx.x.tar.bz2'). Object files are stored seperate from the source files. The object directories are stored under the 'objects' directory ('objs' by default). So taking our previous example, the object files associated with the db package would be stored under: objs/db/. The package objects directory contains several subdirectories - one for each compilation. By default, the install package assumes that every package version will be assigned its own object directory. So, the object files produced by compiling the db package would be stored under: '/objs/db/db-x.xx.x/'. By default files are installed to usr/local/bin, /usr/local/lib, etc. (I.E. the prefix configuration parameter is set to /usr/local). The install package uses a single log file. By default this file is named install.log. It is stored under 'objs/install.log'.
A schematic is given below:

```
/srcs:				# The 'sources' directory. package source directories are placed here.
|-> <package name> 		# The package source directory. The source files associated with <package name> will be stored here.
	|-> <package>		# The package. Install assumes that the source package is a compressed tar archive.
	|-> ...
|-> ... 

/objs:				# The 'objects directory. object files are stored here.
|-> <package name>		# The package object directory. The object files associated with <package name> will be stored here.
	|-> <package version>	# The package version object directory. The object files associated with compiling the package are stored here. By default, Install assumes that each of these directories corresponds to a specific package version.
		|-> <objects>	# The object files produced by compiling a package.
		|-> ...
	|-> ...
|-> ...
|-> install.log			# The install package uses a single log file. By default this file is stored here.
```

Prerequisites:
--------------

The install package requires a number of perl modules from the XML package. These modules can be downloaded from the cpan website. They are installed by executing the Makefile.pl script included in the module distribution directory.

1. make: The gnu make utility is needed to compile gnu software packages.
2. gcc: The gnu c compiler is required to compile most gnu software packages.
3. perl: The install package was written for perl 5.10.

Compiling Notes:
----------------

### Pkg Config:

Sometimes the package uses pkg-config to search for libraries. This program uses pc files to determine which libraries are installed on the given system. The `PKG_CONFIG_PATH` environment variable can be used to sepecify which directories should be search for these .pc files. This variable should contain a list of colon seperated directory paths. For example: '/usr/local/lib/pkgconfig:/usr/lib/pkgconfig'.

To change the pkg-config search path use the export command: `export PKG_CONFIG_PATH=<path>`

Note: I can't get this to work. pkg-config does not seem to respect this variable.

### Library Run Paths:

By default this package installs libraries under /usr/local/lib. Under Certain environments, the gnu linker ld is not configured to search /usr/local/lib for libraries during linkage. The LD_LIBRARY_PATH and RUNPATH environment variables determine where ld will look for libraries. These can be set explicitly during command execution using the following:

```
env LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib RUNPATH=$RUNPATH:/usr/local/lib <command>
```

But it is more effective to add the following lines to /etc/bash.bashrc or /etc/bashrc (depending on your system).

```
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib
export RUNPATH=$RUNPATH:/usr/local/lib
```

This will automatically add /usr/local/lib to the lds' search path during startup.
Unfortunately passing LDFlags="-R/usr/local/lib" to a packages' configure script does not seem to work.
Note also that sudo will not automatically export the `LD_LIBRARY_PATH` or the `RUNPATH` environment variables. To make sudo export these variables you should modify the /etc/sudoers file. For example: I added the variables by modifying the Defaults line to be:

```
Defaults:llee env_keep+="LD_LIBRARY_PATH:RUNPATH"
```

See "man sudoers"

License
-------

This package is available under the GPLv3.

Authors
-------

* Larry Darryl Lee Jr. <llee454@gmail.com>
https://orcid.org/0000-0002-7128-9257
