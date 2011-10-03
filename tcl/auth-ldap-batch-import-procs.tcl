ad_library {
    Implements import from Active Directory and OpenLDAP servers.

    All of these routines return a hash as a list consisting of the values:
    <ul>
    <li>result: The usual 1=true=success or 0=false=failure
    <li>debug: Some debug messages suitable to written out using a HTML "pre" tag
    </ul>

    @author Lars Pind (lars@collaobraid.biz)
    @author Frank Bergmann (frank.bergmann@project-open.com)
    @creation-date 2011-01-13
}

package require base64 2.3.1

namespace eval auth {}
namespace eval auth::ldap {}
namespace eval auth::ldap::batch_import {}

# -----------------------------------------------------------------
# Physical Access: Get a LDIF (=text representation of LDAP entries)
# from the LDAP server
# -----------------------------------------------------------------


ad_proc -private auth::ldap::batch_import::read_ldif_file {
    {-object_class "*" }
    {-ldap_query "" }
    {-attributes ""}
    {parameters {}}
    {authority_id {}}
} {
    Retreives the entire content of the OpenLDAP or Active Directory server.
    Returns a hash with 3 values:
    <ul>
    <li>result: 1 for OK or 0 for failure
    <li>debug: Some debug message suitable for "pre" formatting
    <li>ldif: The contents of the LDIF file
    </ul>
} {
    ns_log Notice "auth::ldap::batch_import::read_ldif_file $parameters $authority_id"

    # Parameters
    array set params $parameters

    # -----------------------------------------------------------------
    # Pull out the LDAP parameter values.
    
    # The LDAP server like: "ldap://localhost"
    set uri $params(LdapURI)
    set base_dn $params(BaseDN)
    set bind_dn $params(BindDN)
    set bind_pw $params(BindPW)
    set server_type $params(ServerType)

    switch $server_type {
	ad {
	    # ------------------------------------------------------------------------------
	    # Active Directory
	    ns_log Notice "auth::ldap::batch_import::read_ldif_file Active Directory"

	    set query "(objectClass=$object_class)"
	    if {"" != $ldap_query} {
		set query (&${query}$ldap_query)
	    }
	    set cmd "ldapsearch -x -H $uri -D $bind_dn -w $bind_pw -b $base_dn $query $attributes"
	    ns_log Notice "auth::ldap::batch_import::read_ldif_file: cmd=$cmd"

	    # Bind as "Adminstrator" and retreive the userPassword field for
	    set fl [open "| $cmd"]
	    set data ""
	    if {[catch {
		set data [read $fl]
		close $fl
	    } err_msg]} {
		ns_log Notice "auth::ldap::batch_import::read_ldif_file: Error executing cmd: $err_msg"
	    }

	    if {"" == $data} {
		return [list result 0 debug $err_msg ldif ""]
	    } else {
		return [list result 1 debug "" ldif $data]
	    }
	}
	ol {
	    # ------------------------------------------------------------------------------
	    # For OpenLDAP auth, we retreive the "userPassword" field of the user and
	    # check if we can construct the same hash
	    ns_log Notice "auth::ldap::batch_import::read_ldif_file OpenLDAP"
	    ns_log Notice "ldapsearch -x -H $uri -D $bind_dn -w $bind_pw -b $base_dn '(objectClass=$object_class)' $attributes"
	    set return_code [catch {
		# Bind as "Manager" and retreive the userPassword field for
		exec ldapsearch -x -H $uri -D $bind_dn -w $bind_pw -b $base_dn "(objectClass=$object_class) $attributes"
	    } err_msg]
	    ns_log Notice "auth::ldap::batch_import::read_ldif_file return_code=$return_code, msg=$err_msg"

	    if {1 == $return_code} {
		return [list result 0 debug $err_msg ldif ""]
	    } else {
		return [list result 1 debug "" ldif $err_msg]
	    }
	}
    }
}


# -----------------------------------------------------------------
# Parse the LDIF file and return a hash of hashs.
# Group key-value pairs of one object together.
# -----------------------------------------------------------------


