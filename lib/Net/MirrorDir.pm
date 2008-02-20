#*** MirrorDir.pm ***#
# Copyright (C) 2006 - 2008 by Torsten Knorr
# create-soft@tiscali.de
# All rights reserved!
#-------------------------------------------------
 use strict;
#-------------------------------------------------
 package Net::MirrorDir::LocalDir;
 sub TIESCALAR { my ($class, $obj) = @_; return(bless(\$obj, $class || ref($class))); }
 sub STORE { ${$_[0]}->{_regex_localdir} = qr!^\Q$_[1]\E!; }
 sub FETCH { return(${$_[0]}->{_localdir}); }
#-------------------------------------------------
 package Net::MirrorDir::RemoteDir;
 sub TIESCALAR { my ($class, $obj) = @_; return(bless(\$obj, $class || ref($class))); }
 sub STORE { ${$_[0]}->{_regex_remotedir} = qr!^\Q$_[1]\E!; }
 sub FETCH { return(${$_[0]}->{_remotedir}); }
#-------------------------------------------------
 package Net::MirrorDir::Exclusions;
 sub TIESCALAR { my ($class, $obj) = @_; return(bless(\$obj, $class || ref($class))); }
 sub STORE { @{${$_[0]}->{_regex_exclusions}} = map { qr/$_/ } @{${$_[0]}->{_exclusions}}; }
 sub FETCH { return(${$_[0]}->{_exclusions}); }
#-------------------------------------------------
 package Net::MirrorDir::Subset;
 sub TIESCALAR { my ($class, $obj) = @_; return(bless(\$obj, $class || ref($class))); }
 sub STORE { @{${$_[0]}->{_regex_subset}} = map { qr/$_/ } @{${$_[0]}->{_subset}}; }
 sub FETCH { return(${$_[0]}->{_subset}); }
#-------------------------------------------------
 package Net::MirrorDir;
#-------------------------------------------------
 use Net::FTP;
 use vars '$AUTOLOAD';
#-------------------------------------------------
 $Net::MirrorDir::VERSION = '0.13';
#-------------------------------------------------
 sub new
 	{
 	my ($class, %arg) = @_;
 	my $self =
 		{
 		_ftpserver	=> $arg{ftpserver}		|| warn("missing ftpserver"),
 		_usr		=> $arg{usr}		|| warn("missing username"),
 		_pass		=> $arg{pass}		|| warn("missing password"),
 		_debug		=> $arg{debug}		|| 1,
 		_timeout		=> $arg{timeout}		|| 30,
 		_connection	=> $arg{connection}	|| undef,
 		};
 	bless($self, $class || ref($class));
 	tie($self->{_localdir},	"Net::MirrorDir::LocalDir", $self);
 	tie($self->{_remotedir},	"Net::MirrorDir::RemoteDir", $self);
 	tie($self->{_exclusions},	"Net::MirrorDir::Exclusions", $self);
 	tie($self->{_subset},	"Net::MirrorDir::Subset", $self);
 	$self->{_localdir}		= $arg{localdir}	|| '.';
 	$self->{_remotedir}	= $arg{remotedir}	|| '/';
 	$self->{_exclusions}	= $arg{exclusions}	|| [];
 	$self->{_subset}		= $arg{subset}	|| [];
	$self->_Init(%arg) if(__PACKAGE__ ne ref($self));
 	return($self);
 	}
#-------------------------------------------------
 sub _Init
	{
	warn("\n\ncall to abstract method _Init() from package: " . ref($_[0]) . "\n");
 	return(0);
	}
#------------------------------------------------
 sub Connect
 	{
 	my ($self) = @_;
 	return($self->{_connection}) if($self->IsConnection());
 	eval
 		{
 	 	$self->{_connection} = Net::FTP->new(
 			$self->{_ftpserver},
 			Debug	=> $self->{_debug},
 			Timeout	=> $self->{_timeout},
 			) or warn("Cannot connect to $self->{_ftpserver} : $@\n");
 		if($self->{_connection}->login($self->{_usr}, $self->{_pass}))
 			{
 		 	$self->{_connection}->binary();
 			}
 		else
 			{
 			$self->{_connection}->quit();
 			$self->{_connection} = undef;
 			return(0);
 			}
 		return(1);
 		};
 	}
#-------------------------------------------------
 sub IsConnection
 	{
 	return(eval { $_[0]->{_connection}->pwd(); });
 	}
#-------------------------------------------------
 sub Quit
 	{
 	my ($self) = @_;
 	$self->{_connection}->quit() if($self->IsConnection());
 	$self->{_connection} = undef;
 	return(1);
 	}
