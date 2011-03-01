#!/usr/bin/perl -w

# --------------------------------------------------------
# get-project.perl
# (c) 2010 ]project-open[
# Frank Bergmann (frank.bergmann@project-open.com)
# Get the XML of the project with the specified ID


# --------------------------------------------------------
# Libraries

use XML::Parser;
use LWP::UserAgent;


# --------------------------------------------------------
# Connection parameters: 

# Debug: 0=silent, 9=verbose
$debug = 1;

$rest_server = "http://demo.project-open.net";		# May include port number
$rest_email = "bbigboss\@tigerpond.com";
$rest_password = "ben";



# --------------------------------------------------------
# Expect the project_id as the command line argument

my $project_id = $ARGV[0];
if ("" eq $project_id) {
    print "get-project.perl: Usage\n";
    print "get-project.perl: \n";
    print "get-project.perl: get-project.perl <project_id>\n";
    print "get-project.perl: \n";
    exit 1;
}



# --------------------------------------------------------
# Get the XML for the project

$ua = LWP::UserAgent->new;
$req = HTTP::Request->new(GET => "$rest_server/intranet-rest/im_project/$project_id");
$req->authorization_basic($rest_email, $rest_password);
$response = $ua->request($req);

# Extract return_code (200, ...), headers and body from the response
print $response->as_string if ($debug > 8);
$code = $response->code if ($debug > 0);
print "list-projects.perl: HTTP return_code=$code\n" if ($debug > 0);
$headers = $response->headers_as_string;
print "list-projects.perl: HTTP headers=$headers\n" if ($debug > 7);
$body =  $response->content;
print "list-projects.perl: HTTP body=$body\n" if ($debug > 8);


# -------------------------------------------------------
# Write the body into an XML file

open(F,"> $project_id.xml");
print F $body;
close(F);



# -------------------------------------------------------
# Creates a XML parser object with a number of event handlers

my $parser = new XML::Parser ( Handlers => {
                              Start   => \&hdl_start,
                              End     => \&hdl_end,
                              Char    => \&hdl_char,
                              Default => \&hdl_def,
});

my $message;			# Hashref containing infos on a message
$parser->parse($body);		# Parse the message



# -------------------------------------------------------
# Define Event Handlers for event based XML parsing

# Handle the start of a tag.
# Store the tag's attributes into "message".
# Create a reserved field "_str" which will contain the strings of the tag.
sub hdl_start{
    my ($p, $elt, %atts) = @_;
#    return unless $elt eq 'object_id';  # We're only interrested in what's said
    $atts{'var'} = $elt;
    $atts{'_str'} = '';
    $message = \%atts; 
}

# Handle the end of a tag.
# Just print out the tag
sub hdl_end{
    my ($p, $elt) = @_;

#    return if $elt eq 'object_id' && $message && $message->{'_str'} =~ /\S/;

    format_message($message);
}

# Handle characters: Append them to the "_str" field
sub hdl_char {
    my ($p, $str) = @_;
    $message->{'_str'} .= $str;
}

# Default handler: Just ignore everything else
sub hdl_def { }



# -------------------------------------------------------
# Helper sub to nicely format what we got from the XML

sub format_message {
    my $atts = shift;
    $atts->{'_str'} =~ s/\n//g;

    if (!exists $atts->{'_str'}) { return; }
    if (!exists $atts->{'var'}) { return; }

    $str = $atts->{'_str'};
    $var = $atts->{'var'};

    print "list-projects.perl: $var=$str\n";

#    while ( my ($key, $value) = each(%$atts) ) { print "$key => $value\n";  }

    undef $message;
}


exit 0;

