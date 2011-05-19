#!/usr/bin/perl -w

# --------------------------------------------------------
# list-projects
# (c) 2010 ]project-open[
# Frank Bergmann (frank.bergmann@project-open.com)


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


#$rest_server = "http://192.168.0.2:30086";		# May include port number


# --------------------------------------------------------
# Request the XML result

print "list-projects.perl: Sending HTTP request to $rest_server/intranet-rest/im_project\n" if ($debug > 0);
print "list-projects.perl: Using email=$rest_email and password=$rest_password\n" if ($debug > 0);

$ua = LWP::UserAgent->new;
$req = HTTP::Request->new(GET => "$rest_server/intranet-rest/im_project");
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
    return unless $elt eq 'object_id';  # We're only interrested in what's said
    $atts{'_str'} = '';
    $message = \%atts; 
}

# Handle the end of a tag.
# Just print out the tag
sub hdl_end{
    my ($p, $elt) = @_;
    format_message($message) if $elt eq 'object_id' && $message && $message->{'_str'} =~ /\S/;
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

    $project_name = $atts->{'_str'};
    $project_id = $atts->{'id'};
    print "list-projects.perl: project_id=$project_id, project_name=$project_name\n";

#    while ( my ($key, $value) = each(%$atts) ) { print "$key => $value\n";  }

    undef $message;
}


exit 0;

