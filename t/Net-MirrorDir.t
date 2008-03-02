# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-MirrorDir.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

 use Test::More tests => 230;
# use Test::More "no_plan";
 BEGIN { use_ok('Net::MirrorDir') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
 my $mirror = Net::MirrorDir->new(
 	localdir		=> "TestA",
 	remotedir	=> "TestD",
 	ftpserver		=> "www.net.de",
 	usr		=> 'e-mail@address.de',
 	pass		=> "xyz", 	
 	);
 isa_ok($mirror, "Net::MirrorDir");
#-------------------------------------------------
# tests for methods
 can_ok($mirror, "_Init");
 ok(!$mirror->_Init());
 can_ok($mirror, "Connect");
 can_ok($mirror, "IsConnection");
 can_ok($mirror, "Quit");
 ok($mirror->Quit());
#-------------------------------------------------
# tests for ReadLocalDir()
 can_ok($mirror, "ReadLocalDir");
 ok(my ($rh_lf, $rh_ld) = $mirror->ReadLocalDir());
 warn("local files : $_\n") for(sort keys(%{$rh_lf}));
 warn("local dirs : $_\n") for(sort keys(%{$rh_ld}));
#-------------------------------------------------
 can_ok($mirror, "ReadRemoteDir");
 my $rh_test_rf =
 	{
	"TestD/TestB/TestC/Dir1/test1.txt"		=> 1,
 	"TestD/TestB/TestC/Dir2/test2.txt"		=> 1,
 	"TestD/TestB/TestC/Dir2/test2.subset"	=> 1,
 	#"TestD/TestB/TestC/Dir3/test3.txt"	=> 1,
 	"TestD/TestB/TestC/Dir4/test4.txt"		=> 1,
 	"TestD/TestB/TestC/Dir4/test4.exclusions"	=> 1,
 	"TestD/TestB/TestC/Dir5/test5.txt"		=> 1,
 	};
 my $rh_test_rd =
 	{
 	"TestD/TestB"		=> 1,
 	"TestD/TestB/TestC"	=> 1,
 	"TestD/TestB/TestC/Dir1"	=> 1,
 	"TestD/TestB/TestC/Dir2"	=> 1,
 	#"TestD/TestB/TestC/Dir3"	=> 1,
 	"TestD/TestB/TestC/Dir4" 	=> 1,
 	"TestD/TestB/TestC/Dir5"	=> 1,
 	};
#-------------------------------------------------
# tests for compare files or directories
 can_ok($mirror, "LocalNotInRemote");
 ok($mirror->LocalNotInRemote({}, {}));
 ok(my $ra_lfnir = $mirror->LocalNotInRemote($rh_lf, $rh_test_rf));
 ok("TestA/TestB/TestC/Dir3/test3.txt" eq $ra_lfnir->[0]);
 ok(my $ra_ldnir = $mirror->LocalNotInRemote($rh_ld, $rh_test_rd));
 ok("TestA/TestB/TestC/Dir3" eq $ra_ldnir->[0]);
 can_ok($mirror, "RemoteNotInLocal");
 ok($mirror->RemoteNotInLocal({}, {}));
 $rh_test_rf->{"TestD/TestB/TestC/Dir6/test6.txt"} = 1;
 $rh_test_rd->{"TestD/TestB/TestC/Dir6"} = 1;
 ok(my $ra_rfnil = $mirror->RemoteNotInLocal($rh_lf, $rh_test_rf));
 ok("TestD/TestB/TestC/Dir6/test6.txt" eq $ra_rfnil->[0]);
 ok(my $ra_rdnil = $mirror->RemoteNotInLocal($rh_ld, $rh_test_rd));
 ok("TestD/TestB/TestC/Dir6" eq $ra_rdnil->[0]);
 ok($mirror->SetExclusions([]));
 ok($mirror->SetSubset([]));
 ok($mirror->ReadLocalDir("TestA"));
 ok($mirror->SetRemoteDir("TestD"));
 ok($mirror->SetLocalDir("TestA"));
 ok($mirror->GetLocalFiles());
 ok($mirror->GetLocalDirs());
 ok($ra_lfnir = $mirror->LocalNotInRemote($mirror->GetLocalFiles(), $rh_test_rf));
 ok("TestA/TestB/TestC/Dir3/test3.txt" eq $ra_lfnir->[0]);
 ok($ra_ldnir = $mirror->LocalNotInRemote($mirror->GetLocalDirs(), $rh_test_rd));
 ok("TestA/TestB/TestC/Dir3" eq $ra_ldnir->[0]);
 ok($ra_rfnil = $mirror->RemoteNotInLocal($mirror->GetLocalFiles(), $rh_test_rf));
 ok("TestD/TestB/TestC/Dir6/test6.txt" eq $ra_rfnil->[0]);
 ok($ra_rdnil = $mirror->RemoteNotInLocal($mirror->GetLocalDirs(), $rh_test_rd));
 ok("TestD/TestB/TestC/Dir6" eq $ra_rdnil->[0]);
#-------------------------------------------------
# tests for set and get
 ok(!$mirror->set_Item());
 ok(!$mirror->get_Item());
 ok(!$mirror->GETItem());
 ok(!$mirror->Get_Item());
 ok($mirror->SET____Remotedir("Homepage"));
 ok(!$mirror->WrongFunction());
 ok(Net::MirrorDir::SetExclusions($mirror, ["sys"]));
 ok(Net::MirrorDir::GetExclusions($mirror)->[0] eq "sys");
 ok(Net::MirrorDir::SetSubset($mirror, ["my_files"]));
 ok(Net::MirrorDir::GetSubset($mirror)->[0] eq "my_files");
 ok(Net::MirrorDir::SetSubset($mirror, []));
 ok($mirror->SetFtpServer("home.perl.de"));
 ok(my $server = $mirror->GetFtpServer());
 ok($server eq "home.perl.de");
 ok($mirror->Set_localdir("home"));
 ok(my $localdir = $mirror->GetLocalDir());
 ok($localdir eq "home");
 ok($mirror->Setremotedir("website"));
 ok(my $remotedir = $mirror->GetRemotedir());
 ok($remotedir eq "website");
 ok($mirror->Set_ftpserver("ftp.net.de"));
 ok(my $ftpserver = $mirror->Get_Ftpserver());
 ok($ftpserver eq "ftp.net.de");
 ok($mirror->set_usr("myself"));
#-------------------------------------------------
# tests for add
 ok(Net::MirrorDir::SetExclusions($mirror, []));
 ok(Net::MirrorDir::SetSubset($mirror, []));
 my $count = 0;
 for(A..Z)
 	{
 	ok($mirror->add_exclusions($_));
 	ok($mirror->add_subset($_));
 	ok($#{$mirror->get_exclusions()} == $count);
 	ok($#{$mirror->get_subset()} == $count++);
 	}
 ok(!$mirror->add_timeout(30));
 ok(!$mirror->add_wrong("txt"));
#-------------------------------------------------
# tests for "exclusions"
 ok($mirror->SetLocalDir("TestA"));
 ok($mirror->Set_exclusions(["exclusions"]));
 ok(my $ref_exclusions = $mirror->Get_exclusions());
 ok($ref_exclusions->[0] eq "exclusions");
 ok($mirror->ReadLocalDir());
# PrintFound();
 ok(!("TestA/TestB/TestC/Dir4/test4.exclusions" eq $_)) for(keys(%{$mirror->GetLocalFiles()}));
 ok($mirror->SetExclusions([qr/TXT/i]));
 ok($mirror->ReadLocalDir());
# PrintFound();
 ok(MyCount() == 2);
 ok($mirror->AddExclusions(qr/SuBsEt/i));
 ok($mirror->ReadLocalDir());
# PrintFound();
 ok(MyCount() == 1);
 ok($mirror->add_exclusions("exclusions"));
 ok($mirror->ReadLocalDir());
# PrintFound();
 ok(MyCount() == 0);
#-------------------------------------------------
# tests for "subset"
 ok($mirror->Set_exclusions([]));
 ok($mirror->Set_subset(["subset"]));
 ok(my $ref_subset = $mirror->Get_subset());
 ok($ref_subset->[0] eq "subset");
 ok($mirror->ReadLocalDir());
# PrintFound();
 ok("TestA/TestB/TestC/Dir2/test2.subset" eq $_) for(keys(%{$mirror->GetLocalFiles()}));
 ok($mirror->SetSubset([qr/TXT/i]));
 ok($mirror->ReadLocalDir());
# PrintFound();
 ok(MyCount() == 5);
 ok($mirror->SetSubset([qr/SUBSET/i, qr/EXCLUSIONS/i]));
 ok($mirror->ReadLocalDir());
# PrintFound();
 ok(MyCount() == 2);
 ok($mirror->AddSubset(qr/TXT/i));
 ok($mirror->ReadLocalDir());
# PrintFound();
 ok(MyCount() == 7);
 ok($mirror->AddExclusions("txt"));
 ok($mirror->ReadLocalDir());
# PrintFound();
 ok(MyCount() == 2);
#-------------------------------------------------
# tests with ftp-server
 SKIP:
 	{
 	my $m = Net::MirrorDir->new(
 		localdir		=> 'TestA',
 		remotedir	=> '/authors/id/K/KN/KNORR/Remote/TestA',
 		ftpserver		=> 'www.cpan.org',
 		usr		=> 'anonymous',
 		pass		=> 'create-soft@tiscali.de', 	
 		exclusions	=> ['CHECKSUMS']
 		);
 	skip("no tests with www.cpan.org\n", 12) unless($m->Connect());
 	ok($m->IsConnection());
 	ok(my ($rh_rf, $rh_rd) = $m->ReadRemoteDir());
	ok($m->Quit());
 	warn("remote files: $_\n") for(sort keys %{$rh_rf});
 	warn("remote dirs: $_\n") for(sort keys %{$rh_rd});
 	ok(($rh_lf, $rh_ld) = $m->ReadLocalDir());
 	warn("local files: $_\n") for(sort keys %{$rh_lf});
 	warn("local dirs: $_\n") for(sort keys %{$rh_ld});
 	ok($ra_lfnir = $m->LocalNotInRemote($rh_lf, $rh_rf));
 	ok($ra_ldnir = $m->LocalNotInRemote($rh_ld, $rh_rd));
 	ok($ra_rfnil = $m->RemoteNotInLocal($rh_lf, $rh_rf));
 	ok($ra_rdnil = $m->RemoteNotInLocal($rh_ld, $rh_rd));
 	warn("\n");
 	warn("local file not in remote: $_\n") for(@{$ra_lfnir});
 	warn("local dir not in remote: $_\n") for(@{$ra_ldnir});
 	warn("remote file not in local: $_\n") for(@{$ra_rfnil});
 	warn("remtoe dir not in local: $_\n") for(@{$ra_rdnil});
 	ok(@{$ra_lfnir} == 0);
 	ok(@{$ra_ldnir} == 0);
 	ok(@{$ra_rfnil} == 0);
 	ok(@{$ra_rdnil} == 0);
 	}
#-------------------------------------------------
 SKIP:
 	{
 	print(STDERR "\nWould you like to  test the module with a ftp-server?[y|n]: ");
 	my $response = <STDIN>;
 	skip("no tests with ftp-server\n", 10) unless($response =~ m/^y/i);
 	print(STDERR "\nPlease enter the hostname of the ftp-server: ");
 	my $s = <STDIN>;
 	chomp($s);
 	print(STDERR "\nPlease enter your user name: ");
 	my $u = <STDIN>;
 	chomp($u);
 	print(STDERR "\nPlease enter your password: ");
 	my $p = <STDIN>;
 	chomp($p);
	print(STDERR "\nPlease enter the local-directory which is to be compared: ");
 	my $l = <STDIN>;
 	chomp($l);
 	print(STDERR "\nPease enter the remote-directory which is to be compared: ");
 	my $r = <STDIN>;
 	chomp($r);
 	ok($m = Net::MirrorDir->new(
 		localdir		=> $l,
 		remotedir	=> $r,
 		ftpserver		=> $s,
 		usr		=> $u,
 		pass		=> $p, 	
 		));
 	ok($m->Connect());
 	ok($m->IsConnection());
 	ok(($rh_lf, $rh_ld) = $m->ReadLocalDir());
 	ok(($rh_rf, $rh_rd) = $m->ReadRemoteDir());
	ok($m->Quit());
 	ok($ra_lfnir = $m->LocalNotInRemote($rh_lf, $rh_rf));
 	ok($ra_ldnir = $m->LocalNotInRemote($rh_ld, $rh_rd));
 	ok($ra_rfnil = $m->RemoteNotInLocal($rh_lf, $rh_rf));
 	ok($ra_rdnil = $m->RemoteNotInLocal($rh_ld, $rh_rd));
 	warn("\n");
 	warn("local file not in remote: $_\n") for(@{$ra_lfnir});
 	warn("local dir not in remote: $_\n") for(@{$ra_ldnir});
 	warn("remote file not in local: $_\n") for(@{$ra_rfnil});
 	warn("remote dir not in local: $_\n") for(@{$ra_rdnil});	    
 	}
#-------------------------------------------------
 sub MyCount
 	{
 	#my $count = 0;
 	#for(keys(%{$mirror->GetLocalFiles()})){$count++;}
 	#return($count);
 	my @count = %{$mirror->GetLocalFiles()}; 
 	return(@count / 2);
 	}
#-------------------------------------------------
 sub PrintFound
 	{
 	 warn("\nfound: $_\n")for(keys(%{$mirror->GetLocalFiles()}));
 	}
#-------------------------------------------------







