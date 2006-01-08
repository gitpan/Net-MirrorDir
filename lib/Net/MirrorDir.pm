#!/usr/local/bin/perl5.9.2 -w
#*** MirrorDir.pm ***#
# Copyright (C) 2006 Torsten Knorr
# create-soft@tiscali.de
# All rights reserved!
#-------------------------------------------------
 package Net::MirrorDir;
#-------------------------------------------------
 use strict;
 use warnings;
 use Net::FTP;
 use vars '$AUTOLOAD';
#-------------------------------------------------
 our $VERSION = '0.02';
#-------------------------------------------------
 sub new
 	{
 	my ($class, %arg) = @_;
 	my $self =
 		{
 		_localdir		=> $arg{localdir}		|| '.',
 		_remotedir	=> $arg{remotedir}	|| '/',
 		_ftpserver	=> $arg{ftpserver}		|| warn("missing ftpserver"),
 		_usr		=> $arg{usr}		|| warn("missing username"),
 		_pass		=> $arg{pass}		|| warn("missing password"),
 		_debug		=> $arg{debug}		|| 1,
 		_timeout		=> $arg{timeout}		|| 30,
 		_delete		=> $arg{delete}		|| "disabled",
 		_connection	=> $arg{connection}	|| undef,
 		_exclusions	=> $arg{exclusions}	|| [],
 		};
 	bless($self, $class || ref($class));
 	return $self;
 	}
#-------------------------------------------------
 sub Connect
 	{
 	my ($self) = @_;
 	return $self->{_connection} if($self->{_connection});
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
 		}
 	return 1;
 	}
#-------------------------------------------------
 sub Quit
 	{
 	my ($self) = @_;
 	$self->{_connection}->quit() if($self->{_connection});
 	$self->{_connection} = undef;
 	return 1;
 	}