ad_proc -private auth::ldap::batch_import::read_ldif_objects {
    {-debug_p 1}
    {-ldap_query "" }
    {-object_class "group" }
    {parameters {}}
    {authority_id {}}
} {
    Reads a LDIF files and returns a hash of hashes in the "objects" field of the returned hash:
    <ul>
    <li>First Index: LDAP "DN" (=Distinguished Name)
    <li>Second Index: LDAP "key" (ex.: objectClass, ...)
    <li>Value: The LDAP value
    </ul>
    The LDIF format consists of "key: value" lines representing all the properties of an object.
    Two "objects" are separated by an empty line.
} {
    ns_log Notice "auth::ldap::batch_import::read_ldif_objects"
    array set result_hash [auth::ldap::batch_import::read_ldif_file -object_class $object_class -ldap_query $ldap_query $parameters $authority_id]
    ns_log Notice "auth::ldap::batch_import::read_ldif_objects: result=$result_hash(result)"

    if {0 == $result_hash(result)} {
	return [list result 0 debug $result_hash(debug) objects {}]
    }

    # Parse the LDIF
    set debug ""
    set lines [split $result_hash(ldif) "\n"]
    ns_log Notice "auth::ldap::batch_import::read_ldif_objects: [llength $lines] lines"

    set dn ""
    set object_keys_values {}
    array set objects_hash {}
    set line_ctr 0
    set max_lines [llength $lines]

    while {$line_ctr < $max_lines} {
	
	# Get the current line
	set line [lindex $lines $line_ctr]
	set next_line [lindex $lines [expr $line_ctr + 1]]
	if {$debug_p} { ns_log Notice "auth::ldap::batch_import::read_ldif_objects: line \#$line_ctr=$line" }
	incr line_ctr

	if {"#" == [string range $line 0 0]} { 
	    # A hash starts a comment line
	    continue 
	}

	if {"" == $line} {

	    # We have found the boundary of one object.
	    # So take the current object lines for parsing and
	    # start off a new object
	    if {"" != $dn} {
		set objects_hash($dn) $object_keys_values
		if {$line_ctr > 15000} { return [list result 1 debug $debug objects [array get objects_hash]] }
	    }
	    # Reset variables for the next object
	    set object_keys_values {}
	    set dn ""

	} else {
	    
	    # Process one line of LDAP information.

	    # Check if the next line starts with a space (" ").
	    # In this case we need to append the next line to the current one.
	    set first_char [string range $next_line 0 0]
	    while {" " == $first_char} {
		if {$debug_p} { ns_log Notice "auth::ldap::batch_import::read_ldif_objects: Cont. at \#$line_ctr: $next_line" }
		append line [string trim $next_line]
		incr line_ctr
		set next_line [lindex $lines [expr $line_ctr + 1]]
		set first_char [string range $next_line 0 0]
	    }
	    
	    # A single colon means unquoted value, double colon means base64 encoded
	    if {[regexp {^dn: (.*)$} $line match dn_var]} { 
		set dn $dn_var 
	    }

	    # Base64 encoded DN:
	    if {[regexp {^dn:: (.*)$} $line match dn_var_base64]} { 

		if {$debug_p} { ns_log Notice "auth::ldap::batch_import::read_ldif_objects: base64 encoded dn: $line" }
		if {[catch {
		    set dn [::base64::decode $dn_var_base64]
		    if {$debug_p} { ns_log Notice "auth::ldap::batch_import::read_ldif_objects: dn=$dn" }
		} err_msg]} {
		    ad_return_complaint 1 "Error:<pre>$err_msg</pre><br><pre>$dn_var_base64"
		}
	    }
		
	    # Convert all other lines into a hash
	    if {[regexp {^([a-zA-Z0-9]+): (.*)$} $line match key value]} {
		set key [string trim $key]
		set value [string trim $value]
		lappend object_keys_values $key $value
	    }
	}
    }

    return [list result 1 debug $debug objects [array get objects_hash]]
}



# -----------------------------------------------------------------
# Retrieve the list of all groups in the LDAP server
# -----------------------------------------------------------------



