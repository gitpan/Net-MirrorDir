# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-MirrorDir.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

 use Test::More tests => 463;
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
 can_ok($mirror, "Connect");
 ok($mirror->SetConnection(1));
 ok($mirror->Connect());
 ok($mirror->SetConnection(undef));
 can_ok($mirror, "Quit");
 ok($mirror->Quit());
 can_ok($mirror, "ReadLocalDir");
 ok(my ($ref_h_local_files, $ref_h_local_dirs) = $mirror->ReadLocalDir());
 warn("files : $_\n") for(sort keys(%{$ref_h_local_files}));
 warn("dirs : $_\n") for(sort keys(%{$ref_h_local_dirs}));
 can_ok($mirror, "ReadRemoteDir");
# for this test we need a connection to a FTP-Server
# ok(my $ref_remote_files, $ref_remote_dirs) = $mirror->ReadRemoteDir());
 my $ref_h_test_remote_files =
 	{
	"TestD/TestB/TestC/Dir1/test1.txt"		=> 1,
 	"TestD/TestB/TestC/Dir2/test2.txt"		=> 1,
 	"TestD/TestB/TestC/Dir2/test2.subset"	=> 1,
 	#"TestD/TestB/TestC/Dir3/test3.txt"	=> 1,
 	"TestD/TestB/TestC/Dir4/test4.txt"		=> 1,
 	"TestD/TestB/TestC/Dir4/test4.exclusions"	=> 1,
 	"TestD/TestB/TestC/Dir5/test5.txt"		=> 1,
 	};
 my $ref_h_test_remote_dirs =
 	{
 	"TestD"			=> 1,
 	"TestD/TestB"		=> 1,
 	"TestD/TestB/TestC"	=> 1,
 	"TestD/TestB/TestC/Dir1"	=> 1,
 	"TestD/TestB/TestC/Dir2"	=> 1,
 	#"TestD/TestB/TestC/Dir3"	=> 1,
 	"TestD/TestB/TestC/Dir4" 	=> 1,
 	"TestD/TestB/TestC/Dir5"	=> 1,
 	};
 can_ok($mirror, "LocalNotInRemote");
 ok(my $ref_a_new_local_files = $mirror->LocalNotInRemote(
 	$ref_h_local_files, $ref_h_test_remote_files));
 ok("TestA/TestB/TestC/Dir3/test3.txt" eq $ref_a_new_local_files->[0]);
 ok(my $ref_a_new_local_dirs = $mirror->LocalNotInRemote(
 	$ref_h_local_dirs, $ref_h_test_remote_dirs));
 ok("TestA/TestB/TestC/Dir3" eq $ref_a_new_local_dirs->[0]);
 can_ok($mirror, "RemoteNotInLocal");
 $ref_h_test_remote_files->{"TestD/TestB/TestC/Dir6/test6.txt"} = 1;
 $ref_h_test_remote_dirs->{"TestD/TestB/TestC/Dir6"} = 1;
 ok(my $ref_a_deleted_local_files = $mirror->RemoteNotInLocal(
 	$ref_h_local_files, $ref_h_test_remote_files));
 ok("TestD/TestB/TestC/Dir6/test6.txt" eq $ref_a_deleted_local_files->[0]);
 ok(my $ref_a_deleted_local_dirs = $mirror->RemoteNotInLocal(
 	$ref_h_local_dirs, $ref_h_test_remote_dirs));
 ok("TestD/TestB/TestC/Dir6" eq $ref_a_deleted_local_dirs->[0]);
 ok(!$mirror->set_Item());
 ok(!$mirror->get_Item());
 ok(!$mirror->GETItem());
 ok(!$mirror->Get_Item());
 ok($mirror->SET____Remotedir("Homepage"));
 ok(!$mirror->WrongFunction());
 ok($mirror->SetDebug(1));
 ok($mirror->GetDelete());
 ok(Net::MirrorDir::SetExclusions($mirror, ["sys"]));
 ok(Net::MirrorDir::GetExclusions($mirror)->[0] eq "sys");
 ok(Net::MirrorDir::SetSubset($mirror, ["my_files"]));
 ok(Net::MirrorDir::GetSubset($mirror)->[0] eq "my_files");
 ok(Net::MirrorDir::SetSubset($mirror, []));
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
 ok($mirror->SetFtpServer("home.perl.de"));
 ok(my $server = $mirror->GetFtpServer());
 ok($server eq "home.perl.de");
 ok($mirror->SetDelete("disabled"));
 ok(my $delete = $mirror->GetDelete());
 ok($delete eq "disabled");
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
# tests for ReadLocalDir()
 ok($mirror->SetExclusions([]));
 ok($mirror->SetSubset([]));
 ok($mirror->ReadLocalDir("TestA"));
 ok($mirror->SetRemoteDir("TestD"));
 ok($mirror->SetLocalDir("TestA"));
 ok($mirror->GetLocalFiles());
 ok($mirror->GetLocalDirs());
 ok($ref_a_new_local_files = $mirror->LocalNotInRemote(
 	$mirror->GetLocalFiles(), $ref_h_test_remote_files));
 ok("TestA/TestB/TestC/Dir3/test3.txt" eq $ref_a_new_local_files->[0]);
 ok($ref_a_new_local_dirs = $mirror->LocalNotInRemote(
 	$mirror->GetLocalDirs(), $ref_h_test_remote_dirs));
 ok("TestA/TestB/TestC/Dir3" eq $ref_a_new_local_dirs->[0]);
 ok($ref_a_deleted_local_files = $mirror->RemoteNotInLocal(
 	$mirror->GetLocalFiles(), $ref_h_test_remote_files));
 ok("TestD/TestB/TestC/Dir6/test6.txt" eq $ref_a_deleted_local_files->[0]);
 ok($ref_a_deleted_local_dirs = $mirror->RemoteNotInLocal(
 	$mirror->GetLocalDirs(), $ref_h_test_remote_dirs));
 ok("TestD/TestB/TestC/Dir6" eq $ref_a_deleted_local_dirs->[0]);
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
  for(my $i = 1; $i <= 3; $i++)
 	{
 	for(keys(%{$mirror}))
 		{
 		my $function = "set" . $_;
 		ok($mirror->$function("ok"));
 		$function = "GET_" . $_;
 		ok(my $value = $mirror->$function());
 		ok($value eq "ok");
 		$function = "SeT_" . $_;
 		ok($mirror->$function("nok"));
 		$function = "gEt" . $_;
 		ok($value = $mirror->$function());
 		ok($value eq "nok");
 		}
 	}
#------------------------------------------------
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

