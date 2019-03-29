# configures, compiles, and installs gnu packages.
# Author: Larry Lee (3 - 23 - 09 GPL)

use Getopt::Long;
use Cwd 'abs_path';
use File::Spec;
use File::Basename;
use Time::Local;
use config;

my $log;

{
	# [1] get parameters:

	my ($srcs, $objs, $prefix, $pkg, $cfg, $opts, $autoconf, $configure, $make, $interactive, $inSrc);

	# [1.a] get command line options:
	GetOptions
	(
		'srcs=s'          => \$srcs,
		'objs=s'          => \$objs,
		'prefix=s'        => \$prefix,
		'package=s'       => \$pkg -> {'path'},
		'packagename=s'   => \$pkg -> {'name'},
		'config=s'        => \$cfg,
		'configoptions=s' => \$opts,
                'autoconf'        => \$autoconf,
                'configure=s'     => \$configure,
                'skip-configure'  => \$skipConfigure,
		'log=s'           => \$log,
		'make=s'          => \$make,
		'interactive'     => \$interactive,
		'in-source'       => \$inSrc,
		'help' => sub {
			print
			(
				"Usage:                                              \n" .
				"	install [options] --package=<package>        \n\n" .

				"Synopsis:                                           \n" .
				"		Install configures, compiles, and    \n" .
				"	installs the given GNU software package and  \n" .
				"	logs the result.                             \n\n" .

				"Detail:                                             \n" .
				"		Install will create a sub directory  \n" .
				"	in the sources directory for the package\'s  \n" .
				"	source files. It will then copy the package  \n" .
				"	into the package source directory. If the    \n" .
				"	package is a compressed tar archive, it will \n" .
				"	decompress and untar the package.            \n" .
				"		Install will then create a sub       \n" .
				"	directory in the objects directory for the   \n" .
				"	package\'s object files.                     \n" .
				"		Install will execute the package\'s  \n" .
				"	configure script from within the package\'s  \n" .
				"	object directory. If the configure script    \n" .
				"	exits without returning an error code, It    \n" .
				"	will execute make on the created makefile.   \n" .
				"		If make returns without throwing an  \n" .
				"	error, compile will execute make install.    \n" .
				"	It will then execute make clean, and delete  \n" .
				"	the source files.                            \n\n" .

				"Options:                                            \n" .
				"	\'--help\'                                   \n" .
				"		Displays this message.               \n\n" .

				"	\'--srcs\'                                   \n" .
				"		The sources directory path. The      \n" .
				"		package source directory will be     \n" .
				"		created in this directory.           \n\n" .

				"	\'--objs\'                                   \n" .
				"		The objects directory path. The      \n" .
				"		package object directory will be     \n" .
				"		created in this directory.           \n\n" .

				"	\'--prefix\'                                 \n" .
				"		The installation prefix. Installed   \n" .
				"		binaries, libraries, headers, and    \n" .
				"		configuration files are installed    \n" .
				"		under this directory. It is passed   \n" .
				"		to the configure script.             \n\n" .

				"	\'--package\'                                \n" .
				"		The package path. This is the gnu    \n" .
				"		package that will be installed.      \n\n" .

				"	\'--packagename\'                            \n" .
				"		The package name. The source and     \n" .
				"		object directories will be named     \n" .
				"		this.                                \n\n" .

				"	\'--config\'                                 \n" .
				"		The configuration file path. This    \n" .
				"		file will be used to set default     \n" .
				"		parameter values (defaults to        \n" .
				"		install.xml).                        \n\n" .
	
				"	\'--configoptions\'                          \n" .
				"		Any additional options that should   \n" .
				"		be passed to the configure script.   \n" .
				"		For example: \'with-<option>\'       \n" .
				"		options.                             \n\n" .
	
				"	\'--autoconf\'                               \n" .
				"		Instructs this program to run        \n" .
				"		autoconf to generate the configure   \n" .
				"		script.                              \n" .
				"		Note: this command only makes sense  \n" .
				"		when used with the \'--in-source\'   \n" .
				"		option.                              \n\n" .

				"	\'--configure\'                              \n" .
				"		The command that will be used to     \n" .
				"		invoke configure. By default this    \n" .
				"		program will search the source       \n" .
				"		directory for any script named       \n" .
				"		configure. The search is case        \n" .
				"		insensitve. Some packages do not use \n" .
				"		the standard configure options, or   \n" .
				"		define a seperate configure script   \n" .
				"		that is specific to specific hosts.  \n" .
				"		For example:                         \n" .
				"			--configure='config'         \n" .
				"		The above argument will instruct     \n" .
				"		this program to search the source    \n" .
				"		directory for a script named config  \n" .
				"		and execute to configure the package.\n\n" .

				"       \--skip-configure\'                          \n" .
				"               Instructs this program to skip       \n" .
				"               configuration. The program will try  \n" .
				"               to execute any make file that is     \n" .
				"               in the object directory. This        \n" .
				"               option should be used in conjunction \n" .
				"               with --in-source.                    \n\n" .

				"	\'--log\'                                    \n" .
				"		The log file path. Log messages will \n" .
				"		be written here. By default, this    \n" .
				"		program uses \'install.log\'.        \n\n" .

				"	\'--interactive\'                            \n" .
				"		continuing between the configuration,\n" .
				"		compilation, and install steps.      \n\n" .

				"	\'--in-source\'                              \n" .
				"		moves the source directory into the  \n" .
				"		object version directory and         \n" .
				"		executes the configure script        \n" .
				"		locally. (Note: some configure       \n" .
				"		scripts try to reference files using \n" .
				"		relative path names and fail when    \n" .
				"		they are executed from an external   \n" .
				"		directory. This option circumvents   \n" .
				"		this problem.)                       \n\n" .

				"	\'--make\'                                   \n" .
				"		The command that will be used to     \n" .
				"		invoke make. By default \'make\'.    \n" .
				"		Some systems require \'gmake\'. Or   \n" .
				"		you can use this option to select    \n" .
				"		a specific version. For example:     \n" .
				"			--make=/usr/bin/make         \n\n" .

				"Examples:                                           \n" .
				"	install --package=test.tar.gz                \n\n" .

 				"Notes:                                              \n" .
				"	Whenever you compile a library ensure that   \n" .
				"	enable shared objects. Many packages will    \n" .
				"	include an --enable-shared configuration     \n" .
				"	option. Shared libraries are often needed    \n" .
				"	by other packages that use these libraries.\n\n" .

				"	Whenever you install a library that you will \n" .
				"	need to link against (or a package that      \n" .
				"	defines libraries), you should ensure that   \n" .
				"	ld knows where those libraries are. You can  \n" .
				"	add directories to ld's search path by       \n" .
				"	adding an entry to the /etc/ld.so.conf file. \n" .
				"	For example, after I installed the krb5      \n" .
				"	package, I added its lib directory to the    \n" .
				"	search path by adding the following line to  \n" .
				"	ld.so.conf:  /usr/local/krb5/krb5-1.8.1/lib. \n" .
				"	I then refreshed ld's cache using: ldconfig. \n" .
				"	Finally, I confirmed that the libraries were \n" .
				"	added by doing a search: ldconfig -p | grep  \n" .
				"	--color libcom_err.                          \n"
			);

			exit (0)
		}
	);

	$make ||= 'make';

	$pkg -> {'path'} || die ("Error: missing --package parameter.\n");

	-e $pkg -> {'path'} || die ("Error: the package does not exist.\n");

	$pkg -> {'path'} = Cwd::abs_path ($pkg -> {'path'});

	$pkg -> {'file'} = File::Basename::fileparse ($pkg -> {'path'});

	$pkg -> {'name'} ||= ($pkg -> {'file'} =~ m/^([^-.]+)/)[0];

	print ("package \n");

	print ("\tpath: " . $pkg -> {'path'} . "\n");

	print ("\tfile: " . $pkg -> {'file'} . "\n");

	print ("\tname: " . $pkg -> {'name'} . "\n");

	# [1.b] get configuration file parameters:

	$cfg ||= 'install.cfg';

	print ("configuration file: $cfg. \n");

	print ("make: \'$make\' \n");

	my $params = config::getParams ($cfg);

	$log ||= $params -> {'log'};

	$srcs ||= $params -> {'srcs'};

	$objs ||= $params -> {'objs'};

	$prefix ||= $params -> {'prefix'};

	$opts .= ' ' . $params -> {'opts'};

	print ("sources directory: $srcs \n");

	print ("objects directory: $objs \n");

	print ("log file: $log \n");

	-d $srcs || die ("Error: the sources directory does not exist.\n");

	-d $objs || die ("Error: the objects directory does not exist.\n");

	$srcs = Cwd::abs_path ($srcs);

	$objs = Cwd::abs_path ($objs);

	$log = Cwd::abs_path ($log);

	updateLog ("\ninstalling: " . $pkg -> {'name'} . "\n");

	updateLog ("\tpackage: " . $pkg -> {'file'} . "\n");

	updateLog ("\tprefix: $prefix\n");

        if ($skipConfigure) {
          updateLog ("\tconfiguration skipped.\n");
        } else {
	  updateLog ("\tconfiguration options: $opts\n");
        }

        updateLog ("\tmake command: $make\n");

	if ($inSrc) {
		updateLog ("\tcompiled in source directory.\n");
	}

	my @time = gmtime (time ());

	my $timestamp = sprintf ('%02d.%02d.%02d:%02d:%02d:%02d', $time [4] + 1, $time [3], $time [5] % 100, $time [2], $time [1], $time [0]);

	updateLog ("\tdate: " . $timestamp . "\n");

	# [2] create package source directory:

	$pkg -> {'src'} = File::Spec -> catfile ($srcs, $pkg -> {'name'});

        if (-e $pkg -> {'src'}) {
		print ("the source directory already exists.\n");
	} else {
		print ("package source directory: " . $pkg -> {'src'} . "\n");

		system ("mkdir --parents " . $pkg -> {'src'}) && die ("Error: could not create the package source directory.\n");

		print ("created package source directory.\n");
	}

	if (-e $pkg -> {'src'} . '/' . $pkg -> {'file'}) {
		print ("the source directory already contains a copy of the package.\n")
        } else {
		system ("cp " . $pkg -> {'path'} . " " . $pkg -> {'src'}) && die ("Error: could not copy package into source directory.\n");

		print ("copied package into source directory.\n");
	}

	chdir ($pkg -> {'src'}) || die ("Error: could not chdir into package source directory.\n");

	# [3] decompress and untar package:

	my $msg = "Error: decompression failed";
 	my $cmd = '';

	print ("file: " . $pkg -> {'file'} . "\n");

 	if ( -f $pkg -> {'file'}) {
		if ($pkg -> {'file'} =~ s/(\.tar\.bz2$|\.tar\.bz$|\.tbz2$|\.tbz$)//) {
			$cmd = "tar --bzip2 -xvf " . $pkg -> {'file'} . $1;
		} elsif ($pkg -> {'file'} =~ s/(\.tar\.gz$|\.tar\.z$|\.tar\.Z$|\.tgz$|\.taz$)//) {
			$cmd = "tar --gzip -xvf " . $pkg -> {'file'} . $1;
		} elsif ($pkg -> {'file'} =~ s/(\.tar\.lzma)$//) {
			$cmd = "tar --lzma -xvf " . $pkg -> {'file'} . $1;
		} elsif ($pkg -> {'file'} =~ s/(\.tar)$//) {
			$cmd = "tar -xvf " . $pkg -> {'file'} . $1;
		} else {
			die ($msg . " The file has an unrecognized file suffix (" . $pkg -> {'file'} . ").\n");
		}
		system ($cmd) && die ($msg . '.');

		print ("decompressed and untarred the package.\n");
	} elsif ( -d $pkg -> {'file'}) {
		print ("package is already untarred and decompressed.\n");
	} else {
		die ("Error: The package is neither a file or a directory. Does the package exist?\n");
	}

	$pkg -> {'vsrc'} = File::Spec -> catfile ($pkg -> {'src'}, $pkg -> {'file'});

	# [4] create package object directory:

	$pkg -> {'obj'} = File::Spec -> catfile ($objs, $pkg -> {'name'});

	print ("package object directory: " . $pkg -> {'obj'} . "\n");

	if (-e $pkg -> {'obj'}) {
		print ("a package object directory already exists.\n");
	} else {
		system ("mkdir --parents " . $pkg -> {'obj'}) && die ("Error: could not create the package object directory.\n");

		print ("created package object directory.\n");
	}

	# [5] create package version object directory:

	$pkg -> {'vobj'} = File::Spec -> catfile ($pkg -> {'obj'}, $pkg -> {'file'});

	print ("package version object directory: " . $pkg -> {'vobj'} . "\n");

	if (-e $pkg -> {'vobj'}) {
		print ("a package version object directory already exists. renaming it.\n");

		system ("mv " . $pkg -> {'vobj'} . " " . $pkg -> {'vobj'} . "-$timestamp") && die ("Error: could not backup the original version object directory.\n");

		print ("append '$timestamp' to the original version object directory.\n");
	}

	if ($inSrc) {
		system ("cp -rf " . $pkg -> {'file'} . " " . $pkg -> {'obj'}) && die ("Error: could not move the source directory into the object directory.\n");
	} else {
		system ("mkdir --parents " . $pkg -> {'vobj'}) && die ("Error: could not create the package version object directory.\n");
	}

	print ("created the package version object directory.\n");

	chdir ($pkg -> {'vobj'}) || die ("Error: could not chdir into package version object directory.\n");

	if ($interactive) { promptContinue (); }

	# [6] configuring package:

        if (!$skipConfigure) {
		if ($autoconf) {
			updateLog ("\tgenerating the configure script using autoconf.\n");

			system ("autoconf") && abort ("\tconfiguration failed.\n", "Error: autoconf failed. Did you add the --in-source option? Is autoconf installed?\n");

			updateLog ("\tgenerated the configure script using autoconf.\n");
		}

		if ($inSrc) {
			$pkg -> {'configure'} = $pkg -> {'vobj'};
		} else {
			$pkg -> {'configure'} = File::Spec -> catfile ($pkg -> {'src'}, $pkg -> {'file'});
		}

	        if (!$configure) {
			$configure = findFile ($pkg -> {'configure'}, '^configure$');
		}

		if (!$configure && $interactive) {
			print ("Could not find the configure script.\n");
			print ("Please enter a path to the configure script.\n");
			$configure = <>;
			chomp ($configure);
			$configure = Cwd::abs_path ($configure);
			print ("Using: $configure.\n");
		} else {
	        	$configure = File::Spec -> catfile ($pkg -> {'configure'}, $configure);
		}

                if ($prefix) {
                  $configure .= " --prefix=$prefix"
                }
		$configure .= " $opts";

	        updateLog ("\tconfigure command: $configure\n");

		system ($configure) && abort ("\tconfiguration failed.\n", "Error: An error occured while trying to execute the configure script.\n");

		print ("configured package.\n");

		updateLog ("\tconfigured package.\n");


	} else {
		updateLog ("\tskipping configuration.\n");

		print ("skipping configuration.\n");
	}

	if ($interactive) { promptContinue (); }

	# [7] compile package:

	# [7.a] check that the makefile supports the uninstall target:

	if ($interactive) {
		$makefile = findFile ($pkg -> {'vobj'}, '^makefile$');

		if ($makefile) {
			if (system ("grep 'uninstall\ *:' $makefile")) {
				print ("The makefile does not support the uninstall target.\n Do you want to continue using the current prefix? ($prefix) \n Note: you should not use /usr or /usr/local for the prefix in this case. Instead you should install the package under its own directory tree. Otherwise you will have to manually remove each file installed by this package.\n");
				promptContinue ();
			} else {
				print ("The makefile MIGHT NOT support the uninstall target. Make sure that you can uninstall the package before continuing.\n");
				promptContinue ();
			}
		} else {
			print ("Could not find the makefile. Could not confirm that the makefile supports the uninstall target.\n");
			promptContinue ();
		}
	}

	system ("$make") && abort ("\tcompilation failed.\n", "Error: could not compile package.\n");

	print ("compiled package.\n");

	updateLog ("\tcompiled package.\n");

	if ($interactive) { promptContinue (); }

	# [8] install package:

	if (system ("make install")) {
		print ("Error: could not install package.\n");

		system ("make uninstall");

		updateLog ("\tinstallation failed.\n");
	} else {
		print ("installed package.\n");

		updateLog ("\tinstalled package.\n");

		print ("Note: If the package defines new shared libraries, and you installed the package in a non-standard location, make sure that you add the package's lib directory to ld's search path. see the notes at the end of the help screen for more information.\n");
	}

	exit 0;
}

# abort:
sub abort ($$) {
	updateLog ($_[0]);

	die ($_[1]);
}

# get path components (file, path, suffix):
sub parsePath ($) { return File::Basename::fileparse ($_[0], qr/\.[^.]*/); }

# get file components (file, suffix):
sub parseFile ($) {
	my @comps = parsePath ($_[0]);

	return ($comps [0], $comps [2]);
}

# update log:
sub updateLog ($) {
	open (hdl, ">>$log") || die ("Error: could not open log file. $!");

	print (hdl $_[0]);

	close (hdl);
}

# prompt user to continue:
sub promptContinue () {
	print ("continue? [y/n]");
	$input = <>;
	print ("input: " . $input);
	unless ($input =~ m/y/i) { abort ("\tuser aborting...\n", "aborting..."); }
}

# Returns the name of the file that matches the given pattern in the given directory:
sub findFile ($$) {
	my ($dir, $pattern) = @_;
	my $file = undef;

	opendir (hdl, $dir) || die ("Error: could not open the directory (" . $dir . ").");

	foreach my $name (readdir (hdl)) {
		if ($name =~ m/$pattern/i) {
                        $file = $name;
			last;
		}
	}	
	close (hdl);
	return $file;
}