ad_proc -private auth::ldap::batch_import::read_ldif_groups {
    {parameters {}}
    {authority_id {}}
} {
    Parse the LDIF file and return a list of all groups, together with 
    information about these groups.
    Returns a hash with the values result, debug and objects.
} {
    ns_log Notice "auth::ldap::batch_import::read_ldif_groups: parameters=$parameters"
    set debug ""

    array set result_hash [auth::ldap::batch_import::read_ldif_objects $parameters $authority_id]
    if {0 == $result_hash(result)} {
        # Found some errors
        return [list result 0 debug $result_hash(debug) objects {}]
    }

    # Loop through the list of objects and extract the ones that are some
    # kind of group
    array set objects_hash $result_hash(objects)
    set groups {}

    foreach group_dn [array names objects_hash] {
	
	ns_log Notice "auth::ldap::batch_import::read_ldif_groups: group_dn=$group_dn"
	set group_p 0
	set group_name ""
	array unset attributes_hash
	array set attributes_hash $objects_hash($group_dn)

	foreach key [array names attributes_hash] {
	    
	    # A group is defined by a key-value tuple "objectClass: group"
	    switch $key {
		name {
		    # Active Directory "name" contains the pretty name of the group
		    set group_name $attributes_hash($key)
		}
		cn {
		    # OpenLDAP "cn" (=common name) contains the pretty name of the group
		    set group_name $attributes_hash($key)
		}
		objectClass {
		    # Groups are determined by "group" or "posixGroup" objectClass.
		    set value $attributes_hash($key)
		    switch $value {
			group { 
			    # Active Directory Group class
			    set group_p 1 
			}
			posixGroup { 
			    # OpenLDAP Group class
			    set group_p 1 
			}
		    }
		}
	    }
	}

	if {$group_p} { lappend groups $group_name $objects_hash($group_dn) }
    }

    return [list result 1 debug [string range $debug 0 1000] objects $groups]
}


# -----------------------------------------------------------------
# Import users
# -----------------------------------------------------------------


ad_proc -private auth::ldap::batch_import::import_users {
    {parameters {}}
    {authority_id {}}
} {
    Parse the LDIF file and import every found users into ]po[
    using the group_map defined in parameters.
    Returns a hash with the values result and debug
} {
    ns_log Notice "auth::ldap::batch_import::import_users: parameters=$parameters"
    set debug ""

    set ldap_query "(memberOf=cn=PO-IntegracionUsuarios,cn=Users,dc=lagunaro,dc=local)"
    array set result_hash [auth::ldap::batch_import::read_ldif_objects -object_class "person" -ldap_query $ldap_query $parameters $authority_id]
    if {0 == $result_hash(result)} {
        # Found some errors
        return [list result 0 debug $result_hash(debug) groups {}]
    }

    # Loop through the list of objects and extract the ones that are some
    # kind of group
    array set objects_hash $result_hash(objects)

    set user_cnt 0
    foreach user_dn [array names objects_hash] {
	
	ns_log Notice "auth::ldap::batch_import::import_users: user_cnt=$user_cnt, dn=$user_dn"
	if {[regexp {\$} $user_dn match]} { 
	    # A "$" indicates a computer name instead of a user
	    continue 
	}

	incr user_cnt

	# The list of key-value pairs in ]po[ naming
	array unset user_hash
	array set user_hash {}

	# Start by default as "not a user"
	set user_p 0

	# Get the list of LDAP attributes
	set key_value_list $objects_hash($user_dn)
	set key_value_list_len [llength $key_value_list]

	# List of group memberships
	set group_list {}
	
	for {set i 0} {$i < $key_value_list_len} { incr i 2} {
	    set key [lindex $key_value_list $i]
	    set value [string trim [lindex $key_value_list [expr $i+1]]]
	    switch $key {
		c		{ set user_hash(country_code) $value }
		cn		{ set user_hash(display_name) $value }
		displayName	{ set user_hash(display_name) $value }
		company		{ set user_hash(company_name) $value }
		gecos		{ set user_hash(display_name) $value }
		givenName	{ set user_hash(first_names) $value }
		l		{ set user_hash(city) $value }
		countryCode	{ set user_hash(country_code_numeric) $value }
		co		{ set user_hash(country_name) $value }
		description	{ set user_hash(description) $value }
		homePhone	{ set user_hash(home_phone) $value }
		mail		{ set user_hash(email) $value }
		memberOf	{ lappend group_list $value }
		mobile		{ set user_hash(mobile_phone) "" }
		name		{ set user_hash(display_name) $value }
		objectClass {
		    ns_log Notice "auth::ldap::batch_import::import_users: objectClass='$value'"
		    switch $value {
			user { set user_p 1 }
			person { set user_p 1 }
			inetOrgPerson { set user_p 1 }
			organizationalPerson { set user_p 1 }
		    }
		}
		physicalDeliveryOfficeName { set user_hash(office_name) $value }
		postalCode	{ set user_hash(postal_code) $value }
		sAMAccountName	{ set user_hash(username) $value }
		sn		{ set user_hash(last_name) $value }
		st		{ set user_hash(state) $value }
		streetAddress	{ set user_hash(address_line1) $value }
		telephoneNumber { set user_hash(work_phone) $value }
		uid		{ set user_hash(username) $value }
		wWWHomePage { set user_hash(url) $value }
	    }
	}

	if {$user_p} { 
	    # Insert the user into the databaes
	    ns_log Notice "auth::ldap::batch_import::import_users: Found a user: $user_dn"
	    array set user_result_hash [auth::ldap::batch_import::parse_user \
					    -authority_id $authority_id \
					    -parameters $parameters \
					    -dn $user_dn \
					    -keys_values [array get user_hash] \
					    -group_list $group_list \
					   ]
	    append debug $user_result_hash(debug)
	} else {
	    ns_log Notice "auth::ldap::batch_import::import_users: Not a user: $user_dn"
	}
    }
    return [list result 1 debug $debug]
}