#-------------------------------------------------
 sub ReadLocalDir
 	{ 
 	my ($self, $path) = @_;
 	$self->{_localfiles} = {};
 	$self->{_localdirs} = {};
 	$self->{_readlocaldir} = sub
 		{
 		my ($self, $p) = @_;
 		if(-f $p)
 			{
 			if(!@{$self->{_regex_subset}})
 				{
 				$self->{_localfiles}{$p} = 1;
 				return($self->{_localfiles}, $self->{_localdirs});
 				}
 			for(@{$self->{_regex_subset}})
 				{
 				if($p =~ $_)
 					{	
 					$self->{_localfiles}{$p} = 1;
 					last;
 					}
 				}
 			return($self->{_localfiles}, $self->{_localdirs});
 			}
 		elsif(-d $p)
 			{
 			$self->{_localdirs}{$p} = 1;
 			opendir(PATH, $p) or die("error in opendir $p $!\n");
 			my @files = grep { $_ ne '.' and $_ ne '..' } readdir(PATH);
 			closedir(PATH);
 			for my $file (@files)
 				{
 				next if(grep { $file =~ $_ } @{$self->{_regex_exclusions}});
 				$self->{_readlocaldir}->($self, "$p/$file");
 				}
 			return($self->{_localfiles}, $self->{_localdirs});
 			}
 		warn("$p is neither a file nor a directory\n");
		return($self->{_localfiles}, $self->{_localdirs});
 		};
 	return($self->{_readlocaldir}->($self, ($path or $self->{_localdir})));
 	}
#-------------------------------------------------
 sub ReadRemoteDir
 	{
 	my ($self, $dir) = @_;
 	my $d = $dir || $self->{_remotedir};
 	return({}, {}) unless($self->IsConnection() && $d);
 	return({}, {}) unless(eval { $self->{_connection}->cwd($d) || $self->{_connection}->size($d); });
 	$self->{_connection}->cwd();
 	$self->{_remotefiles} = {};
 	$self->{_remotedirs} = {};
 	$self->{_readremotedir} = sub 
 		{
 		my ($self, $p) = @_;
 		if(defined($self->{_connection}->size($p)))
 			{
 			if(!@{$self->{_regex_subset}})
 				{
 				$self->{_remotefiles}{$p} = 1;
 				return($self->{_remotefiles}, $self->{_remotedirs});
 				}
 			for(@{$self->{_regex_subset}})
 				{
 				if($p =~ $_)
 					{
 					$self->{_remotefiles}{$p} = 1;
 					last;
 					}
 				}
 			return($self->{_remotefiles}, $self->{_remotedirs});
 			}
 		else
 			{
 			$self->{_remotedirs}{$p} = 1;
			for my $file ($self->{_connection}->ls($p))
 				{
 				next if(grep { $file =~ $_ } @{$self->{_regex_exclusions}});
 				$self->{_readremotedir}->($self, "$p/$file");
 				}
 			return($self->{_remotefiles}, $self->{_remotedirs});
 			}
 		};
 	return($self->{_readremotedir}->($self, $d));
 	}
#-------------------------------------------------
 sub LocalNotInRemote
 	{
 	my ($self, $rh_lp, $rh_rp) = @_;
 	my @lnir = ();
 	my $rp;
 	for my $lp (keys(%{$rh_lp}))
 		{
 		$rp = $lp;
 		$rp =~ s!$self->{_regex_localdir}!$self->{_remotedir}!;
 		push(@lnir, $lp) unless(defined($rh_rp->{$rp}));
 		}
 	return(\@lnir);
 	}
#-------------------------------------------------
 sub RemoteNotInLocal
 	{
 	my ($self, $rh_lp, $rh_rp) = @_;
 	my @rnil = ();
 	my $lp;
 	for my $rp (keys(%{$rh_rp}))
 		{
 		$lp = $rp;
 		$lp =~ s!$self->{_regex_remotedir}!$self->{_localdir}!;
 		push(@rnil, $rp) unless(defined($rh_lp->{$lp}));
 		}
 	return(\@rnil);
 	}
