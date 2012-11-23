# --------------------------------------------------------
# Access the ]project-open[ REST Web-Service
# Example
# (c) 2010 ]project-open[
# Author: Frank Bergmann
# --------------------------------------------------------

use ProjectOpen;
use Data::Dumper;

# --------------------------------------------------------
# Connection parameters:

# Debug: 0=silent, 9=very verbose
$debug = 1;

# benbigboss/ben is a default user @ demo.project-open.net...
#

$rest_server = "demo.project-open.net";
$rest_server = "192.168.21.128";
$rest_email = "bbigboss\@tigerpond.com";
$rest_password = "ben";


# Create a generic access object to query the ]po[ HTTP server
#
ProjectOpen->new (
	host	=> $rest_server,
	email	=> $rest_email,
	password => $rest_password,
	debug => $debug
);


# -------------------------------------------------------
# Get the list of users with a "cvs_user" field which is not null.
# As a result we will receive a hash reference with user_id -> <some reference>
# We can then take the user_id to get more information about that user.
#
my $user_list = ProjectOpen->get_object_list("user", "cvs_user is not null and cvs_user != 'anonymous'");
print Dumper($user_list) if ($debug > 5);



# -------------------------------------------------------
# Get the group memberships for each user
#
for my $user_id (keys %$user_list) {

    # Get more information about the user
    my $user_hash = ProjectOpen->get_object("user", $user_id);
    print Dumper($user_hash) if ($debug > 5);

    # Extract some variables from hash
    my $username = $user_hash->{username};
    my $cvs_user = $user_hash->{cvs_user};
    my $first_names = $user_hash->{first_names};
    my $last_name = $user_hash->{last_name};
    print "example.perl: Found user '$first_names $last_name' with user_id=$user_id, cvs_user=$cvs_user\n" if ($debug > 0);
 
    # Get the list of group memberships of the user
    my $group_array = ProjectOpen->get_group_memberships($user_id);
    print Dumper($group_array) if ($debug > 5);

    # Loop through the list of groups
    my $array_size = @{$group_array};
    for (my $count = 0; $count < $array_size; $count++) {

	# Access the hash at the position $count of the array
	my $val_hash = $group_array->[$count];
	# The hash has a value "group_id" which we need.
	my $group_id = $val_hash->{group_id};

	# Skip special groups ("The Public" and "Registered Users")
	# with negative group_id
        next if ($group_id < 0);

	# Get the details of the group
	my $group_hash = ProjectOpen->get_object("group", $group_id);
	my $group_name = $group_hash->{group_name};
	my $group_object_type = $group_hash->{object_type};

	# We are looking for groups with group_type = "im_cvs_group".
	# We have created this special group_type in ]po[ to separate
	# these groups from "im_profile" and other groups.
        next if ($group_object_type ne "im_cvs_group");

	print "example.perl: group_id=$group_id, group_name=$group_name\n" if ($debug > 0);
    }
}



exit 0;







# -------------------------------------------------------
# Get the list of configuration items of type "CVS Repository"
#
my $conf_item_list = ProjectOpen->get_object_list("im_conf_item");
print Dumper($conf_item_list) if ($debug > 5);


# -------------------------------------------------------
# Get the list of IDs of the Conf Items
#
my $list = $conf_item_list->{object_id};
for my $object_id (keys %$list) {
    
    print "example.perl: Found conf_item_id=$object_id\n" if ($debug > 5);
    my $conf_item = ProjectOpen->get_object("im_conf_item", $object_id);
    print Dumper($conf_item) if ($debug > 5);

    my $conf_item_name = $conf_item->{conf_item_name};
    my $conf_item_status_id = $conf_item->{conf_item_status_id}->{content};
    my $conf_item_type_id = $conf_item->{conf_item_type_id}->{content};

    my $conf_item_status = ProjectOpen->get_category($conf_item_status_id);
    my $conf_item_type = ProjectOpen->get_category($conf_item_type_id);

    print "example.perl: name=$conf_item_name, status=$conf_item_status, type=$conf_item_type\n" if ($debug);

}

