# deletes a gnu package that was installed using install and logs the result.

use config;
use Cwd 'abs_path';
use File::Spec;
use File::Basename;
use Getopt::Long;

my $log;

{
	# [1] get command line parameters:

	my ($objs, $srcs, $pkg, $cfg);

	GetOptions
	(
		'objs=s'    => \$objs,
		'package=s' => \$pkg -> {'name'},
		'version=s' => \$pkg -> {'version'},
		'config=s'  => \$cfg,
		'log=s'     => \$log,

		'help' => sub {
			print
			(
				"Usage:                                              \n" .
				"	uninstall [options] --package=<package>      \n\n" .

				"Synopsis:                                           \n" .
				"		Uninstall uninstalls packages that   \n" .
				"	were installed using install.                \n\n" .

				"Detail:                                             \n" .
				"		Uninstall will execute \'make        \n" .
				"	uninstall\' from the package\'s version      \n" .
				"	object directory and then delete the         \n" .
				"	package's object directory.                  \n" .
				"		If the package has multiple version  \n" .
				"	object directories, and the version option   \n" .
				"	has not been set, it will execute \'make     \n" .
				"	uninstall\' from each directory and then     \n" .
				"	delete them.                                 \n" .
				"		Once the package version object      \n" .
				"	directories have been deleted, it will       \n" .
				"	delete the object directory.                 \n\n" .

				"Notes:                                              \n" .
				"		If the version option is set,        \n" .
				"	Uninstall will execute \'make uninstall\'    \n" .
				"	from the following directory:                \n" .
				"		<objs>/<pkg name>-<pkg version>      \n" .
				"	For example, if the object directory was set \n" .
				"	to \'/usr/objs\', the package name was       \n" .
				"	\'curl\', and the version was set to         \n" .
				"	\'1.2.3\', Uninstall would try to execute    \n" .
				"	\'make uninstall\' from:                     \n" .
				"		\'/usr/objs/curl-1.2.3\'             \n\n" .

				"Options:                                            \n" .
				"	\'--objs\'                                   \n" .
				"		The objects directory path. This     \n" .
				"	program will search for the package object   \n" .
				"	directory under this directory.              \n\n" .

				"	\'--package\'                                \n" .
				"		The package name. This program will  \n" .
				"	assume that the package object directory is  \n" .
				"	named this.                                  \n\n" .

				"	\'--version\'                                \n" .
				"		The package version. This program    \n" .
				"	assume that the package version object       \n" .
				"	directory is name \'<package>-<version>\'.   \n" .
				"	If this option is omitted, this program will \n" .
				"	delete every package version                 \n\n" .

				"	\'--config\'                                 \n" .
				"		The configuration file path. This    \n" .
				"	file will be used to set the default         \n" .
				"	parameter values. By default, this program   \n" .
				"	uses \'install.xml\'.                         \n\n" .

				"	\'--log\'                                    \n" .
				"		The log file path. Log messages will \n" .
				"	be recorded here. By default, this program   \n" .
				"	uses \'install.log\'.                        \n\n" .

				"	\'--delete-sources\'                         \n" .
				"		Will delete the package source       \n" .
				"	directories. If --version is specified, this \n" .
				"	program will only delete the version source  \n" .
				"	directory. Otherwise, it will delete the     \n" .
				"	the package source directory. This program   \n" .
				"	assumes that the version source directory is \n" .
				"	named \'<package>-<version>\'.               \n\n" .

				"Examples:                                           \n" .
				"		uninstall --package=curl             \n" .
				"		This command will uninstall the curl \n" .
				"	package.                                     \n"
			);

			exit (0);
		}
	);

	$pkg -> {'name'} || die ("Error: missing --package parameter.\n");

	# get configuration file parameters:

	$cfg ||= 'install.cfg';

	print ("configuration file: $cfg. \n");

	my $params = config::getParams ($cfg);

	$log ||= $params -> {'log'};

	$srcs = $params -> {'srcs'};

	$objs ||= $params -> {'objs'};

	print ("sources directory: $srcs.\n");

	print ("objects directory: $objs.\n");

	print ("log file: $log\n");

	-d $srcs || die ("Error: the sources directory does not exist.\n");

	-d $objs || die ("Error: the objects directory does not exist.\n");

	-e $log || die ("Error: the log file does not exist.\n");

	$srcs = Cwd::abs_path ($srcs);

	$objs = Cwd::abs_path ($objs);

	$log = Cwd::abs_path ($log);

	updateLog ("\nuninstalling: " . $pkg -> {'name'} . "\n");

	updateLog ("\tdate: " . gmtime () . "\n");

	# get package source directory:

	$pkg -> {'src'} = File::Spec -> catfile ($srcs, $pkg -> {'name'});

	print ("package source directory: " . $pkg -> {'src'} . "\n");

	-d $pkg -> {'src'} || abort ("package source directory does not exist.");

	# get package object directory:

	$pkg -> {'obj'} = File::Spec -> catfile ($objs, $pkg -> {'name'});

	print ("package object directory: " . $pkg -> {'obj'} . "\n");

	-d $pkg -> {'obj'} || abort ("package object directory does not exist.");

	# uninstall package:

		my $status;

	if ($pkg -> {'version'})
	{
		$pkg -> {'vname'} = $pkg -> {'name'} . "-" . $pkg -> {'version'};

		alert ("version: " . $pkg -> {'vname'});

		$pkg -> {'vdir'} = File::Spec -> catfile ($pkg -> {'obj'}, $pkg -> {'vname'});

		print ("package version object directory: " . $pkg -> {'vdir'} . "\n");

		-d $pkg -> {'vdir'} || abort ("package version object directory does not exist.");	

		chdir ($pkg -> {'vdir'}) || abort ("could not chdir into package version object directory.");

		system ("make uninstall") && abort ("could not unstall package.");

		system ("rm -rf " . $pkg -> {'vdir'}) && abort ("could not delete package version directory.");

		$pkg -> {'vsrc'} = File::Spec -> catfile ($pkg -> {'src'}, $pkg -> {'vname'});

		print ("package version source directory: " . $pkg -> {'vsrc'} . "\n");

		if (-d $pkg -> {'vsrc'})
		{
			system ("rm -rf " . $pkg -> {'vsrc'}) && abort ("could not delete version source directory.");
		}
		else
		{
			print ("could not find the version source directory.");
		}
	}
	else
	{
		opendir (hdl, $pkg -> {'obj'}) || abort ("could not open package object directory.");

		foreach my $dir (readdir (hdl))
		{
			my $name = $pkg -> {'name'};

			if ($dir =~ m/$name/i)
			{
				$dir = File::Spec -> catfile ($pkg -> {'obj'}, $dir);

				my $vname = File::Basename::fileparse ($dir);

				unless (chdir ($dir))
				{
					$status = 1;
					close (hdl);
					error ("could not chdir into package version object directory.");
				}

				if (system ("make uninstall"))
				{
					$status = 1;
					close (hdl);
					alert ("could not uninstall package version.");
				}
				else { alert ("uninstalled $vname."); }

				if (system ("rm -rf $dir"))
				{
					$status = 1;
					close (hdl);
					error ("could not delete package version directory.");
				}
				else { alert ("deleted $dir."); }

			}
		}

		system ("rm -rf " . $pkg -> {'obj'});
		
		system ("rm -rf " . $pkg -> {'src'});

		close (hdl);	
	}

	unless ($status) { alert ("uinstalled: " . $pkg -> {'name'} . "\n"); }

	exit (0);
}

# alert:
sub alert ($)
{
	my $msg = $_[0] . "\n";

	updateLog ("\t$msg");

	print ($msg);
}

# error:
sub error ($)
{
	my $msg = "Error: " . $_[0] . "\n";

	updateLog ("\t$msg");

	print (STDERR $msg);
}

# abort:
sub abort ($)
{
	my $msg = "Error: uninstall failed: " . $_[0] . "\n";

	updateLog ("\t$msg");

	die ($msg);
}

# update log:
sub updateLog ($)
{
	open (hdl, ">>$log") || die ("Error: could not open log file. $!");

	print (hdl $_[0]);

	close (hdl);
}