#-------------------------------------------------
 sub AUTOLOAD
 	{
 	no strict "refs";
 	my ($self, $value) = @_;
 	if($AUTOLOAD =~ m/.*::(?i:get)_*(\w+)/)
 		{
 		my $attr = lc($1);
 		$attr = '_' . $attr;
 		if(exists($self->{$attr}))
 			{
 			*{$AUTOLOAD} = sub
 				{
 				return($_[0]->{$attr});
 				};
 			return($self->{$attr});
 			}
 		else
 			{
 			warn("\nNO such attribute : $attr\n");
 			}
 		}
 	elsif($AUTOLOAD =~ m/.*::(?i:set)_*(\w+)/) 
 		{
 		my $attr = lc($1);
 		$attr = '_' . $attr;
 		if(exists($self->{$attr}))
 			{
 			*{$AUTOLOAD} = sub
 				{
 				$_[0]->{$attr} = $_[1];
 				return(1);
 				};
 			$self->{$attr} = $value;
 			return(1);
 			}
 		else
 			{
 			warn("\nNO such attribute : $attr\n");
 			}
 		}
 	elsif($AUTOLOAD =~ m/.*::(?i:add)_*(\w+)/)
 		{
 		my $attr = lc($1);
 		$attr = '_' . $attr;
 		if(ref($self->{$attr}) eq "ARRAY")
 			{
 			*{$AUTOLOAD} = sub
 				{
 				$_[0]->{$attr} = [@{$_[0]->{$attr}}, $_[1]];
 				return(1);
 				};
 			$self->{$attr} = [@{$self->{$attr}}, $value]; 
 			return(1);
 			}
 		else
 			{
 			warn("\nNO such attribute or NOT a array reference: $attr\n");
 			}
 		}
 	else
 		{
 		warn("\nno such method : $AUTOLOAD\n");
 		}
 	return(0);
 	}
#-------------------------------------------------
 sub DESTROY
 	{
 	my ($self) = @_;
 	if($self->{_debug})
 		{
 		my $class = ref($self);
 		print("$class object destroyed\n");
 		} 
 	}
#-------------------------------------------------
1;
#-------------------------------------------------
__END__

=head1 NAME

Net::MirrorDir - Perl extension for compare local-directories and remote-directories with each other

