#!/usr/bin/perl
#
# @author John Prevost <jmp@arsdigita.com>
# @creation-date 2001-01-16
# @cvs-id $Id$

### DANGER  This script is entirely untested, since I don't yet have an Oracle
### DANGER  DBI setup available to me.  It will be tested once I do.

sub usage () {
    print "$0: db_user db_passwd [envelope_from] [envelope_to]\n";
}

################################################################
# Global Definitions

$db_user           = shift;
$db_passwd         = shift;
$envelope_from     = shift || '';
$envelope_to       = shift || '';

# Oracle access
$ORACLE_HOME = "/ora8/m01/app/oracle/product/8.1.6";
$ENV{'ORACLE_HOME'} = $ORACLE_HOME;
$ENV{'ORACLE_BASE'} = "/ora8/m01/app/oracle";
$ENV{'ORACLE_SID'} = "ora8";

$db_datasource = 'dbi:Oracle:';

################################################################

use DBI;
use DBD::Oracle qw(:ora_types);

$content_all = '';
$content_no_header = '';

$header_p = 1;
$header_name = undef;
%headers = ();

while (<>) {
    $content_all .= $_;
    $content_no_header .= $_ if ( !$header_p );
    chomp;
    if ( $header_p ) {
	if ( /^$/ ) {
	    $header_p = 0;
	} elsif ( /^\S+: / ) {
	    ($header_name, $header_content) = /^(\S+): (.*)$/;
	    $headers{lc $header_name} .= $header_content;
	} elsif ( /^\s+/ ) {
	    $headers{lc $header_name} .= "\n$_";
	}
    }
}

# Open the database connection.
$dbh = DBI->connect($db_datasrc, $db_user, $db_passwd,
                     { RaiseError => 1, AutoCommit => 0 })
   || die "$0: couldn't connect to database: $!";

# This is supposed to make it possible to write large CLOBs
$dbh->{LongReadLen} = 2**20;   # 1 MB max message size 
$dbh->{LongTruncOk} = 0;

# Create a message body

$h = $dbh->prepare (qq{
    declare
	-- blob
        header_message_id varchar;
        header_reply_to varchar;
        header_subject varchar;
        header_from varchar;
        header_to varchar;
        -- envelope to
	-- envelope from
        body_reply_to integer;
        body_from integer;
        body_date date;
	cont_id integer;
	body_id integer;
        link_id integer;
    begin
	cont_id := acs_mail_gc_object.new ( creation_user => null );
        insert into acs_contents (content_id, content, searchable_p, mime_type)
	    values (cont_id, ?, 'f', 'text/plain');
	header_message_id := ?;
        header_reply_to := ?;
        header_subject := ?;
        header_from := ?;
        header_to := ?;
        -- try to get the body_reply_to id by selecting on header_message_id
        body_reply_to := null;
	-- try to get the body_from id by searching on email
        body_from := null
	-- get the body date by being handed it from perl
        body_date := ?;
	body_id := acs_mail_body.new (
            body_reply_to => body_reply_to,
	    body_from => body_from,
            body_date => body_date,
            header_message_id => header_message_id,
	    header_reply_to => header_reply_to,
            header_subject => header_subject,
	    header_from => header_from,
            header_to => header_to,
	    content_object_id => cont_id
        );
        link_id := acs_mail_queue_message.new (
	    body_id => body_id
        );
        insert into acs_mail_queue_incoming values (link_id, ?, ?);
    end;
});

$h->bind_param(1, $content_no_header, { ora_type => ORA_CLOB, ora_field => 'content' });

if (!$h->execute($content_no_header, $headers{'message-id'},
		 $headers{'in-reply-to'}, $headers{'subject'},
		 $headers{'from'}, $headers{'to'}, $envelope_from,
		 $envelope_to)) {
    die "$0: unable to open cursor: $!\n" . $dbh->errstr;
}

$h->finish;

$dbh->disconnect;
