# /packages/oacs-dav/tcl/oacs-dav-procs.tcl 
ns_log debug "\nLoading oacs-dav-procs.tcl"
ad_library {
    
    Support for tDAV tcl webDAV implemenation
    
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2003-09-11
    @cvs-id $Id$
    
}

namespace eval oacs_dav {}

ad_proc oacs_dav::urlencode { string } {
    urlencode allowing characters according to rfc 1738
    http://www.w3.org/Addressing/rfc1738.txt

    "Thus, only alphanumerics, the special characters "$-_.+!*'(),", and
    reserved characters used for their reserved purposes may be used
    unencoded within a URL."
    
    ignore + used to encode spaces in query strings
    
    This is mainly to support MS Web Folders which do not follow the
    spec which states that any character may be urlencoded. Web Folders
    rejects the entire collection as invalid if a filename contains
    one of these characters encoded.

} {
    set encoded_string [ns_urlencode $string]
    set encoded_string [string map -nocase \
                            {+ %20 %2d - %5f _ %24 $ %2e . %21 ! %28 ( %29 ) %27 ' %2c ,} $encoded_string]
     
   return $encoded_string
}

ad_proc oacs_dav::folder_enabled {
    -folder_id
} {
    @param folder_id

    @return t if folder is webdav enabled, f if not
} {

    return [db_string enabled_p "" -default "f"]

}

ad_proc oacs_dav::set_user_id {} {
    set user_id based on authentication header
} {

    # should be something like "Basic 29234k3j49a"
    set a [ns_set get [ns_conn headers] Authorization]
    if {[string length $a]} {
        ns_log debug "\nTDAV auth_check authentication info $a"
        # get the second bit, the base64 encoded bit
        set up [lindex [split $a " "] 1]
        # after decoding, it should be user:password; get the username
        set user [lindex [split [ns_uudecode $up] ":"] 0]
        set password [lindex [split [ns_uudecode $up] ":"] 1]
        ns_log debug "\nACS VERSION [ad_acs_version]"
        
        
        ns_log debug "\nTDAV 5.0 authentication"
	# check all authorities 
	foreach authority [auth::authority::get_authority_options] {
	    set authority_id [lindex $authority 1]
        array set auth [auth::authenticate \
                            -username $user \
                            -password $password \
			    -authority_id $authority_id \
			    -no_cookie]
	    if {![string equal $auth(auth_status) "ok"]} {
		array set auth [auth::authenticate \
				    -email $user \
				    -password $password \
				    -authority_id $authority_id \
				    -no_cookie]
	    }
	    if {[string equal $auth(auth_status) "ok"]} {
		# we can stop checking
		break
	    }
	}
	if {![string equal $auth(auth_status) "ok"]} {
	    ns_log debug "\nTDAV 5.0 auth status $auth(auth_status)"
	    ns_returnunauthorized
	    return 0
	}
        ns_log debug "\nTDAV: auth_check openacs 5.0 user_id= $auth(user_id)"
        ad_conn -set user_id $auth(user_id)

    } else {
        # no authenticate header, anonymous visitor
        ad_conn -set user_id 0
        ad_conn -set untrusted_user_id 0
    }
}

ad_proc oacs_dav::authorize { args } {
    check is user_id has permission to perform the WebDAV method on
    the URI
} {
    ns_log debug "\nOACS-DAV running oacs_dav::authorize"

    # Restrict to SSL if required
    if { [security::RestrictLoginToSSLP]  && ![security::secure_conn_p] } {
        ns_returnunauthorized
        return filter_return
    }

    # set common data for all requests 
    oacs_dav::conn_setup
   
    set method [string tolower [oacs_dav::conn method]]
    set item_id [oacs_dav::conn item_id]
    set user_id [oacs_dav::conn user_id]
    set folder_id [oacs_dav::conn folder_id]
    ns_log debug "\nOACS-DAV oacs_dav::authorize user_id $user_id method $method item_id $item_id" 
    set authorized_p 0
    # if item doesn't exist don't bother checking....
    if {[empty_string_p $item_id]} {
        if {![string equal "put" $method] && ![string equal "mkcol" $method] && ![string equal "lock" $method]} {
            ns_log debug "\noacs_dav::authorize file not found"
            ns_return 404 text/plain "File Not Found"
            return filter_return
        }
    }
    switch $method {
        put -
        mkcol {
            set authorized_p [permission::permission_p \
                                  -object_id $folder_id \
                                  -party_id $user_id \
                                  -privilege "create"]
        }
        delete {
            set authorized_p [permission::permission_p \
                                  -object_id $item_id \
                                  -party_id $user_id \
                                  -privilege "delete"]
        }
        lock {
            if {![empty_string_p $item_id]} {
                set authorized_p [permission::permission_p \
                          -object_id $item_id \
                          -party_id $user_id \
                          -privilege "write"]
            } else {
                # if item does not exist yet check for create on
                # the collection and create a null lock
                set authorized_p [permission::permission_p \
                                  -object_id $folder_id \
                                  -party_id $user_id \
                                  -privilege "create"]
            }
        }
        unlock -
        proppatch {
            set authorized_p [permission::permission_p \
                                  -object_id $item_id \
                                  -party_id $user_id \
                                  -privilege "write"]
        }
        copy -
        move {
            set authorized_p [expr [permission::permission_p \
                                        -object_id $item_id \
                                        -party_id $user_id \
                                        -privilege "read"] \
				  && [permission::permission_p \
					  -object_id [oacs_dav::conn dest_parent_id ] \
					  -party_id $user_id \
					  -privilege "create"]\
				  || [permission::permission_p \
					  -object_id [oacs_dav::conn dest_parent_id ] \
					  -party_id $user_id \
					  -privilege "write"]]
        }
        propfind {
            if {[empty_string_p $user_id]} {
                ns_returnunauthorized
            } else {
                set authorized_p [permission::permission_p \
                                  -object_id $item_id \
                                  -party_id $user_id \
                                  -privilege "read"]
            }
        }
        head -
        get {
            # default for GET PROPFIND 
            set authorized_p [permission::permission_p \
                                  -object_id $item_id \
                                  -party_id $user_id \
                                  -privilege "read"]
        }
    }
    if {![string equal $authorized_p 1]} {
        ns_returnunauthorized
        return filter_return
    }
    return filter_ok    
}

ad_proc -public oacs_dav::conn {
    args
} {
    shared data for WebDAV requests
} {
    global tdav_conn
    set flag [lindex $args 0]
    if { [string index $flag 0] != "-" } {
        set var $flag
        set flag "-get"
    } else {
        set var [lindex $args 1]
    }
    switch -- $flag {
        -set {
            set value [lindex $args 2]
            set tdav_conn($var) $value
            return $value
        }
        -get {
            if { [info exists tdav_conn($var)] } {
                return $tdav_conn($var)
            } else {
                return [ad_conn $var]
            }               
        }
    }
}
    
ad_proc -public oacs_dav::register_folder {
    {-enabled_p "t"}
    folder_id
    node_id
} {
    add a uri to dav support
    @param folder_id
    @param node_id
    Register a root WebDAV enabled folder for a site node_id
    All requests that resolve to this site node id will be checked for
    WebDAV content using this folder as the root. Only one folder per
    node_id can be registered.
} {

    db_transaction {
        db_dml add_folder ""
    } on_error {
        ns_log error "OACS-DAV Failed attempt to add folder_id $folder_id as a WebDAV enabled folder for node_id $node_id. One folder is already registered"
        error "Only one folder per node_id may be registered."
    }
}

ad_proc -public oacs_dav::unregister_folder {
    folder_id
    node_id
} {
    remove a uri from dav support
    @param folder_id
    @param node_id
} {
    db_dml remove_folder ""
}

ad_proc -public oacs_dav::item_parent_folder_id {
    uri
} {
    get the folder_id of the parent of an item
    from the uri
    @param uri
    @returns parent_folder_id or empty string if folder does not exist
} {

    array set sn [oacs_dav::request_site_node $uri]
    set node_id $sn(node_id)
    set root_folder_id [oacs_dav::request_folder_id $node_id]
    set urlv [split [string trimright [string range $uri [string length $sn(url)] end] "/"] "/"]
    if {[llength $urlv] >1} {
        set parent_name [join [lrange $urlv 0 [expr [llength $urlv] -2 ] ] "/" ]
    } else {
        set parent_name "/"
    }
    ns_log debug "\nparent_folder_id urlv $urlv parent_name $parent_name uri $uri"
    if {[string equal [string trimright $parent_name "/"] [string trimright $sn(url) "/"]]} {
        # content_item__get_id can't resolve "/"
        # because it strips the leading and trailing /
        # from the url you pass in, and cr_items.name of the folder
        # is not and empty string
        set parent_id $root_folder_id
    } else {
        set parent_id [db_exec_plsql get_parent_folder_id ""]
    }
    return $parent_id
}

ad_proc -public oacs_dav::uri_prefix {
} {
    @return URI prefix to use for WebDAV requests
} {
    set oacs_dav_package_id [apm_package_id_from_key "oacs-dav"]
    return [parameter::get -package_id $oacs_dav_package_id -parameter "WebDAVURLPrefix" -default "/dav"]
}

ad_proc -public oacs_dav::conn_setup {} {
    Setup oacs_dav::conn, authenticate user
} {
    ad_conn -reset
    set uri [ns_urldecode [ns_conn url]]
    ns_log debug "\nconn_setp uri \"$uri\" "
    set dav_url_regexp "^[oacs_dav::uri_prefix]"
    regsub $dav_url_regexp $uri {} uri
    if {[empty_string_p $uri]} {
        set uri "/"
    }
    oacs_dav::conn -set uri $uri
    set method [ns_conn method]
    ns_log debug "\noacs_dav::conn_setup: uri \"$uri\" method $method"
    oacs_dav::set_user_id
    ns_log debug "\noacs_dav::conn_setup: uri \"$uri\" method $method user_id [oacs_dav::conn user_id]"
    array set sn [oacs_dav::request_site_node $uri]
    set node_id [oacs_dav::conn -set node_id $sn(node_id)]
    set package_id [oacs_dav::conn -set package_id $sn(package_id)]
    set folder_id [oacs_dav::conn -set folder_id [oacs_dav::request_folder_id [oacs_dav::conn node_id]]]
    set urlv [oacs_dav::conn -set urlv [split [string trimright $uri "/"] "/"]]

    set destination [ns_urldecode [ns_set iget [ns_conn headers] Destination]]

    regsub {https?://[^/]+/} $destination {/} dest

     regsub $dav_url_regexp $dest {} dest

    oacs_dav::conn -set oacs_destination $dest
 
    if {![empty_string_p $dest]} {
        oacs_dav::conn -set dest_parent_id [oacs_dav::item_parent_folder_id $dest]
    }

    # we need item_id and content_type
    # we should use content::init but that has caching and  I don't
    # have time to resolve the issues that raises right now
    # a full-featured, consistently used tcl api for CR will fix that
    if {[llength $urlv] > 2} {
        set parent_url [join [lrange $urlv 0 [expr [llength $urlv] -2 ] ] "/" ]
    } else {
        set parent_url "/"
    }
    ns_log debug "\noacs_dav::conn_setup: handle request parent_url $parent_url length urlv [llength $urlv] urlv $urlv"
    set item_name [lindex $urlv end]
    if {[empty_string_p $item_name]} {
        # for propget etc we need the name of the folder
        # the last element in urlv for a folder is an empty string
        set item_name [lindex [split [string trimleft $parent_url "/"] "/"] end]
    }
    oacs_dav::conn -set item_name $item_name
        ns_log debug "\noacs_dav::conn_setup: handle request parent_url $parent_url length urlv [llength $urlv] urlv $urlv item_name $item_name" 
    set parent_id [oacs_dav::item_parent_folder_id $uri]

    set item_id [oacs_dav::conn -set item_id [db_exec_plsql get_item_id ""]]
    ns_log debug "\noacs_dav::conn_setup: uri $uri parent_url $parent_url folder_id $folder_id"
    if {[string equal [string trimright $uri "/"] [string trimright $sn(url) "/"]]} {
        set item_id [oacs_dav::conn -set item_id $folder_id]
    }

    ns_log debug "\noacs_dav::conn_setup: item_id $item_id"
}

ad_proc -public oacs_dav::children_have_permission_p {
    -user_id
    -item_id
    -privilege
} {
    Check permission on child items of item_id for user_id with privilege
    @param user_id
    @param item_id
    @param privilege 

    @return retursn 0 if user does not have privilege over all childern otherwise return 1
} {
    set child_count [db_string child_perms ""]
    ns_log notice "\n ----- \n oacs_dav::children_have_permission_p \n child_count = $child_count \n ----- \n"
    incr child_count [db_string revision_perms ""]
    ns_log notice "\n ----- \n oacs_dav::children_have_permission_p \n child_count = $child_count \n ----- \n"
    ns_log notice "\n ----- \n oacs_dav::children_have_permission_p \n return [expr $child_count == 0] \n ----- \n"
    return [expr $child_count == 0]
}

ad_proc -public oacs_dav::handle_request { uri method args } {
    dispatch request to the proper service contract implmentation
} {

    set uri [oacs_dav::conn uri]
    set method [string tolower [ns_conn method]]
    ns_log debug "\noacs_dav::handle_request method=$method uri=$uri"    
    set item_id [oacs_dav::conn item_id]
    set folder_id [oacs_dav::conn folder_id]
    set package_id [oacs_dav::conn package_id]
    set node_id [oacs_dav::conn node_id]
    set package_key [apm_package_key_from_id $package_id]    

    ns_log debug "\noacs_dav::handle_request item_id is $item_id"
    if {[empty_string_p $item_id]} {
        ns_log debug "\noacs_dav::handle_request item_id is empty"
        # set this to null if nothing exists, only valid on PUT or MKCOL
        # to create a new item, otherwise we bail
        # item for URI does not exist
        # ask package what content type to use
            switch -- $method {
                mkcol {
                    if {![acs_sc_binding_exists_p dav_mkcol_type $package_key]} {
                        set content_type "content_folder"
                    } else {
                        set content_type [acs_sc_call dav_mkcol_type get_type "" $package_key]
                    }
                }
                put {
                    if {![acs_sc_binding_exists_p dav_put_type $package_key]} {
                        set content_type "content_revision"
                    } else {
                        set content_type [acs_sc_call dav_put_type get_type "" $package_key]
                    }

                } 
                lock {
                    # asssume resource on NULL LOCK
                    set content_type "content_revision"
                }
                default {
                    # return a 404 or other error
                    ns_log debug "\noacs_dav::handle_request: 404 handle request Item not found method $method URI $uri"
                    ns_return 404 text/html "File Not Found"
                    return
                }
            }
    
    } else {
        # get content type of existing item
        set content_type \
            [oacs_dav::conn -set content_type \
                 [db_string get_content_type "" -default "content_revision"]]
    }
    # use content type
    # i think we should walk up the object type hierarchy up to
    # content_revision if we don't find an implementation
    # implementation name is content_type

       set real_content_type [oacs_dav::conn -set real_content_type $content_type]

    while {![acs_sc_binding_exists_p dav $content_type]} {
        # go up content_type hierarchy
        # we do the query here to avoid running the query
        # when the implementation for the content_type does
        # exist
                         set content_type [db_string supertype "select supertype from acs_object_types where object_type = :content_type" -default ""]
                                          if { $content_type eq "content_revision"} {break}
                                               if { $content_type eq ""} { error "no dav implementation found for content_type $real_content_type" }
                                                    ns_log Notice "now looking for a dav implementation for content_type $content_type"
    }

    oacs_dav::conn -set content_type $content_type

    # probably should catch this

    ns_log debug "\noacs_dav::handle_request method $method uri $uri item_id $item_id folder_id $folder_id package_id $package_id node_id $node_id content_type $content_type args $args"

    set response [acs_sc_call dav $method "" $content_type]

    # here the sc impl might return us some data,
    # then we would probably have to send that to tDAV for processing
    ns_log debug "\nDAV: response is \"$response\""

    if {![string equal -nocase "get" $method]
        && ![string equal -nocase "head" $method]} {

        tdav::respond $response
    }
}

ad_proc -public oacs_dav::request_site_node { uri } {
    resolves uri to a site node_id
} {
    # if you want to serve up DAV content at a different URL
    # you still need to mount a package in the site-map
    # might change later when we figure out how to actually use it 
    ns_log debug "\nOACS-DAV!! uri $uri"
    set sn [site_node::get -url $uri]
    return $sn
}

ad_proc -public oacs_dav::request_folder_id { node_id } {
    resolves a node_id to a DAV enabled folder_id
    @param node_id site node_id of request
    @returns folder_id, or empty string if no folder exists
    in dav_package_folder_map for this node_id
} {
    return [db_string get_folder_id "" -default ""]
}

namespace eval oacs_dav::impl::content_folder {}

# this is probably going away, is there such thing as "source"
# of a folder/collection?

ad_proc oacs_dav::impl::content_folder::get {} {
    GET DAV method for content folders
    can't get a folder
} {
   
    # return something
    # if its just a plain file, and a GET then do we need to send anything
    # extra or just the file?
    return [list 409]
}

ad_proc oacs_dav::impl::content_folder::head {} {
    HEAD DAV method for content folders
    can't get a folder
} {

    # I am not sure what the behavior is, but the client
    # should be smart enough to do a propfind on a folder/collection
    
    return [list 409]
}

ad_proc oacs_dav::impl::content_folder::mkcol {} {
    MKCOL DAV method for generic content folder
    @author Dave Bauer
} {
    set uri [oacs_dav::conn uri]
    set user_id [oacs_dav::conn user_id]
    set peer_addr [oacs_dav::conn peeraddr]
    set item_id [oacs_dav::conn item_id]
    set fname [oacs_dav::conn item_name]
    set parent_id [oacs_dav::item_parent_folder_id $uri]
    if {[empty_string_p $parent_id]} {
        return [list 409]
    }
    if { ![empty_string_p $item_id]} {
        return [list 405]
    }
    
    # probably have to revisit setting content_types allowed
    # and permissions, but inheriting from the parent seems
    # reasonable
    
    db_transaction {
            set new_folder_name $fname
            set label $fname
            set description $fname 
            set new_folder_id [db_exec_plsql create_folder ""]
            set response [list 201]
    } on_error {
        set response [list 500]
    }
   
    return $response
}

ad_proc oacs_dav::impl::content_folder::copy {} {
    COPY DAV method for generic content folder
} {
    set package_id [oacs_dav::conn package_id]
    set user_id [oacs_dav::conn user_id]
    set peer_addr [oacs_dav::conn peeraddr]
    set copy_folder_id [oacs_dav::conn item_id]
    set overwrite [oacs_dav::conn overwrite]
    set target_uri [oacs_dav::conn oacs_destination]
    set new_parent_folder_id [oacs_dav::conn dest_parent_id]
    set durlv [split [string trimright $target_uri "/"] "/"]
    set new_name [lindex $durlv end]
    set uri [oacs_dav::conn uri]
    # check that destination exists and is WebDAV enabled
    # when depth is 0 copy just the folder
    # when depth is 1 copy contents
    ns_log debug "\nDAV Folder Copy dest $target_uri parent_id $new_parent_folder_id"
    if {[empty_string_p $new_parent_folder_id]} {
        return [list 409]
    }

    set dest_item_id [db_string get_dest_id "" -default ""]
    if {![empty_string_p $dest_item_id]} {
        ns_log debug "\n ----- \n DAV Folder Copy Folder Exists item_id $dest_item_id overwrite $overwrite \n ----- \n"
        if {![string equal -nocase $overwrite "T"]} {
            return [list 412]
        } elseif {![permission::permission_p \
                     -object_id $dest_item_id \
                     -party_id $user_id \
                      -privilege "write"]} {
            ns_returnunauthorized
        } 
        # according to the spec copy with overwrite means
        # delete then copy
        set children_permission_p [oacs_dav::children_have_permission_p -item_id $copy_folder_id -user_id $user_id -privilege "delete"]
        if {!$children_permission_p} {
            return [list 409]
        }
        if {![string equal "unlocked" [tdav::check_lock $target_uri]]} {
            return [list 423]
        }
        db_exec_plsql delete_for_copy ""
        set response [list 204]
        ns_log debug "\n ----- \n  CONTENT_FOLDER::COPY OVERWRITING RETURNING 204  \n ----- \n"
    } else {
        set response [list 201]
    }
    set err_p 0
    db_transaction {
        db_exec_plsql copy_folder ""
        # we need to do this because in oracle content_folder__copy
        # is a procedure and does not return the new folder_id
        set new_folder_id [db_string get_new_folder_id ""]
        # update all child items revisions to live revision
        db_dml update_child_revisions "" 
    } on_error {
        set err_p 1
    }

    if { $err_p } {
        return [list 500]
    }

    tdav::copy_props $uri $target_uri
    return $response
}

ad_proc oacs_dav::impl::content_folder::move {} {
    MOVE DAV method for generic content folder
} {
    set package_id [oacs_dav::conn package_id]
    set user_id [oacs_dav::conn user_id]
    set peer_addr [oacs_dav::conn peeraddr]
    set uri [oacs_dav::conn uri]
    set target_uri [oacs_dav::conn oacs_destination]
    set move_folder_id [oacs_dav::conn item_id]
    set item_name [oacs_dav::conn item_name]
    set new_parent_folder_id [oacs_dav::conn dest_parent_id]
    set cur_parent_folder_id [oacs_dav::item_parent_folder_id $uri]
    set turlv [split [string trimright $target_uri "/"] "/"]
    set new_name [lindex $turlv end]
    set overwrite [oacs_dav::conn overwrite]

    if {![string equal "unlocked" [tdav::check_lock $uri]]} {
        return [list 423]
    }
    
    if {[empty_string_p $new_parent_folder_id]} {
        set response [list 412]
        return $response
    }

    set dest_item_id [db_string get_dest_id "" -default ""]
    ns_log debug "\n@DAV@@ folder move new_name $new_name dest_id $dest_item_id new_folder_id $new_parent_folder_id \n" 

    if {![empty_string_p $dest_item_id]} {

        if {![string equal -nocase $overwrite "T"]} {
            return [list 412]
        } elseif {![permission::permission_p \
                     -object_id $dest_item_id \
                     -party_id $user_id \
                      -privilege "write"]} {
            ns_returnunauthorized
        }
        # according to the spec move with overwrite means
        # delete then move
        if {![string equal "unlocked" [tdav::check_lock $target_uri]]} {
            return [list 423]
        }
        # TODO check if we have permission over everything inside
        set children_permission_p [oacs_dav::children_have_permission_p -item_id $move_folder_id -user_id $user_id -privilege "delete"]
        if {!$children_permission_p} {
            return [list 409]
        }
        db_exec_plsql delete_for_move ""
        set response [list 204]
        ns_log debug "\n ----- \n  CONTENT_FOLDER::MOVE OVERWRITING RETURNING 204  \n ----- \n"
    } else {
        set response [list 201]
    }

    # don't let anyone move root DAV folders in the
    # dav_site_node_folder_map
    if {![string equal [db_string site_node_folder ""] 0]} {
        return [list 403]
    }
    
    set err_p 0
    db_transaction {
        if {![string equal $cur_parent_folder_id $new_parent_folder_id]} {
            ns_log debug "\n@@DAV@@ move folder $move_folder_id"
            db_exec_plsql move_folder ""
            # change label if name is different
            if {![string equal $new_name $item_name]} {
                db_dml update_label ""
            }
        } elseif {![empty_string_p $new_name]} {
            ns_log debug "\n@@DAV@@ move folder rename $move_folder_id to $new_name"
            db_exec_plsql rename_folder ""
        }
        
    } on_error {
        set err_p 1
    }

    if { $err_p } {
        return [list 500]
    }

    tdav::copy_props $uri $target_uri
    tdav::delete_props $uri
    tdav::remove_lock $uri
    return $response
}

ad_proc oacs_dav::impl::content_folder::delete {} {
    DELETE DAV method for generic content folder
} {
    set package_id [oacs_dav::conn package_id]
    set user_id [oacs_dav::conn user_id]
    set peer_addr [oacs_dav::conn peeraddr]
    set item_id [oacs_dav::conn item_id]
    set uri [oacs_dav::conn uri]

    if {![string equal "unlocked" [tdav::check_lock $uri]]} {
        return [list 423]
    }
    set children_permission_p [oacs_dav::children_have_permission_p -item_id $item_id -user_id $user_id -privilege "delete"]
        if {!$children_permission_p} {
            return [list 403]
        }
    if {[catch {db_exec_plsql delete_folder ""} errmsg]} {
        ns_log error "content_folder::delete $errmsg"
        set response [list 500]
#       ns_log debug "\nCONTEXT IDS [db_list get_ids "select object_id from acs_objects where context_id=:item_id"]"
    } else {
        set response [list 204]
        tdav::delete_props $uri
        tdav::remove_lock $uri
    }

    return $response
}

ad_proc oacs_dav::impl::content_folder::propfind {} {
    PROPFIND DAV method for generic content folder
} {
    set user_id [oacs_dav::conn user_id]
    set depth [oacs_dav::conn depth]
    set encoded_uri [list]
    foreach fragment [split [ad_conn url] "/"] {
        lappend encoded_uri [oacs_dav::urlencode $fragment]
    }   

    set folder_uri "[ad_conn location][join $encoded_uri "/"]"
    
    # this is wacky, but MS Web Folders usually (but not always)
    # requests a collection without a trailing slash
    # if you return a propfind with the href for the collection
    # with a trailing slash, sometimes (but not always) it will
    # get confused and show the collection as a member of itself
    regsub {/$} $folder_uri {} folder_uri
    if {[empty_string_p $depth]} {
        set depth 0
    }

    set prop_req [oacs_dav::conn prop_req]
    set folder_id [oacs_dav::conn item_id]

    # append the properties into response
    set all_properties [list]
    # hack to get the OS time zone to tack on the end of oracle timestamps
    # until we stop supporting oracle 8i
    set os_time_zone [clock format [clock seconds] -format %Z]
    db_foreach get_properties "" {
        set name $name
        set etag "1f9a-400-3948d0f5"
        set properties [list]
        # is "D" the namespace??
        lappend properties [list "D" "getcontentlength"] $content_length

#       ns_log debug "\nDAVEB item_id $item_id folder_id $folder_id $item_uri"
        if {$item_id == $folder_id} {
            set item_uri "/"
        } else {
            set encoded_uri [list]
            foreach fragment [split $item_uri "/"] {
                lappend encoded_uri [oacs_dav::urlencode $fragment]
#               ns_log debug "\npropfind: fragment \"$fragment\" encoded_uri \"$encoded_uri\" "
            }
            set item_uri "/[join $encoded_uri "/"]"
          
        }
        
        lappend properties [list "D" "getcontenttype"] $mime_type
        # where do we get an etag from?
        lappend properties [list "D" "getetag"] $etag
        lappend properties [list "D" "getlastmodified"] $last_modified
        lappend properties [list "D" "creationdate"] $creation_date
        if {$collection_p} {
            lappend properties [list "D" "resourcetype"] "D:collection"
        } else {
        lappend properties [list "D" "resourcetype"] ""
        }
    
        # according to Todd's example
        # resourcetype for a folder(collection) is <D:collection/>
        # and getcontenttype is */*
        foreach i [tdav::get_user_props ${folder_uri}${item_uri} $depth $prop_req] {
            lappend properties $i
        }
        lappend all_properties [list ${folder_uri}${item_uri} $collection_p $properties]
    }

    set response [list 207 $all_properties]
    
    return $response


}

ad_proc oacs_dav::impl::content_folder::proppatch {} {
    PROPPATCH DAV method for generic content folder
    user-properties are stored in the filesystem by tDAV
    this doesn't do anything until tDAV allows storage of
    user properties in the database
} {
    set uri [oacs_dav::conn uri]

    if {![string equal "unlocked" [tdav::check_lock $uri]]} {
        return [list 423]
    }

    set response [tdav::update_user_props $uri [oacs_dav::conn prop_req]]
    return [list 207 $response]
}

ad_proc oacs_dav::impl::content_folder::lock {} {
    LOCK DAV method for generic content folder
} {
    set uri [oacs_dav::conn uri]
    set owner [oacs_dav::conn lock_owner]
    set scope [oacs_dav::conn lock_scope]
    set type [oacs_dav::conn lock_type]

    if {![string equal "unlocked" [tdav::check_lock $uri]]} {
        set ret_code 423
        
        set response [list $ret_code]
    } else {
        set depth [tdav::conn depth]
        set timeout [tdav::conn lock_timeout]
        if {[empty_string_p $timeout]} {
            set timeout [parameter::get_from_package_key -parameter "DefaultLockTimeout" -package_key "oacs-dav" -default "300"]
        }
        set token [tdav::set_lock $uri $depth $type $scope $owner $timeout]
        set ret_code 200
        set response [list $ret_code [list depth $depth token $token timeout $timeout owner $owner scope $scope type $type]]
    }
    return $response
}

ad_proc oacs_dav::impl::content_folder::unlock {} {
    UNLOCK DAV method for generic content folder
} {
    set uri [oacs_dav::conn uri]

    if {![string equal unlocked [tdav::check_lock_for_unlock $uri]]} {
        set ret_code 423
        set body "Resource is locked."
    } else {
        ns_log debug "\ntdav::check_lock_for_unlock = [tdav::check_lock_for_unlock $uri]]"
        tdav::remove_lock $uri
        set ret_code 204
        set body ""
    }

    return [list $ret_code $body]
}

namespace eval oacs_dav::impl::content_revision {}

ad_proc oacs_dav::impl::content_revision::get {} {
    GET DAV method for generic content revision
    @author Dave Bauer
    @param uri
} {

    set item_id [oacs_dav::conn item_id]

    #should return the DAV content for the content item
    #for now we always get live/latest revision

    cr_write_content -item_id $item_id

}

ad_proc oacs_dav::impl::content_revision::head {} {
    GET DAV method for generic content revision
    @author Dave Bauer
    @param uri
} {

    set item_id [oacs_dav::conn item_id]

    # cr_write_content works correctly for HEAD requests
    # with filesystem storage, it sends out the content
    # on lob storage. that needs to be fixed.
    
    cr_write_content -item_id $item_id
}

ad_proc oacs_dav::impl::content_revision::put {} {
    PUT DAV method for generic content revision
    @author Dave Bauer
} {
    set user_id [oacs_dav::conn user_id]
    set item_id [oacs_dav::conn item_id]
    set root_folder_id [oacs_dav::conn folder_id]
    set uri [oacs_dav::conn uri]

    if {![string equal "unlocked" [tdav::check_lock $uri]]} {
        return [list 423]
    }

    set tmp_filename [oacs_dav::conn tmpfile]
    set tmp_size [file size $tmp_filename]
    # authenticate that user has write privilege

    # we need to calculate parent_id from the URI
    # it might not be the root DAV folder for the package
    # check for folder or not
    set urlv [split [oacs_dav::conn uri] "/"]

    set name [oacs_dav::conn item_name]
    set parent_id [oacs_dav::item_parent_folder_id $uri]
    if {[empty_string_p $parent_id]} {
        set response [list 409]
        return $response
    }

    # create new item if necessary
    db_transaction {
        set mime_type [cr_filename_to_mime_type $name]
        if {[empty_string_p $item_id]} {
            # this won't really work very nicely if we support
            # abstract url type names... maybe chop off the extension
            # when we name the object?

            set revision_id [cr_import_content \
                                 -storage_type file \
                                 $parent_id \
                                 $tmp_filename \
                                 $tmp_size \
                                 $mime_type \
                                 $name]

            if {[file exists [tdav::get_lock_file $uri]]} {
                # if there is a null lock use 204
                set response [list 204]
            } else {
                set response [list 201]
            }

        } else {
            set revision_id [cr_import_content \
                                 -item_id $item_id \
                                 -storage_type file \
                                 $parent_id \
                                 $tmp_filename \
                                 $tmp_size \
                                 $mime_type \
                                 $name]
            set response [list 204]
        }
        db_dml set_live_revision ""

    } on_error {
        set response [list 500]
        ns_log error "oacs_dav::impl::content_revision::put: $errmsg"
    }
    file delete $tmp_filename
    # at least we need to return the http_status
    return $response

}

ad_proc oacs_dav::impl::content_revision::propfind {} {
    PROPFIND DAV method for generic content revision
    @author Dave Bauer
} {
    set user_id [oacs_dav::conn user_id]
    set item_id [oacs_dav::conn item_id]
    set folder_id [oacs_dav::conn folder_id]
    set uri [oacs_dav::conn uri]

    set depth [oacs_dav::conn depth]
    set prop_req [oacs_dav::conn prop_req]

    set os_time_zone [clock format [clock seconds] -format %Z]

    # find the values
    db_1row get_properties ""
    set etag "1f9a-400-3948d0f5"
    set properties [list]
    # is "D" the namespace??
    lappend properties [list "D" "getcontentlength"] $content_length
#    lappend properties [list "D" "uri"] $item_uri
    lappend properties [list "D" "getcontenttype"] $mime_type
    # where do we get an etag from?
    lappend properties [list "D" "getetag"] $etag
    lappend properties [list "D" "getlastmodified"] $last_modified
    lappend properties [list "D" "creationdate"] $creation_date
    lappend properties [list "D" "resourcetype"] ""

        foreach i [tdav::get_user_props ${uri} $depth $prop_req] {
            lappend properties $i
        }

    set response [list 207 [list [list $uri "" $properties]]]
    
    return $response
}

ad_proc oacs_dav::impl::content_revision::proppatch {} {
    PROPPATCH DAV method for generic content revision
    We store all user properties in the filesystem using tDAV for now
    So this is just a stub until we can get everything stored in the
    database.
    @author Dave Bauer
} {
    # get the properties out of the list
    set uri [oacs_dav::conn uri]

    if {![string equal "unlocked" [tdav::check_lock $uri]]} {
        return [list 423]
    }

    # set the values
    set response [tdav::update_user_props $uri [oacs_dav::conn prop_req]]
    # return results
    return [list 207 $response]
}

ad_proc oacs_dav::impl::content_revision::delete {} {
    DELETE DAV method for generic content revision
    @author Dave Bauer
} {
    set package_id [oacs_dav::conn package_id]
    set user_id [oacs_dav::conn user_id]
    set peer_addr [oacs_dav::conn peeraddr]
    set item_id [oacs_dav::conn item_id]
    set uri [oacs_dav::conn uri]
    if {![string equal "unlocked" [tdav::check_lock $uri]]} {
        return [list 423]
    }
    if {[catch {db_exec_plsql delete_item ""} errmsg]} {
        set response [list 500]
    } else {
        set response [list 204]
        tdav::delete_props $uri
        tdav::remove_lock $uri
    }
    return $response
}

ad_proc oacs_dav::impl::content_revision::copy {} {
    COPY DAV method for generic content revision
    @author Dave Bauer
} {
    set package_id [oacs_dav::conn package_id]
    set user_id [oacs_dav::conn user_id]
    set peer_addr [oacs_dav::conn peeraddr]
    set uri [oacs_dav::conn uri]
    # check for write permission on target folder
    set target_uri [oacs_dav::conn oacs_destination]
    set copy_item_id [oacs_dav::conn item_id]
    set overwrite [oacs_dav::conn overwrite]
    set turlv [split $target_uri "/"]
    set new_name [lindex $turlv end]
    set new_parent_folder_id [oacs_dav::conn dest_parent_id]
    if {[empty_string_p $new_parent_folder_id]} {
        return [list 409]
    }
    set dest_item_id [db_string get_dest_id "" -default ""]
ns_log debug "\nDAV Revision Copy dest $target_uri parent_id $new_parent_folder_id"
    if {![empty_string_p $dest_item_id]} {
        ns_log debug "\n ----- \n DAV Revision Copy Folder Exists item_id $dest_item_id overwrite $overwrite \n ----- \n"       
        if {![string equal -nocase $overwrite "T"]} {
            return [list 412]
        } elseif {![permission::permission_p \
                     -object_id $dest_item_id \
                     -party_id $user_id \
                      -privilege "write"]} {
                ns_returnunauthorized
        } 
        # according to the spec copy with overwrite means
        # delete then copy
        ns_log debug "\noacs_dav::revision::copy checking for lock on target"
        if {![string equal "unlocked" [tdav::check_lock $target_uri]]} {
            return [list 423]
        }

        db_exec_plsql delete_for_copy ""
        set response [list 204]
        ns_log debug "\n ----- \n  CONTENT_REVISION::COPY OVERWRITING RETURNING 204  \n ----- \n"
    } else {
        set response [list 201]
    }

    set err_p 0
    db_transaction {
        set item_id [db_exec_plsql copy_item ""]
        db_dml set_live_revision ""
    } on_error {
        set err_p 1
    }

    if { $err_p } {
        return [list 500]
    }

    tdav::copy_props $uri $target_uri
    return $response
}

ad_proc oacs_dav::impl::content_revision::move {} {
    MOVE DAV method for generic content revision
    @author Dave Bauer
} {

    set package_id [oacs_dav::conn package_id]
    set user_id [oacs_dav::conn user_id]
    set peer_addr [oacs_dav::conn peeraddr]
    set item_id [oacs_dav::conn item_id]
    set item_name [oacs_dav::conn item_name]
    set uri [oacs_dav::conn uri]
    set target_uri [oacs_dav::conn oacs_destination]
    set cur_parent_folder_id [oacs_dav::conn folder_id]
    set new_parent_folder_id [oacs_dav::conn dest_parent_id]
    set turlv [split $target_uri "/"]
    set new_name [lindex $turlv end]
    set overwrite [oacs_dav::conn overwrite]
    if {[empty_string_p $new_parent_folder_id]} {
        return [list 409]
    }

    if {![string equal "unlocked" [tdav::check_lock $uri]]} {
        return [list 423]
    }
ns_log debug "\nDAV Revision move dest $target_uri parent_id $new_parent_folder_id"
    set dest_item_id [db_string get_dest_id "" -default ""]
    if {![empty_string_p $dest_item_id]} {
        ns_log debug "\n ----- \n DAV Revision move Folder Exists item_id $dest_item_id overwrite $overwrite \n ----- \n"       
        if {![string equal -nocase $overwrite "T"]} {
            return [list 412]
        } elseif {![permission::permission_p \
                     -object_id $dest_item_id \
                     -party_id $user_id \
                      -privilege "write"]} {
                return [list 401]
        } 
        if {![string equal "unlocked" [tdav::check_lock $target_uri]]} {
            return [list 423]
        }

        db_exec_plsql delete_for_move ""
        set response [list 204]
        ns_log debug "\n ----- \n  CONTENT_REVISION::MOVE OVERWRITING RETURNING 204  \n ----- \n"
    } else {
        set response [list 201]
    }

    set err_p 0
    db_transaction {
        if {![string equal $cur_parent_folder_id $new_parent_folder_id]} {
                db_exec_plsql move_item ""

        } elseif {![empty_string_p $new_name] } {
            db_exec_plsql rename_item ""
        }
       if {![string equal $item_name $new_name]} {
            db_dml update_title ""
        }
    } on_error {
        set err_p 1
    }

    if { $err_p } {
        return [list 500]
    }

    tdav::copy_props $uri $target_uri
    tdav::delete_props $uri
    tdav::remove_lock $uri
    return $response
}


ad_proc oacs_dav::impl::content_revision::mkcol {} {
    MKCOL DAV method for generic content revision
    @author Dave Bauer
} {
    # not allowed to create a collection inside a resource
    # return some sort of error
    set response [list 405]
    return $response
}

ad_proc oacs_dav::impl::content_revision::lock {} {
    LOCK DAV method for generic content revision
} {
    set uri [oacs_dav::conn uri]
    set owner [oacs_dav::conn lock_owner]
    set scope [oacs_dav::conn lock_scope]
    set type [oacs_dav::conn lock_type]

    if {![string equal "unlocked" [tdav::check_lock $uri]]} {
        set ret_code 423
        
        set response [list $ret_code]
    } else {
        set depth [tdav::conn depth]
        set timeout [tdav::conn lock_timeout]
        if {[empty_string_p $timeout]} {
            set timeout 300
        }
        set token [tdav::set_lock $uri $depth $type $scope $owner $timeout]
        set ret_code 200
        set response [list $ret_code [list depth $depth token $token timeout $timeout owner $owner scope $scope type $type]]
    }
    return $response
}

ad_proc oacs_dav::impl::content_revision::unlock {} {
    UNLOCK DAV method for generic content revision
} {
    set uri [oacs_dav::conn uri]

    if {![string equal unlocked [tdav::check_lock_for_unlock $uri]]} {
        set ret_code 423
        set body "Resource is locked."
    } else {
        ns_log debug "\ntdav::check_lock_for_unlock = [tdav::check_lock_for_unlock $uri]]"
        tdav::remove_lock $uri
        set ret_code 204
        set body ""
    }

    return [list $ret_code $body]
}