=head1 SYNOPSIS

  use Net::MirrorDir;
  my $md = Net::MirrorDir->new(
 	ftpserver		=> "my_ftp.hostname.com",
 	usr		=> "my_ftp_usr_name",
 	pass		=> "my_ftp_password",
 	);
 my ($ref_h_local_files, $ref_h_local_dirs) = $md->ReadLocalDir();
 my ($ref_h_remote_files, $ref_h_remote_dirs) = $md->ReadRemoteDir();
 my $ref_a_new_remote_files = $md->RemoteNotInLocal($ref_h_local_files, $ref_h_remote_files);
 my $ref_a_new_local_files = $md->LocalNotInRemote($ref_h_local_files, $ref_h_remote_files);
 $md->Quit();

 or more detailed
 my $md = Net::MirrorDir->new(
 	ftpserver		=> "my_ftp.hostname.com",
 	usr		=> "my_ftp_usr_name",
 	pass		=> "my_ftp_password",
 	localdir		=> "home/nameA/homepageA",
 	remotedir	=> "public",
 	debug		=> 1 # 1 for yes, 0 for no
 	timeout		=> 60 # default 30
 	connection	=> $ftp_object, # default undef
# "exclusions" default references to a empty array []
 	exclusions	=> ["private.txt", "Thumbs.db", ".sys", ".log"],
# "subset" default references to a empty array []
 	subset		=> [".txt, ".pl", ".html", "htm", ".gif", ".jpg", ".css", ".js", ".png"]
# or substrings in pathnames
#	exclusions	=> ["psw", "forbidden_code"]
#	subset		=> ["name", "my_files"]
# or you can use regular expressions
# 	exclusinos	=> [qr/SYSTEM/i, $regex]
# 	subset		=> {qr/(?i:HOME)(?i:PAGE)?/, $regex]
 	);
 $md->SetLocalDir("home/name/homepage");
 print("hostname : ", $md->get_ftpserver(), "\n");
 $md->Connect();
 my ($ref_h_local_files, $ref_h_local_dirs) = $md->ReadLocalDir();
 if($md->{_debug})
 	{
 	print("local files : $_\n") for(sort keys %{$ref_h_local_files});
 	print("local dirs : $_\n") for(sort keys %{$ref_h_local_dirs});
 	}	
 my ($ref_h_remote_files, $ref_h_remote_dirs) = $md->ReadRemoteDir();
 if($md->{_debug})
 	{
 	print("remote files : $_\n") for(sort keys %{$ref_h_remote_files});
 	print("remote dirs : $_\n") for(sort keys %{$ref_h_remote_dirs});
 	}
 my $ref_a_new_local_files = $md->LocalNotInRemote($ref_h_local_files, $ref_h_remote_files);
 if($md->{_debug})
 	{
 	print("new local files : $_\n") for(@{$ref_a_new_local_files});
 	}
 my $ref_a_new_local_dirs = $md->LocalNotInRemote($ref_h_local_dirs, $ref_h_remote_dirs);
 if($md->{_debug})
 	{
 	print("new local dirs : $_\n") for(@{$ref_a_new_local_dirs});
 	}
 my $ref_a_new_remote_files = $md->RemoteNotInLocal($ref_h_local_files, $ref_h_remote_files);
 if($md->{_debug})
 	{
 	print("new remote files : $_\n") for(@{$ref_a_new_remote_files});
 	}
 my $ref_a_new_remote_dirs = $md->RemoteNotInLocal($ref_h_local_dirs, $ref_h_remote_dirs);
 if($md->{_debug})
 	{
 	print("new remote dirs : $_\n") for(@{$ref_a_new_remote_dirs});
 	}
 $md->Quit();

=head1 DESCRIPTION

This module is written as base class for Net::UploadMirror and Net::DownloadMirror.
However, it can be used, also for themselves alone.
It can compare local-directories and remote-directories with each other.
To find which files where in which directory available.

=head1 Constructor and Initialization

=item (object)Net::MirrrorDir->new(options)

=head2 required optines

=item ftpserver
the hostname of the ftp-server

=item usr	
the username for authentification

=item pass
password for authentification

=head2 optional optiones

=item localdir
local directory 
default = '.'

=item remotedir
remote location
default '/' 

=item debug
set it true for more information about the ftp-process
default 1 

=item timeout
the timeout for the ftp-serverconnection, default 30

=item connection
takes a Net::FTP-object, you should not create the object by yourself,
instead of this call the Connect(); function to set the connection.
default undef

=item exclusions
takes a reference to a array of strings interpreted as regular-expressios 
matching to something in the local or remote pathnames,
pathnames matching will be ignored
You can also use a regex object [qr/PASS/i, $regex, "system"]
default []

=item subset
takes a reference to a list of strings interpreted as regular-expressios 
matching to something in the local or remote pathnames,
pathnames NOT matching will be ignored.
You can also use a regex object [qr/TXT/i, "name", qr/MY_FILES/i, $regex]
default []

=head2 methods

=item (ref_hash_local_files, ref_hash_local_dirs)object->ReadLocalDir(void)
=item (ref_hash_local_files, ref_hash_local_dirs)object->ReadLocalDir(path)
The directory, indicated with the attribute "localdir" or directly as parameter, is searched.
Returns two hashreferences first  the local-files, second the local-directorys.
The values are in the keys. You can also call the functions: 
 (ref_hash_local_dirs)object->GetLocalDirs(void)
 (ref_hash_local_files)object->GetLocalFiles(void)
in order to receive the results.
If ReadLocalDir() fails, it returns references to empty hashs.

=item (ref_hash_remote_files, ref_hash_remote_dirs)object->ReadRemoteDir(void)
=item (ref_hash_remote_files, ref_hash_remote_dirs)object->ReadRemoteDir(path)
The directory, inidcated with the attribute "remotedir" or directly as parameter, is searched.
Returns two hashreferences first the remote-files, second the remote-directorys.
The values are in the keys. You can also call the functions:
 (ref_hash_remote_files)object->GetRemoteFiles(void)
 (ref_hash_remote_dirs)object->GetRemoteDirs(void)
in order to receive the results.
If ReadRemoteDir() fails, it returns references to empty hashs.

=item (1|0)object->Connect(void)
Makes the connection to the ftp-server.
Uses the attributes "ftpserver", "usr" and "pass".

=item (1)object->Quit(void)
Closes the connection with the ftp-server.

=item (ref_list_new_paths)object->LocalNotInRemote(ref_hash_local_paths, ref_hash_remote_paths)
Takes two hashreferences, first the localpaths, second the remotepaths,
to compare with each other. 
Returns a reference of a list with files or directorys found in 
the local directory but not in the remote location.

=item (ref_list_deleted_paths)object->RemoteNotInLocal(ref_hash_local_paths, ref_hash_remote_paths)
Takes two hashreferences, first the localpaths, second the remotepaths,
to compare with each other. 
Returns a reference of a list with files or directorys found in 
the remote location but not in the local directory.

=item (value)object->get_option(void)
=item (1)object->set_option(value)
The functions are generated by AUTOLOAD, for all options.
The syntax is not case-sensitive and the character '_' is optional.

=item (1) object->add_option(value)
The functions are generated by AUTOLOAD, for arrayrefrences options.
Like "subset" or "exclusions"
The syntax is not case-sensitive and the character '_' is optional.

=item (0) _Init(void)
 Abstract method should be defined in every derived class.

=head2 EXPORT

None by default.

=head1 SEE ALSO

Net::UploadMirror
Net::DownloadMirror
Net::FTP
http://www.planet-interkom.de/t.knorr/index.html

=head1 FILES

Net::FTP

=head1 BUGS

Maybe you'll find some. Let me know.

=head1 REPORTING BUGS

When reporting bugs/problems please include as much information as possible.

=head1 AUTHOR

Torsten Knorr, E<lt>create-soft@tiscali.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 - 2008 by Torsten Knorr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.9.2 or,
at your option, any later version of Perl 5 you may have available.


=cut