#-------------------------------------------------
 sub ReadLocalDir
 	{ 
 	my ($self, $path) = @_;
 	delete($self->{_localfiles}{$_}) for(keys(%{$self->{_localfiles}}));
 	delete($self->{_localdirs}{$_}) for(keys(%{$self->{_localdirs}}));
 	$self->{_readlocaldir} = sub
 		{
 		my ($self, $p) = @_;
 		if(-f $p)
 			{
 			$self->{_localfiles}{$p} = 1;
 			return $self->{_localfiles}, $self->{_localdirs};
 			}
 		if(-d $p)
 			{
 			$self->{_localdirs}{$p} = 1;
 			opendir(PATH, $p) or
 				die("error in opendir $p : 
 				at Net::MirrorDir::ReadLocalDir() : $!\n");
 			my @files = readdir(PATH);
 			closedir(PATH);
 			FILE: for my $file (@files)
 				{
 				next if(($file eq ".") or ($file eq ".."));
 				for(@{$self->{_exclusions}})
 					{
 					next FILE if($file =~ m/$_/);
 					}
 				$self->{_readlocaldir}->($self, "$p/$file");
 				}
 			return $self->{_localfiles}, $self->{_localdirs};
 			}
 		warn("$p is neither a file nor a directory\n");
 		};
 	return $self->{_readlocaldir}->($self, ($path or $self->{_localdir}));
 	}
#-------------------------------------------------
 sub ReadRemoteDir
 	{
 	my ($self, $path) = @_;
 	return if(!(defined($self->{_connection})));
 	delete($self->{_remotefiles}{$_}) for(keys(%{$self->{_remotefiles}}));
 	delete($self->{_remotedirs}{$_}) for(keys(%{$self->{_remotedirs}}));
 	$self->{_readremotedir} = sub 
 		{
 		my ($self, $p) = @_;
 		if(defined($self->{_connection}->size($p)))
 			{
 			$self->{_remotefiles}{$p} = 1;
 			return $self->{_remotefiles}, $self->{_remotedirs};
 			}
 		if($self->{_connection}->cwd($p))
 			{
 			$self->{_connection}->cwd();
 			$self->{_remotedirs}{$p} = 1;
 			my @files = $self->{_connection}->ls($p);
 			$self->{_readremotedir}->($self, "$p/$_") for(@files);
 			return $self->{_remotefiles}, $self->{_remotedirs};
 			}
 		warn("$p is neither a file nor a directory\n");
 		};
 	return $self->{_readremotedir}->($self, ($path or $self->{_remotedir}));
 	}
#-------------------------------------------------
 sub LocalNotInRemote
 	{
 	my ($self, $ref_h_local_paths, $ref_h_remote_paths) = @_;
 	my @files = ();
 	my $r_path;
 	for(keys(%{$ref_h_local_paths}))
 		{
 		$r_path = $_;
 		$r_path =~ s!^$self->{_localdir}!$self->{_remotedir}!;
 		push(@files, $_) if(!(defined($ref_h_remote_paths->{$r_path})));
 		}
 	return \@files;
 	}
#-------------------------------------------------
 sub RemoteNotInLocal
 	{
 	my ($self, $ref_h_local_paths, $ref_h_remote_paths) = @_;
 	my @files = ();
 	my $l_path;
 	for(keys(%{$ref_h_remote_paths}))
 		{
 		$l_path = $_;
 		$l_path =~ s!^$self->{_remotedir}!$self->{_localdir}!;
 		push(@files, $_) if(!(defined($ref_h_local_paths->{$l_path})));
 		}
 	return \@files;
 	}
#-------------------------------------------------
 sub AUTOLOAD
 	{
 	no strict "refs";
 	my ($self, $value) = @_;
 	if($AUTOLOAD =~ m/(?:\w|:)*::(?i:get)_*(\w+)/)
 		{
 		my $attr = lc($1);
 		$attr = '_' . $attr;
 		if(exists($self->{$attr}))
 			{
 			*{$AUTOLOAD} = sub
 				{
 				return $_[0]->{$attr};
 				};
 			return $self->{$attr};
 			}
 		else
 			{
 			warn("NO such attriute : $attr\n");
 			}
 		}
 	elsif($AUTOLOAD =~ m/(?:\w|:)*::(?i:set)_*(\w+)/) 
 		{
 		my $attr = lc($1);
 		$attr = '_' . $attr;
 		if(exists($self->{$attr}))
 			{
 			*{$AUTOLOAD} = sub
 				{
 				$_[0]->{$attr} = $_[1];
 				return 1;
 				};
 			$self->{$attr} = $value;
 			return 1;
 			}
 		else
 			{
 			warn("NO such attribute : $attr\n");
 			}
 		}
 	else
 		{
 		warn("no such method : $AUTOLOAD\n");
 		}
 	return 1;
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

 or more detailed
 my $md = Net::MirrorDir->new(
 	ftpserver		=> "my_ftp.hostname.com",
 	usr		=> "my_ftp_usr_name",
 	pass		=> "my_ftp_password",
 	localdir		=> "home/nameA/homepageA",
 	remotedir	=> "public",
 	debug		=> 1 # 1 for yes, 0 for no
 	timeout		=> 60 # default 30
 	delete		=> "enable" # default "disabled"
 	connection	=> $ftp_object, # default undef
 	exclusions	=> ["private.txt", "Thumbs.db", ".sys", ".log"],
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
Howevr, it can be used, also for something other.
It can compare local-directories and remote-directories with each other.
In order to find which files where in which directory available.

=head1 Constructor and Initialization

=item (object) new (options)

=head2 required optines

=item ftpserver
the hostname of the ftp-server

=item usr	
the username for authentification

=item pass
password for authentification

=head2 optional optiones

=item localdir
local directory selecting information from, default '.'

=item remotedir
remote location selecting information from, default '/' 

=item debug
set it true for more information about the ftp-process, default 1 

=item timeout
the timeout for the ftp-serverconnection

=item delete
this attribute is used in the child-class Net::UploadMirror and
Net::DownloadMirror, default "disabled"

=item connection
takes a Net::FTP-object you should not use that,
instead of this call the Connect(); function to set the connection.
default undef

=item exclusions
a reference to a list of strings interpreted as regular-expressios ("regex") 
matching to something in the local pathnames, you do not want to list, 
default empty list [ ]

=head2 methods

=item (ref_hash_local_files, ref_hash_local_dirs) object->ReadLocalDir (void)
=item (ref_hash_local_files, ref_hash_local_dirs) object->ReadLocalDir (path)
=item (void) object->ReadLocalDir (path)
Returns two hashreferences first  the local-files, second the local-directorys
found in the directory given by the MirrorDir-object,
(uses the attribute "localdir") or given directly as parameter.
The values are in the keys. You can also call the functions 
 (ref_hash_local_dirs) object->GetLocalDirs()
 (ref_hash_local_files) object->GetLocalFiles()
in order to receive the results.

=item (ref_hash_remote_files, ref_hash_remote_dirs) object->ReadRemoteDir (void)
=item (ref_hash_remote_files, ref_hash_remote_dirs) object->ReadRemoteDir(path)
=item (void) object->ReadRemoteDir (path)
Returns two hashreferences first the remote-files, second the remote-directorys
found in the directory given by the MirrorDir-object,
(uses the attribute "remotedir") or given directly as parameter. 
The values are in the keys. You can also call the functions
 (ref_hash_remote_files) object->GetRemoteFiles()
 (ref_hash_remote_dirs) object->GetRemoteDirs()
in order to receive the results.

=item (1) object->Connect (void)
Makes the connection to the ftp-server.
Uses the attributes "ftpserver", "usr" and "pass" given by the MirrorDir-object.

=item (1) object->Quit (void)
Closes the connection with the ftp-server.

=item (ref_hash_local_paths, ref_hash_remote_paths) object->LocalNotInRemote (ref_list_new_paths)
Takes two hashreferences, given by the functions ReadLocalDir(); and ReadRemoteDir();
to compare with each other. Returns a reference of a list with files or directorys found in 
the local directory but not in the remote location. Uses the attribute "localdir" and 
"remotedir" given by the MirrorDir-object.

=item (ref_hash_local_paths, ref_hash_remote_paths) object->RemoteNotInLocal (ref_list_deleted_paths)
Takes two hashreferences, given by the functions ReadLocalDir(); and ReadRemoteDir();
to compare with each other. Returns a reference of a list with files or directorys found in 
the remote location but not in the local directory. Uses of the attribure "localdir" and 
"remotedir" given by the MirrorDir-object.

=item (value) object->get_option (void)
=item (1)  set_object->option (value)
The functions are generated by AUTOLOAD for all options.
The syntax is not case-sensitive and the character '_' is optional.

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

=head1 AUTHOR

Torsten Knorr, E<lt>knorrcpan@tiscali.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Torsten Knorr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.9.2 or,
at your option, any later version of Perl 5 you may have available.


=cut