ad_proc -private auth::ldap::batch_import::parse_user {
    {-group_list "" }
    -authority_id:required
    -parameters:required
    -dn:required
    -keys_values:required
} {
    Parse a single OpenLDAP object as defined by a number of LDIF lines
} {
    ns_log Notice "auth::ldap::batch_import::parse_user: dn=$dn, kv=$keys_values"
    set debug ""
    array set params $parameters
    array set hash $keys_values
    
    # display_name logic: Fill in first_names and last name if empty.
    if {[info exists hash(display_name)]} {
	set display_name $hash(display_name)
	set display_name_pieces [split $display_name " "]
	if {![info exists hash(first_names)]} { set hash(first_names) [lrange $display_name 0 end-1] }
	if {![info exists hash(last_name)]} { set hash(last_name) [lrange $display_name end end] }
    }   

    # Email logic: Fill in username+domain if not exists
    if {[info exists hash(username)]} {
	set username $hash(username)
	if {![info exists hash(email)]} {
	    set base_dn $params(BaseDN)
	    # Remove the "dc=" pieces from the domain
	    regsub -all -nocase {dc\=} $base_dn "" domain
	    # Replace "," with "."
	    regsub -all -nocase {,} $domain "." domain
	    set hash(email) "$username@$domain"
	}
    }   

    # Check for empty variables
    set ok_p 1
    foreach var {username first_names last_name email } {
	set val ""
	if {[info exists hash($var)]} { set val $hash($var) }
	if {"" == $val} {
	    ns_log Error "auth::ldap::batch_import::parse_user: found empty variable '$var', skipping"
	    append debug "Skpping: dn=$dn\n"
	    append debug "Skipping because: Found empty variable '$var'\n"
	    set ok_p 0
	}
    }

    # Skip if something was wrong.
    if {!$ok_p} { return [list result 0 oid 0 debug $debug] }

    # Write hash variables to local variables
    foreach var [array names hash] {
	set $var $hash($var)
    }

    # Make sure the first letter of the first name is in upper case
    set first_names "[string toupper [string range $first_names 0 0]][string range $first_names 1 end]"

    if {![info exists display_name]} { set display_name "$first_names $last_name" }

    # Check if the user already exists.
    # We assume that username and email are unique here.
    # Normally, username and email are only unique for each Authority,
    # but this is a special that that we want to ignore here.
    # 
    set user_id [db_string uid "
	select	user_id
	from	cc_users
	where	lower(username) = :username OR lower(email) = :email
    " -default 0]

    if {0 == $user_id} {
	
	# The user doesn't exist yet. Create the user.
	ns_log Notice "auth::ldap::batch_import::parse_user: Creating new user: dn=$dn, username=$username, email=$email, first_names=$first_names, last_name=$last_name"
	append debug "Creating new user: dn=$dn\n"
	append debug "Creating new user '$first_names $last_name'\n"

	# Random password...
	set pwd [expr rand()]
	# user_id is the next free ID
	set user_id [db_nextval acs_object_id_seq]

	# Create the guy
	array set creation_info [auth::create_user \
				     -user_id $user_id \
				     -username $username \
				     -email $email \
				     -first_names $first_names \
				     -last_name $last_name \
				     -screen_name $display_name \
				     -password $pwd \
				     -password_confirm $pwd \
				    ]

	set creation_status $creation_info(creation_status)
	if {"ok" != $creation_status} {
	    ns_log Notice "auth::ldap::batch_import::parse_user: dn=$dn: Failed to create user dn=$dn: [array get creation_info]"
	    append debug "Failed to create user dn=$dn\n"
	    append debug "Failed to create reason: $creation_info(creation_message)\n"
	}

	# Set creation user
	db_dml update_creation_user_id "
                update acs_objects
                set creation_user = [ad_get_user_id]
                where object_id = :user_id
        "

	# For all users: Add a users_contact record
        catch { db_dml add_users_contact "insert into users_contact (user_id) values (:user_id)" } errmsg

	# Add the user to the "Registered Users" group, because (s)he would get strange problems otherwise
        set registered_users [im_registered_users_group_id]
        set reg_users_rel_exists_p [db_string member_of_reg_users "
                select  count(*)
                from    group_member_map m, membership_rels mr
                where   m.member_id = :user_id
                        and m.group_id = :registered_users
                        and m.rel_id = mr.rel_id
                        and m.container_id = m.group_id
                        and m.rel_type = 'membership_rel'
        "]
        if {!$reg_users_rel_exists_p} {
            relation_add -member_state "approved" "membership_rel" $registered_users $user_id
        }

    } else {
	append debug "Update existing user: dn=$dn\n"
    }

    # Update fiels of both existing or new user.
    db_dml update_user "
		update users set
			username = :username,
			authority_id = :authority_id
		where user_id = :user_id
    "
    db_dml update_person "
		update persons set
			first_names = :first_names,
			last_name = :last_name
		where person_id = :user_id
    "
    db_dml update_parties "
		update parties set
			email = :email
		where party_id = :user_id
    "


    # Add the user to the respective groups
    set group_pairs $params(GroupMap)
    array set group_map $group_pairs
    foreach g $group_list {
	set group_id 0
	if {[info exists group_map($g)]} { set group_id $group_map($g) }
	if {[regexp -nocase {^cn=([^\,\=]+)} $g match group_body]} {
	    if {[info exists group_map($group_body)]} { set group_id $group_map($group_body) }
	}

        if {0 == $group_id} {
            ns_log Notice "auth::ldap::batch_import::parse_user: did not find group '$g' - skipping"
            continue
        }
        ns_log Notice "auth::ldap::batch_import::parse_user: Found group '$g' -> $group_id"

        set rel_exists_p [db_string member_of_group "
                select  count(*)
                from    group_member_map m, membership_rels mr
                where   m.member_id = :user_id
                        and m.group_id = :group_id
                        and m.rel_id = mr.rel_id
                        and m.container_id = m.group_id
                        and m.rel_type = 'membership_rel'
        "]
        if {!$rel_exists_p} {
            relation_add -member_state "approved" "membership_rel" $group_id $user_id
        }
    }

    return [list result 1 oid 0 debug $debug]
}





# -----------------------------------------------------------------
# Import groups
# -----------------------------------------------------------------


ad_proc -private auth::ldap::batch_import::import_groups {
    {parameters {}}
    {authority_id {}}
} {
    Parse the LDIF file and import every found groups into ]po[
    using the group_map defined in parameters.
    Returns a hash with the values result and debug
} {
    ns_log Notice "auth::ldap::batch_import::import_groups: parameters=$parameters"
    array set params $parameters
    array set result_hash [auth::ldap::batch_import::read_ldif_groups $parameters $authority_id]
    if {0 == $result_hash(result)} {
        # Found some errors
        return [list result 0 debug $result_hash(debug) groups {}]
    }

    # Successfully read the group
    set debug $result_hash(debug)
    array set group_hash $result_hash(objects)
    array set group_map_hash $params(GroupMap)

    foreach group_name [array names group_hash] {

	set po_group_id ""
	if {[info exists group_map_hash($group_name)]} { set po_group_id $group_map_hash($group_name) }

	ns_log Notice "auth::ldap::batch_import::import_groups: group='$group_name' -> $po_group_id"

	# Going through the group members only makes sense if we have mapped the LDAP group to ]po[...
	if {"" != $po_group_id} {

	    set group_kvs $group_hash($group_name)
	    set group_kvs_len [llength $group_kvs]
	    
	    # Loop for all key-value pairs of the group
	    for {set i 0} {$i < $group_kvs_len} { incr i 2 } {
		
		set key [lindex $group_kvs $i]
		set val [lindex $group_kvs [expr $i+1]]
		
		switch $key {
		    memberUid {
			# Val should be the username of a user who is member of this group
			set user_id [db_string uid "
				select	user_id
				from	users
				where	username = :val
			" -default 0]

			if {0 != $user_id} {
			    set group_name [im_profile::profile_name_from_id -translate_p 0 -profile_id $po_group_id]
			    ns_log Notice "auth::ldap::batch_import::import_groups: Adding user '$val' to group '$group_name'"
			    append debug "Adding user $val ($user_id) to group $group_name\n"
			    relation_add -member_state "approved" "membership_rel" $po_group_id $user_id
			}
		    }
		}
	    }
	}

    }
    return [list result 0 debug $debug]   
}