# defines functions for parsing the install configuration file.

package config;

BEGIN
{
	use Exporter ();
	@ISA     = "Exporter";
	@EXPORT  = "&getParams";
	$VERSION = 1.00;
}

# parses the install configuration file:
sub getParams ($)
{
	my $fileName = $_[0];

	my %params;

	# open configuration file:
	open (fileHandle, "<$fileName") || die ("Error: could not open configuration file ($fileName).");

	# get configuration parameters:

		my $lineNumber = 0;

	foreach my $line (readline (fileHandle))
	{
		$lineNumber ++;

		# remove comments:
		$line =~ s/#[^\n]*//;

		# ignore blank lines:
		if ($line =~ m/^\s*$/)
		{
			next;
		}
		elsif ($line =~ m/([^:]+)\s*:\s*([^\n]*)/)
		{
			my ($name, $value) = ($1, $2);

			# removes trailing whitespaces:
			$value =~ s/\s*$//;

			# set parameter values:
			if ($name =~ m/^\s*srcs\s*$/)
			{
				$params {'srcs'} = $value;
			}
			elsif ($name =~ m/^\s*objs\s*$/)
			{
				$params {'objs'} = $value;
			}
			elsif ($name =~ m/^\s*opts\s*$/)
			{
				$params {'opts'} = $value;
			}
			elsif ($name =~ m/^\s*prefix\s*$/)
			{
				$params {'prefix'} = $value;
			}
			elsif ($name =~ m/^\s*log\s*$/)
			{
				$params {'log'} = $value;
			}
			else
			{
				die ("Error: the configuration file contains an invalid parameter name on line $lineNumber.");
			}
		}
		else
		{
			die ("Error: the configuration file contains a syntax error on line $lineNumber.\n");
		}
	}

	# check parameter values:

		my $msg = 'Error: invalid configuration file';

	foreach my $name ('srcs', 'objs', 'opts', 'prefix', 'log')
	{
		if (!defined ($params {$name}))
		{
			die ("Error: invalid configuration file (the \'$name\' parameter is undefined).");
		}
	}

	return \%params;
}

return 1;
END {}
