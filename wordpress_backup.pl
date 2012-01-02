#!/usr/bin/perl 

use v5.10; #make use of the say command and other nifty perl 10.0 onwards goodness; 
			 #should be able to drop to 10.0 or above OK
use Carp;
use WWW::Mechanize;
use YAML;
use common::sense;
#TODO add UTF8 module here & fix wide character bug

#set the version number in a way Getopt::Euclid can parse
BEGIN { use version; our $VERSION = qv('0.1.1_1') }

use Getopt::Euclid; # Create a command-line parser that implements the documentation below... 

my $path_to_file = $ARGV{-d} || "./"; #ensure the directory defaults to the current one if not provided

##############  Settings  #####################
#my $path_to_file="./";
#Filename format: fileprefix.date.xml
my $fileprefix="wordpress";
###############################################

#get the login data
my $account = YAML::LoadFile($ENV{HOME} . "/.wordpress_login")
    or die "Failed to read $ENV{HOME}/.wordpress_login - $!";

say "loaded YAML credentials file:\t\t[OK]";

#Change agent string if you want
my $agent="unixwayoflife/1.0";

my $date=((localtime)[5] +1900)."-".((localtime)[4] +1)."-".(localtime)[3];
my $mech = WWW::Mechanize->new( agent => $agent );
$mech->get( $account->{url}."wp-login.php" );

##Log in
$mech->submit_form(
        form_name => 'loginform',
        fields    => { log  => $account->{username}, pwd => $account->{password} },
        button    => 'wp-submit'
   );
die "ERROR: Incorrect password. Aborted." if $mech->content =~ m/Incorrect password/;
print ("Login in \t\t\t\t[OK]\n");
#TODO rewrite login code to better handle errors using mech->success

#optional
sleep(2);

##Download the file
$mech->get($account->{url}."wp-admin/export.php?author=$account->{author}&submit=Download+Export+File&download=true");
my $file_name="$fileprefix.$date.xml";
$mech->save_content( $path_to_file.$file_name );
	if  ( $mech->success() )
	{ 
		say "download \t\t\t\t[OK]";
		say "saved \t\t\t\t\t$path_to_file.$file_name"; 
	}
	else
		{ carp "download failed getting $file_name because: $!" }

#optional
sleep(2);

##Log Out
#disabled because the original code doesn't work and gives an error and I've not
#  figured out how to do this properly via wordpress - seems to need some kind of
#  session id.

#$mech->get($account->{url}."wp-login.php?action=logout&_wpnonce=01d57eff69");
#	if  ( $mech->success() )
#		{ say "logout \t\t\t [OK]"; }
#	else
#		{ carp "logout failed because: $!"; }


__END__
=head1 NAME

wordpress_backup - backs up a wordpress instance.

=over 4
 
=item * B<NOTE> unless you provide -d the data files will be created in the current working directory.

=item * B<Note> The script expect to find a file called ~/.wordpress_login and will fail if it can't.

=back

=head2 Warning

=over 4

=item * If a file with a given name exists it'll be overwritten.

=item * Don't forget to escape special characters like @ in the password
   variable.  Example:   q6@7mb   =>  q6\@7mb

=back

=head2 Thanks

to the blogger behind 'unixwayoflife', who put his version on his blog at
 http://unixwayoflife.wordpress.com/2008/11/08/automated-wordpress-com-backup/ .  

=head2 config file reference

The YAML file follows the following format;

 ---
 username: my_wordpress_username
 password: my_wordpress_password
 url: url_to_wordpress_site
 author: e.g. 'all' or 'john'

=head2 TODO

=over 2

=item implement fix for 'wide character' bug in UTF8 handling in www::mechanize

=item implement 'silent mode' for no output

=item implement optional attributes in config file

	optional attr: silent specification
	optional attr: file prefix specification

=item fix logout code

=back

=head1 USAGE

    wordpress_backup  [-d] specify directory name to create backup file in 

=head1 OPTIONS

=over

=item  -d[ir] [=] <dir>

Specify directory to select the file from [default: dir.default]


=for Euclid:
    dir.type:    string 
    dir.default: './'
    dir.type.error: must be a valid directory


=item --version

=item --usage

=item --help

=item --man

Print the usual program information

=back

=begin remainder of documentation here. . .


