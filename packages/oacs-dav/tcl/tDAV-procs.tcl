#
# tDAV.tcl
# 
# Copyright 2003 Musea Technologies
#
# http://www.museatech.net
#
# $Id
#
# bugs to:
# toddg@tdav.museatech.net
#
# Authors: Todd Gillespie
#          Dave Bauer 
#
# Based upon sources from:
#
# webdav.tcl    
#
# A WebDAV implementation for AOLserver 3.x.
#
# Copyright (c) 2000-2001 Panoptic Computer Network.
# All rights reserved.
#
# http://www.panoptic.com/
#


# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA



# ------------------------------------------------------------
# Silly workaround so that AOLserver can find scripts via "package require".
# set tcl_library [file join $tcl_pkgPath tcl${tcl_version}]
# source [file join $tcl_library init.tcl]
# ------------------------------------------------------------

package require tdom

namespace eval tdav {}

# workaround if not installed in OACS

# tdav::filter_webdav_options
#
#     Handles OPTIONS HTTP requests
#
# Arguments:
#     none
#
# Results:
#     returns an HTTP response containing WebDAV options supported
#
# TODO Make this smart to return options based on URI
# We still need to pretend that the site root supports DAV 
# methods or some clients get confused.

proc tdav::filter_webdav_options {args} {
    set dav_level {1,2}
    ns_set put [ns_conn outputheaders] DAV $dav_level

    # The allowed webdav options for the share that the requested
    # URL belongs to.
    
    foreach {uri options} [nsv_array get tdav_options] {
	if {[regexp $uri [ns_conn url]]} {
	    ns_set put [ns_conn outputheaders] Allow [join $options {, }]
	    break
	}
    }

    # This tells MSFT products to skip looking for FrontPage extensions.

    ns_set put [ns_conn outputheaders] MS-Author-Via DAV
    ns_return 200 text/plain {}
    return filter_return
}

# ------------------------------------------------------------
# first check XML validity
# add PROPPATCH
# split into prop error function?
# get body

proc tdav::xml_valid_p {xml_doc} {
    # TODO use tnc with tDOM to vaildate the xml request
    return 1
    
}

# tdav::read_xml
#
#     reads xml from connection
#
# Arguments:
#     none
#
# Results:
#
#     returns xml text of request

proc tdav::read_xml {} {
    set fp ""
    while {$fp == ""} {
	set tmpfile [ns_tmpnam]
	set fp [ns_openexcl $tmpfile]
    }
    #fconfigure $fp -translation binary -encoding binary
#    fconfigure $fp -encoding utf-8
    ns_conncptofp $fp
    seek $fp 0
    set xml [read $fp]
    close $fp
    ns_unlink -nocomplain $tmpfile
    ns_log debug "\n-----tdav::read_xml XML = -----\n $xml \n ----- end ----- \n "
    return $xml
}

# tdav::dbm_write_list
#
#      helper fxns for dbm-like props
#      Writes a list to a properties file
#
# Arguments:
#     uri URI of the request being handled
#     list properties formatted in a Tcl list as
#     propertyname value 
#
# Results:
#     file written including contents of list

proc tdav::dbm_write_list {uri list} {
    set file [tdav::get_prop_file $uri]
    if {[catch {set f [open $file w]} err]} {
	# probably no parent dir, create it:
	file mkdir [file dirname $file]
	# open again:
	set f [open $file w] 
    }
    fconfigure $f -encoding utf-8
    puts $f $list
    close $f
}

# tdav::get_prop_file
#
#     Get the filename that contains user properties.
#
# Arguments:
#     uri URI to get properties filename for
#
# Results:
#     Returns the filename containing user properties. 

proc tdav::get_prop_file {uri} {
    # just in case.  I hate that 'file join' fails on this
    regsub {^/} $uri {} uri

    # log this for failed config section
    set name [ns_config "ns/server/[ns_info server]/tdav" propdir]

    if {[string equal "" $name]} {
	set name [file join [ns_info pageroot] "../propdir/${uri}"]
    } else {
	set name [file join $name $uri]
    }

    # catch uncreated parent dirs here:
    if {![file exists [file dirname $name]]} {
	# no parent dir, create it:
	file mkdir [file dirname $name]
	# safe for public consumption?
    }
    return "${name}.prop"
}

# tdav::get_lock_file
#
#     Get the filename of the lock file
#
# Arguments:
#     uri URI to get the lock filename for
#
# Results:
#     Returns the filename containing the lock information for URI

proc tdav::get_lock_file {uri} {
    # just in case.  I hate that 'file join' fails on this
    regsub {^/} $uri {} uri

    # log this for failed config section
    set name [ns_config "ns/server/[ns_info server]/tdav" lockdir]

    if {[string equal "" $name]} {
	set name [file join [ns_info pageroot] "../lockdir/${uri}"]
    } else {
	set name [file join $name $uri]
    }
    if {![file exists [file dirname $name]]} {
	# no parent dir, create it:
	file mkdir [file dirname $name]
	# safe for public consumption?
    }

    return "${name}.lock"
}

# tdav::delete_props
#
#     Delete the properties file for a URI
#
# Arguments:
#    uri URI of properties file to delete
#
# Results:
#     File containing user properties for URI is deleted

proc tdav::delete_props {uri} {
    set entry [tdav::get_prop_file $uri]
    catch {[file delete -force $entry]} err
    return err
}

# tdav::move_props
#
#     Move the properties file for a URI
#
# Arguments:
#     uri Original URI
#     newuri New URI after move
#
# Results:
#     Properties file is moved under the properties directory
#     to the relative location for newuri

proc tdav::move_props {uri newuri} {
    set entry [tdav::get_prop_file $uri]
    set dest [tdav::get_prop_file $newuri]
    catch {[file copy -force $entry $dest]}
}

# tdav::copy_props
#
#     Copy properties file for a URI to another URI
#
# Arguments:
#     uri source URI to copy
#     newuri destination URI of copy
#
# Results:
#     Contents of properties file for URI is copied
#     under the properties directory to the relative
#     location corresponding to newuri.

proc tdav::copy_props {uri newuri} {
    set entry [tdav::get_prop_file $uri]
    set dest [tdav::get_prop_file $newuri]
    catch {[file copy -force $entry $dest]}
}

proc tdav::write_lock {uri list} {
    set f [open [tdav::get_lock_file $uri] w]
    puts $f $list
    close $f
}

proc tdav::dbm_read_list {uri} {
    set f [open [tdav::get_prop_file $uri] {CREAT RDONLY}]
    fconfigure $f -encoding utf-8
    set s [read $f]
    close $f
    return $s
}

# tdav::read_lock
#
#     Read lock file for a URI
#
# Arguments:
#     uri URI to retrieve lock
#
# Results:
#     Returns the contents of the lock file. Contents will
#     be evaluated before being returned.

proc tdav::read_lock {uri} {
    set f [open [tdav::get_lock_file $uri] {CREAT RDONLY}]
    set s [read $f]
    set e "list ${s}"
    set l [eval $e]
    close $f

    return $l
}

# tdav::remove_lock
#
#     Delete lock file, effectively also removing the lock
#
# Arguments:
#      uri URI to remove lock from
#
# Results:
#      Lock file for URI is deleted

proc tdav::remove_lock {uri} {
    ns_unlink -nocomplain [tdav::get_lock_file $uri]
}

# tdav::dbm_write_array
#
#     Write array into user properties file
#
# UNUSED

proc tdav::dbm_write_array {uri arr} {
    # extract list from array
    tdav::dbm_write_list($uri,[array get arr])
    # throw errors
}

# tdav::lock_timeout_left
#
# timeout
#    total length of timeout set in seconds
#
# locktime
#    time lock was created in any format clock scan can accept
#

proc tdav::lock_timeout_left { timeout locktime } {
    set locktime [clock scan $locktime]
    set lockexpiretime [clock scan "$timeout seconds" -base $locktime]
    set timeout_left [expr $lockexpiretime - [clock seconds]]
    if {$timeout_left < 0} {
	set timeout_left 0
    }
    return $timeout_left
}

# tdav::check_lock
#
#     Compare existing lock to lock token provided
#     by the client
#
# Arguments:
#     uri URI of request
#
# Results:
#     If the lock token in the Lock-Token header matches
#     an existing lock return "unlocked". Processing of
#     transction from the caller should continure. If
#     the lock doesn't match return "filter_return". Generally
#     this means either no Lock-Token header was provided or
#     the Lock-Token header does not match the existing lock
#     on URI. In this case the caller should return an HTTP
#     status of 423 or otherwise treat the file as locked.

proc tdav::check_lock {uri} {
    regsub {^/} $uri {} uri
    # if lock exists, work.  if not, just return.
    if {[file exists [tdav::get_lock_file $uri]]} {
	  set lockinfo [tdav::read_lock $uri]

	# check if lock is expired
	if {[tdav::lock_timeout_left [lindex $lockinfo 4] [lindex $lockinfo 6]] == 0 } {
	    tdav::remove_lock $uri
	    return "unlocked"
	}
	set hdr [ns_set iget [ns_conn headers] If]
	
	# the If header exists, work, otherwise 423
	
	if {[info exists hdr] && [string length $hdr]} {
	    set token ""
	    # add ? in the token re in case there is a conditional () 
	    # in the header
	    regexp {(<https?://[^/]+([^>]+)>\s+)?\(<([^>]+)>\)} $hdr nil maybe hdr_uri token
	    
	    set ftk [lindex $lockinfo 3]
	    if {![info exists token] || ![string equal $token $ftk]} {
                ns_log Debug "tdav::check_lock: token mismatch $ftk expected hdr: $hdr token: $token"
		ns_return 423 {text/plain} {}
		return filter_return
	    }
	} else {
            ns_log Debug "tdav::check_lock: no \"If\" header found for request of $uri"
	    ns_return 423 {text/plain} {}
	    return filter_return
	}
	# also check for uri == hdr_uri
    }
    return unlocked
}

# tdav::check_lock_for_unlock
#
#     Compare existing lock with client provided lock token.
#
# Arguments:
#     uri URI of the request
#
# Results:
#     If the client provided lock token matches the existing lock the
#     lock is removed and "unlocked" is returned. Otherwise no action
#     is taken on the lock and "filter_return" is returned.

proc tdav::check_lock_for_unlock {uri} {
    regsub {^/} $uri {} uri
    # if lock exists, work.  if not, just return.
    if {[file exists [tdav::get_lock_file $uri]]} {
	set hdr [ns_set iget [ns_conn headers] {Lock-Token}]
	# the If header exists, work, otherwise 423
	if {[info exists hdr] && [string length $hdr]} {
	    regexp {<([^>]+)>} $hdr nil token
	    set ftk [lindex [tdav::read_lock $uri] 3]
	    if {[info exists token] && [string equal $token $ftk]} {
		# it's good, the tokens match.  carry on.
	    } else {
		return filter_return
	    }
	} else {
	    return filter_return
	}
	# also check for uri == hdr_uri
    }
    return unlocked
}


# tdav::get_fs_props
#
#     Generate a list of filesystem properties
#
# Arguments:
#     none
#
# Results:
#     Returns a list of standard DAV properties for
#     the request uri as ns_conn url
#     The list is formatted as
#     {namespace propertyname} value pairs. The results
#     should be evaluated in the caller.

proc tdav::get_fs_props {} {
#    global fs_props
    set fs_props [list]
    
#    lappend fs_props [list ns0 supportlock] {subst {"<none/>"}}
    lappend fs_props [list ns0 getcontenttype] {subst {[ns_guesstype $filename]}}
    lappend fs_props [list D getcontentlength] {subst {[file size $entry]}}
    lappend fs_props [list D creationdate]     {subst {[clock format $file_stat(mtime) -format "%Y-%m-%dT%H:%M:%SZ" -gmt 1]}}
    lappend fs_props [list D getlastmodified]  {subst {[clock format $file_stat(mtime) -format "%a, %d %b %Y %H:%M:%S %Z" -gmt 1]}}
    lappend fs_props [list D getetag]          {subst {"1f9a-400-3948d0f5"}}
    lappend fs_props [list D resourcetype] {if {[file isdirectory $entry]} {
	subst {D:collection}
    } else {
	subst {[ns_guesstype $filename]}
    }}

    return $fs_props
}

# tdav::extract_propertyupdate_remove
#
# I am guessing this should return a list of properties
# to be removed. It isn't used anywhere.
proc tdav::extract_propertyupdate_remove {proplist} {
    # ht
    # ACTION
    foreach c $proplist {
	# extraneous, then name
	set p [[$c childNodes] childNodes]
	set name [$p nodeName]
	# DATA:
	set ht($name) [[$p childNodes] nodeValue]
    }
    return $ht
}

# tdav::extract_propertyupdate_set
#
# I am guessing this should return a list of properties
# to be removed. It isn't used anywhere.
proc tdav::extract_propertyupdate_set {proplist} {
    # ht
    # ACTION
    foreach c $proplist {
	# extraneous, then name
	set p [[$c childNodes] childNodes]
	set name [$p nodeName]
	# DATA:
	set ht($name) [[$p childNodes] nodeValue]
    }
    return $ht
}

# tdav::filter_webdav_proppatch
#
#     Prepare request data for PROPPATCH method
#
# Arguments:
#     none
#
# Results:
#     Parses XML body and puts the formatted result in tdav_conn(prop_req)
#     global variable. Accessed from tdav::conn prop_req command.
#     Sets tdav_conn(depth) from HTTP Depth header

proc tdav::filter_webdav_proppatch {args} {

    set depth [tdav::conn -set depth [ns_set iget [ns_conn headers] Depth]]

    set xml [tdav::read_xml]
    
    if {[catch {dom parse $xml} xd]} {
	# xml body is not well formed
	ns_returnbadrequest
	return filter_return
    }
    
    set setl [$xd getElementsByTagName "*set"]
    set rml [$xd getElementsByTagName "*remove"]
    set prop_req [list]
    foreach node $rml {
	set p [[$node childNodes] childNodes]
	# we use localname because we always resolve the URI namespace
	# for the tag name
	set ns [$p namespaceURI]
	if {[string equal "" $ns]} {
	    set name [$p nodeName]
	} else {
	    set name [$p localName]
	}
	if {[catch {set value [[$p childNodes] nodeValue]}]} {
	    set value ""
	}
	lappend prop_req remove [list [list $ns $name] $value]
    }

    foreach node $setl {
	set p [[$node childNodes] childNodes]
	# we use localname because we always resolve the URI namespace
	# for the tag name
	set ns [$p namespaceURI]
	if {[string equal "" $ns]} {
	    set name [$p nodeName]
	} else {
	    set name [$p localName]
	}
	if {[catch {set value [[$p childNodes] nodeValue]}]} {
	    set value ""
	}
	lappend prop_req set [list [list $ns $name] $value]
    }

    tdav::conn -set prop_req $prop_req

    return filter_ok

}

# tdav::webdav_proppatch
#
#     Handle proppatch method for tDAV filesystem storage
#
# Arguments:
#     none
#
# Results:
#     Attempts to set or unset properties based on the request
#     contained in tdav_conn(prop_req).
#
#     Returns a list containing the HTTP status code and
#     the status of each property set/unset. The status is a list
#     of HTTP status code and text for each property.

proc tdav::webdav_proppatch {} {
    set uri [ns_conn url]
    regsub {^/} $uri {} uri    
    set filename [file join [ns_info pageroot] $uri]
    set body ""
    set ret_code 200
    if {![file exists $filename]} {
	set ret_code 404
    } else {
	if {![string equal unlocked [tdav::check_lock $uri]]} {
	    set ret_code 423
	    set response "The resource is locked"
	} else {
	    set prop_req [tdav::conn prop_req]
	    set response [tdav::update_user_props $uri $prop_req]
	}
	set ret_code 207
    }

    tdav::respond [list $ret_code $response]

}


# tdav::webdav_propfind
#
#     Handle propfind request for tDAV filesystem storage
#
# Arguments:
#     none
#
# Results:
#     Returns a list of HTTP status for the request, and if sucessful a
#     list of properties in the format of
#     {href collection_p {properies_list}}
#     where properties list is a list of pairs
#     {namespace name} value.

proc tdav::webdav_propfind {} {
    set props [list]
    set uri [ns_conn url]
    set depth [tdav::conn depth]
    set prop_req [tdav::conn prop_req]
    regsub {^/} $uri {} uri
    regsub -all -- (\{|\}) $uri \\\\& uri

    # decide on file or directory
    # why doesn't tcl handle this?
    # otoh, it lets us handle the notfound error here    
    # wait, no, this is right as long as the DAV request is correct
    # so fuck it
    if {$depth > 0} {
	set entries [glob -nocomplain [file join [ns_info pageroot] $uri *]]
    } else {
	set entries [glob -nocomplain [file join [ns_info pageroot] $uri]]
    }
    
    foreach entry $entries {
	set entry_props [list]
	set filename [lindex [file split $entry] end]
	# Tcl befuddles me:
	set href [string replace $entry 1 [string length [ns_info pageroot]] ""]
	file stat $entry file_stat
	set collection_p [string equal "directory" $file_stat(type)]

	foreach {i j} [tdav::get_fs_props] {
	    lappend entry_props [list [lindex $i 0] [lindex $i 1]] [eval $j]
	}
	foreach {i j} [tdav::get_user_props $uri $depth $prop_req] {
	    lappend entry_props [list [lindex $i 0] [lindex $i 1]] $j
	}
	
	lappend props [list $href $collection_p $entry_props]
    }
    
    tdav::respond [list 207 $props]
}

# tdav::get_user_props
#
#     Retreive user properties from tDAV filesystem storage
#
# Arguments:
#     uri URI of the request
#     depth valid for collections (directories) can be 0 1 or infinity
#           0 is the directory only
#           1 is the directory and direct descendants
#           infinity is all decendants, this is the default if depth
#           is not specified
#     prop_req should contain a list of name/value pairs of properties
#           to return. Right now it is unsupported and all properties
#           are always returned
#
# Results:
#     returns a list of name/value pairs 

proc tdav::get_user_props { uri depth prop_req } {
    regsub {^/} $uri {} luri
    return [tdav::dbm_read_list $luri] 
}

proc tdav::update_user_props {uri prop_req} {
    array set props [tdav::dbm_read_list $uri]
    set status [list]
    foreach {action i} $prop_req {
	set k [lindex $i 0]
	set value [lindex $i 1]
	switch -- $action {
	    set {
		if {[catch {set props($k) $value} err]} {
		    lappend status [list "HTTP/1.1 409 Conflict" $k]
		} else {
		    lappend status [list "HTTP/1.1 200 OK" $k]
		}

	    }
	    remove {
		#according to WebDAV spec removing a nonexistent
		# property is not an error, if it's there
		# remove it, otherwise, continue.
		if {[info exists props($k)]} {
		    unset props($k)
		}
		lappend status [list "HTTP/1.1 200 OK" $k]
	    }
	}

    #filter out filesystem sets
    # DAVEB where is this filtering occuring?

    #write the props back out to disc:
    tdav::dbm_write_list $uri [array get props]
   }
    return $status
}

# tdav::filter_webdav_propfind
#
#     Prepare incoming PROPFIND request
#
# Arguments:
#     none
#
# Results:
#     sets global values in tdav_conn array for
#     depth, and prop_req
#     prop_req is a list of lists of namespace/name pairs

proc tdav::filter_webdav_propfind {args} {
    set prop_req [list]
    set depth [ns_set iget [ns_conn headers] Depth]
    tdav::conn -set depth $depth

    set body ""
    set ret_code 207

    set xml [tdav::read_xml]
    # test for xml req
    # test for url existence

    regsub {^/} [ns_conn url] {} uri
    set entry [file join [ns_info pageroot] $uri]
    # parse the xml body to check if its valid
    if {![string equal "" $xml] && [catch {dom parse $xml} xd]} {
	ns_return 400 text/plain "XML request not well-formed."
	return filter_return
    }
    
    set xml_prop_list [list]

    if {[info exists xd] && ![string equal "" $xd]} {
	set prop [$xd getElementsByTagNameNS "DAV:" "prop"]
	# if <prop> element doesn't exist we return all properties
	if {![string equal "" $prop]} {
	    set xml_prop_list [$prop childNodes]
	}
	foreach node $xml_prop_list {
	    set ns [$node namespaceURI]
	    if {[string equal $ns ""]} {
		set name [$node nodeName]
	    } else {
		set name [$node localName]
	    }
	    lappend prop_req [list $ns $name]
	}
    }
    tdav::conn -set prop_req $prop_req
    # this should be the end of the filter.
    return filter_ok
}

# tdav::filter_webdav_put
#
#     Prepare incoming PUT request
#
# Arguments:
#     none
#
# Results
#     Copies content to a temporary file and sets tdav_conn(tmpfile)

proc tdav::filter_webdav_put {args} {

    set tmpfile [ns_tmpnam]
    set fd [open $tmpfile w+]
    ns_writecontent $fd
    close $fd

    tdav::conn -set tmpfile $tmpfile

    return filter_ok
}

# tdav::webdav_put
#
#     Handle PUT for tDAV filesystem storage
#
# Arguments:
#     none
#
# Results:
#     If sucessful file is created under AOLserver pageroot
#     that corresponds to the URI of the request.
#     Calls tdav::respond with a list containing HTTP status
#     and response body to return the results to the client.

proc tdav::webdav_put {} {
    set uri [ns_conn url]
    set uri [string trimleft $uri "/"]
    set entry [file join [ns_info pageroot] $uri]
    set filename [lindex [file split $entry] end]
    set tmpfile [tdav::conn tmpfile]
    set ret_code 500
    set body ""
    if {[file exists $entry]} {
	if {![string equal "unlocked" [tdav::check_lock $uri]]} {
	    set ret_code 423
	    set body "Resource is locked."
	} else {
	    file rename -force -- $tmpfile $entry
	    set ret_code 204
	}
    } else {
        file rename -- $tmpfile $entry
	set ret_code 201
    }

    tdav::respond [list $ret_code ""]
    
}

# tdav::filter_webdav_delete
#
#     Prepare incoming DELETE request
#
# Arguments:
#     none
#
# Results:
#     There isn't anything to set so this doesn't do anything
#     right now

proc tdav::filter_webdav_delete {args} {
    # not sure there is anything we need to set here
    return filter_ok
}

# tdav::webdav_delete
#
#    Handle DELETE method for tDAV filesystem storage
#
# Arguments:
#     none
#
# Results:
#     If sucessful file corresponding to URI is removed from
#     the filesystem. In addition properties and lock files
#     are also removed. Calls tdav::respond to return the results
#     to the client.

proc tdav::webdav_delete {} {
    set uri [ns_conn url]
    regsub {^/} $uri {} uri
    set entry [file join [ns_info pageroot] $uri]
    set filename [lindex [file split $entry] end]

    set ret_code 500
    set body ""
    
    if {[file exists $entry]} {
	# 423's and returns:
	if {[string equal unlocked [tdav::check_lock $uri]]} {
	    file delete -force -- $entry
	    ns_unlink -nocomplain $entry
	    tdav::delete_props $uri
	    tdav::remove_lock $uri
	    set ret_code 204
	} else {
	    set ret_code 423
	    set body "Resource is locked."
	}
    } else {
	# file exists will fail on urls created by urlencode.  do a decode here & test
	# ?

	set ret_code 404
    }
    
    tdav::respond [list $ret_code $body]
    
}

# tdav::filter_webdav_mkcol
#
#     Prepares MKCOL request
#
# Arguments:
#     none
#
# Results:
#     This handles the invalid request with
#      a content body. Otherwise it passes on to the
#      registered procedure.

proc tdav::filter_webdav_mkcol {args} {
    if [ns_conn contentlength] {
	set ret_code 415
	set html_response ""
	tdav::respond [list 415]
	return filter_return
    }
    return filter_ok
}

# tdav::webdav_mkcol
#
#     Handles MKCOL method for tDAV filesystem storage
#
# Arguments:
#     none
#
# Results:
#     Creates a directory under the AOLserver pageroot
#     corresponding to the URI. Calls tdav::respond to
#     return the results to the client.

proc tdav::webdav_mkcol {} {
    set uri [ns_conn url]
    regsub {^/} $uri {} uri
    
    set entry [file join [ns_info pageroot] $uri]
    set filename [lindex [file split $entry] end]
    regsub {/[^/]*/*$} $entry {} parent_dir

    if ![file exists $parent_dir] {
	set ret_code 409
    } elseif ![file exists $entry] {
	file mkdir $entry
	file mkdir [file join [ns_info pageroot] "../props/" $uri]
	set ret_code 201
    } else {
	set ret_code 405

    }

    tdav::respond [list $ret_code]
}

# ------------------------------------------------------------

proc tdav::filter_webdav_copy {args} {
    set overwrite [tdav::conn -set overwrite [ns_set iget [ns_conn headers] Overwrite]]
    set destination [encoding convertto utf-8 [ns_urldecode [ns_set iget [ns_conn headers] Destination]]]
    regsub {https?://[^/]+/} $destination {/} dest
    tdav::conn -set destination $dest
    return filter_ok
    
}

proc tdav::webdav_copy {} {
    set overwrite [tdav::conn overwrite]

    set dest [tdav::conn destination]
   
    set local_dest [ns_info pageroot]
    append local_dest $dest
    set newuri [string replace $local_dest 1 [string length [ns_info pageroot]] ""]
    regsub {^/} $newuri {} newuri

    set uri [ns_conn url]
    regsub {^/} $uri {} uri
    
    set entry [file join [ns_info pageroot] $uri]
    set filename [lindex [file split $entry] end]

    regsub {^/} [ns_conn url] {} uri
    set entry [file join [ns_info pageroot] $uri]
    
    if {![file exists $entry]} {
	set ret_code 404
    } else {
	if {[file exists $local_dest]} {
	    if {![string equal "unlocked" [tdav::check_lock $dest]]} {
		#           ns_return 423 {text/plain} {Resource is locked.}
		set ret_code 423
		set body "Resource is locked."
	    } else {
		if [string equal -nocase $overwrite "F"] {
		    set ret_code 412
		} else {
		    set ret_code 204
		    file copy -force $entry $local_dest
		    tdav::copy_props $uri $newuri
		}
	    }
	} else {
	    set ret_code 201
	    file copy $entry $local_dest
	    tdav::copy_props $uri $newuri
	}
    }
    ns_return $ret_code {text/html} {}
    tdav::respond [list $ret_code]
}

# ------------------------------------------------------------

proc tdav::filter_webdav_move {args} {
    set overwrite [tdav::conn -set overwrite [ns_set iget [ns_conn headers] Overwrite]]
    set destination [encoding convertto utf-8 [ns_urldecode [ns_set iget [ns_conn headers] Destination]]]

    regsub {https?://[^/]+/} $destination {/} dest

    tdav::conn -set destination $dest

return filter_ok
}

proc tdav::webdav_move { args } {
    set overwrite [tdav::conn overwrite]
    set dest [tdav::conn destination]
    set uri [ns_conn url]
    set local_dest [ns_info pageroot]
    append local_dest $dest
    set newuri [string replace $local_dest 1 [string length [ns_info pageroot]] ""]
    regsub {^/} $newuri {} newuri

    set uri [ns_conn url]
    regsub {^/} $uri {} uri
    
    set entry [file join [ns_info pageroot] $uri]
    set filename [lindex [file split $entry] end]
    
    set ret_code 500
    set body {}

    if {![file exists $entry]} {
	set ret_code 404
    } else {
	if {![string equal "unlocked" [tdav::check_lock $uri]]} {
#         ns_return 423 {text/plain} {Resource is locked.}
	    set ret_code 423
	    set body "Resource is locked."
	} elseif [file exists $local_dest] {
	    if [string equal -nocase $overwrite "F"] {
		set ret_code 412
	    } else {
		set ret_code 204
		file delete -force $local_dest
		file copy -force $entry $local_dest
		file delete -force $entry
		tdav::copy_props $uri $newuri
		tdav::delete_props $uri
	    }
	} else {
	    set ret_code 201
	    file copy $entry $local_dest
	    tdav::copy_props $uri $newuri
	    file delete -force $entry
	    tdav::delete_props $uri
	}
    }

    ns_return $ret_code {text/html} $body
    return filter_return
}

proc tdav::filter_webdav_lock {args} {
    set ret_code 500
    set body {}

    set xml [tdav::read_xml]
    set d [[dom parse $xml] documentElement]
    set l [$d childNodes]
    set scope [[[lindex $l 0] childNodes] nodeName]
    set type [[[lindex $l 1] childNodes] nodeName]
    if {[catch {set owner [[[lindex $l 2] childNodes] nodeValue]} err]} {
	set owner ""
    }
    set depth [ns_set iget [ns_conn headers] Depth]
    set timeout [ns_set iget [ns_conn headers] Timeout]
    regsub {^Second-} $timeout {} timeout
    tdav::conn -set lock_timeout $timeout
     if {![string length $depth]} {
	set depth 0
    }
    tdav::conn -set depth $depth

    tdav::conn -set lock_scope $scope
    tdav::conn -set lock_type $type
    tdav::conn -set lock_owner $owner
    set lock_token [ns_set iget [ns_conn headers] Lock-Token]
    tdav::conn -set lock_token $lock_token
    return filter_ok
}

proc tdav::set_lock {uri depth type scope owner {timeout ""} {locktime ""} } {
    if {[string equal "" $timeout]} {
	set timeout [ns_config "ns/server/[ns_info server]/tdav" "defaultlocktimeout" "300"]
    }
    if {[string equal "" $locktime]} {
	set locktime [clock format [clock seconds] -format "%T %D"]
    }
    set token "opaquelocktoken:[ns_rand 2147483647]"
    set lock [list $type $scope $owner $token $timeout $depth $locktime]
    tdav::write_lock $uri $lock
    return $token

}

proc tdav::webdav_lock {} {
    set scope [tdav::conn lock_scope]
    set type [tdav::conn lock_type]
    set owner [tdav::conn lock_owner]
    set uri [ns_conn url]
    regsub {^/} $uri {} uri
    set entry [file join [ns_info pageroot] $uri]
    set filename [lindex [file split $entry] end]
    set existing_lock_token [tdav::conn lock_token]
#    if {![file exists $entry]} {
#	set ret_code 404
#    } else
    if {![string equal "unlocked" [tdav::check_lock $uri]]} {
	set ret_code 423
	tdav::respond [list $ret_code]
    } else {
	set depth [tdav::conn depth]
	set timeout [tdav::conn lock_timeout]
	if {[string equal "" $timeout]} {
	    #probably make this a paramter?
	    set timeout 180
	}
	if {![string equal "" $existing_lock_token] && [file exists [tdav::get_lock_file $uri]} {
	    
	    set old_lock [tdav::read_lock $uri]
	    set new_lock [list [lindex $old_lock 0] [lindex $old_lock 1] [lindex $old_lock 2] [lindex $old_lock 3] $timeout [clock format [clock seconds]]]
	    tdav::write_lock $uri $new_lock
	} else {
	    set token [tdav::set_lock $uri $depth $type $scope $owner $timeout [clock format [clock seconds]]]
	}
	set ret_code 200

	tdav::respond [list $ret_code [list depth $depth token $token timeout $timeout owner $owner scope $scope type $type]]
    }
}

proc tdav::filter_webdav_unlock {args} {
    set ret_code 500
    set body {}
    set lock_token [ns_set iget [ns_conn headers] Lock-Token]
    tdav::conn -set lock_token $lock_token

    return filter_ok
}

proc tdav::webdav_unlock {} {
    set uri [ns_conn url]
    regsub {^/} $uri {} uri
    set entry [file join [ns_info pageroot] $uri]
    set filename [lindex [file split $entry] end]

    if {![file exists $entry]} {
	set ret_code 404
	set body {}
    } elseif {![string equal unlocked [tdav::check_lock_for_unlock $uri]]} {
	set ret_code 423
	set body "Resource is locked."
    } else {
	tdav::remove_lock $uri
	set ret_code 204
	set body ""
    }
    tdav::respond [list $ret_code $body]
}

proc tdav::filter_stuff_nsperm {args} {
    # should be something like "Basic 29234k3j49a"
    set a [ns_set get [ns_conn headers] Authorization]
    # get the second bit, the base64 encoded bit
    set up [lindex [split $a " "] 1]
    # after decoding, it should be user:password; get the username
    set user [lindex [split [ns_uudecode $up] ":"] 0]

    return filter_ok
}


proc tdav::return_unauthorized { {realm ""} } {
    ns_set put [ns_conn outputheaders] "WWW-Authenticate" [subst {Basic realm="$realm"}]
    ns_return 401 {text/plain} "Unauthorized\n"
}

# so this will take what's returned and if necessary format an
# XML response body

proc tdav::respond { response } {
    set response_code [lindex $response 0]
    if {[string equal "423" $response_code]} {
	set response_body "The resource is locked"
	set mime_type "text/plain"
    } else {
	set response_list [tdav::respond::[string tolower [ns_conn method]] $response]
	set response_body [lindex $response_list 0]
	set mime_type [lindex $response_list 1]
	if {[string equal "" $mime_type]} {
	    set mime_type "text/plain"
	}
	if {[string match "text/xml*" $mime_type]} {
	    set response_body [encoding convertto utf-8 $response_body]
	}
    }
    ns_log debug "\n ----- tdav litmus headers ----- \n [ns_set iget [ns_conn headers] X-Litmus] \n -----\n"
    ns_log debug "\n  ----- tdav::response response_body ----- \n $response_body \n ----- end ----- \n"
    ns_return $response_code $mime_type $response_body
}

namespace eval tdav::respond {}

proc tdav::respond::delete { response } {
    set body ""
    set mime_type text/plain
    set body [lindex $response 1]
    return [list $body $mime_type]
}

proc tdav::respond::lock { response } {
    array set lock [lindex $response 1]

    set body [subst {<?xml version="1.0" encoding="utf-8"?>
	<prop xmlns="DAV:">
	<lockdiscovery>
	<activelock>
	<locktype><${lock(type)}/></locktype>
	<lockscope><${lock(scope)}/></lockscope>
	<depth>${lock(depth)}</depth>
	<owner>${lock(owner)}</owner><timeout>Second-${lock(timeout)}</timeout>
	<locktoken>
	<href>${lock(token)}</href>
	</locktoken>
	</activelock>
	</lockdiscovery>
	</prop>}]
    
    ns_set put [ns_conn outputheaders] "Lock-Token" "<${lock(token)}>"

    set ret_code 200

    return [list $body text/html]

}

proc tdav::respond::unlock { response } {
    # probably should be doing something here

    set body ""

    return [list $body]
}

proc tdav::respond::put { response } {
    return  $response
}

proc tdav::respond::proppatch { response } {
    set resp_code [lindex $response 0]
    set href ""
    set body [subst {<?xml version="1.0" encoding="utf-8" ?>
	<D:multistatus xmlns:D="DAV:">
	<D:response xmlns:ns0="DAV:">
	<D:href>[ns_conn location]${href}</D:href>
    }]

    foreach res [lindex $response 1] {
	set status [lindex $res 0]
	set ns [lindex [lindex $res 1] 0]
	set name [lindex [lindex $res 1] 1]
	append body [subst {<D:propstat>
	    <D:prop><$name xmlns='$ns'/></D:prop>
	    <D:status>$status</D:status>
	    </D:propstat>
        }]
    }
    append body {</D:response>
	</D:multistatus>}
    return [list $body {text/xml charset="utf-8"}]
}

proc tdav::respond::copy { response } {
    return $response
}

proc tdav::respond::move { response } {
    return $response
}

proc tdav::respond::mkcol { response } {
    set body ""
    switch -- [lindex $response 0] {
	415 {
#	    set body "<!DOCTYPE HTML PUBLIC \"-//IETF//DTD HTML 2.0//EN\">"
	}
	490 {
#	    set body "<!DOCTYPE HTML PUBLIC \"-//IETF//DTD HTML 2.0//EN\">"
	}
	201 {
# 	    set body "<!DOCTYPE HTML PUBLIC \"-//IETF//DTD HTML 2.0//EN\">
# <html><head>
# <title>201 Created</title>
# </head><body>
# <h1>Created</h1>
# <p>Collection [ns_conn url] has been created.</p>
# <hr>
# <address></address>
# 	</body></html>"

	}
	405 {
	    	set body "<!DOCTYPE HTML PUBLIC \"-//IETF//DTD HTML 2.0//EN\">
<html><head>
<title>405 Method Not Allowed</title>
</head><body>
<h1>Method not allowed</h1>
</body></html>"
	}
    }
    return [list $body text/html]
}

proc tdav::respond::propfind { response } {
    # this proc requires that all properties to be returned are in the
    # response lindex 1
    # we don't have to check the tdav fs props or lock properties
    # they should already be there

    set d [dom createDocumentNS "DAV:" "D:multistatus"]
    set n [$d documentElement]
    $n setAttribute "xmlns:b" "urn:uuid:c2f41010-65b3-11d1-a29f-00aa00c14882/"
    set mst_body ""
    foreach res [lindex $response 1] {
	set href [lindex $res 0]
	set props [lindex $res 2]
	set r [$d createElementNS DAV: ns0:response]
	$n appendChild $r
	set h [$d createElement D:href]
        $h appendChild [$d createTextNode ${href}]
	set propstat [$d createElement D:propstat]
	set prop [$d createElement D:prop]
	$r appendChild $h
	$r appendChild $propstat

	foreach {i j} $props {
	    # interestingly enough, adding the namespace here to the prop is fine
	    set name [lindex $i 1]
	    set ns [lindex $i 0]
	    if {![string equal "D" $ns] && ![string equal "ns0" $ns]} {
		# for user properties set the namespace explicitly in
		# the tag
		if {![string equal "" $ns]} {
		    set pnode [$d createElementNS $ns $name]
		} else {
		    set pnode [$d createElement $name]
		}
	    } else {
		set pnode [$d createElement ${ns}:${name}]
	    }

	    if {[string equal "creationdate" $name]} {

		$pnode setAttribute "b:dt" "dateTime.tz"

            }

	    if {[string equal "getlastmodified" $name]} {

		$pnode setAttribute "b:dt" "dateTime.rfc1123"

	    }

            if {[string equal "D:collection" $j]} {
		
		$pnode appendChild [$d createElement $j]

	    } else {
		
		$pnode appendChild [$d createTextNode $j]

	    }

	    $prop appendChild $pnode

	}

	set supportedlock [$d createElement D:supportedlock]	
	
	set lockentry [$d createElement D:lockentry]
	set lockscope [$d createElement D:lockscope]
	set exclusive [$d createElement D:exclusive]
	set locktype [$d createElement D:locktype]
	set write_type [$d createElement D:write]
	
	$supportedlock appendChild $lockentry
	
        $locktype appendChild $write_type
	$lockscope appendChild $exclusive

	$lockentry appendChild $lockscope
	$lockentry appendChild $locktype

	$prop appendChild $supportedlock

	set lockdiscovery [$d createElement D:lockdiscovery]
	regsub {https?://[^/]+/} $href {/} local_uri
	if {[file exists [tdav::get_lock_file $local_uri]]} {
	    # check for timeout
	    set lockinfo [tdav::read_lock $local_uri]
	    set lock_timeout_left [tdav::lock_timeout_left [lindex $lockinfo 4] [lindex $lockinfo 6]]
	    if {$lock_timeout_left > 0} {

		set activelock [$d createElement D:activelock]
		set locktype [$d createElement D:locktype]
		set lockscope [$d createElement D:lockscope]
		set depth [$d createElement D:depth]
		set owner [$d createElement D:owner]
		set timeout [$d createElement D:timeout]
		set locktoken [$d createElement D:locktoken]
		set locktokenhref [$d createElement D:href]
		
		$locktype appendChild [$d createElement D:[lindex $lockinfo 0]]
		$lockscope appendChild [$d createElement D:[lindex $lockinfo 1]]
		$depth appendChild [$d createTextNode [lindex $lockinfo 5]]

		$timeout appendChild [$d createTextNode Second-$lock_timeout_left]
		$owner appendChild [$d createTextNode [lindex $lockinfo 2]]
		$locktokenhref appendChild [$d createTextNode [lindex $lockinfo 3]]
		$locktoken appendChild $locktokenhref

		$activelock appendChild $locktype
		$activelock appendChild $lockscope
		$activelock appendChild $depth
		$activelock appendChild $timeout
		$activelock appendChild $owner
		$activelock appendChild $locktoken

		$lockdiscovery appendChild $activelock
	    }
	}

	$prop appendChild $lockdiscovery
	$propstat appendChild $prop	

	set status [$d createElement D:status]
	set status_text [$d createTextNode "HTTP/1.1 200 OK"]

	$status appendChild $status_text
	$propstat appendChild $status


	}
    

    set body [$d asXML -escapeNonASCII]
    set body "<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n${body}"
    set response [list $body {text/xml charset="utf-8"}]
    return $response
    
}

proc tdav::conn {args} {
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
		return [ns_conn $var]
	    }               
	}
    }
}


proc tdav::apply_filters {{uri "/*"} {options "OPTIONS GET HEAD POST DELETE TRACE PROPFIND PROPPATCH COPY MOVE MKCOL LOCK UNLOCK"} {enable_filesystem "f"}} {

    # Verify that the options are valid options. Webdav requires
    # support for a minimum set of options. And offers support for a
    # limited set of options. (See RFC 2518)

    set required_options [list OPTIONS PROPFIND PROPPATCH MKCOL GET HEAD POST]
    foreach required_option $required_options {
	if {[lsearch -exact [string toupper $options] $required_option] < 0} {
	    ns_log error "Required option $required_option missing from tDAV options for URI '$uri'.
Required web dav options are: '$required_options'."
	    return
	}
    }
    set allowed_options [list OPTIONS COPY DELETE GET HEAD MKCOL MOVE LOCK POST PROPFIND PROPPATCH PUT TRACE UNLOCK]
    foreach option $options {
	if {[lsearch -exact $allowed_options [string toupper $option]] < 0} {
	    ns_log error "Option $option is not an allowed tDAV option for URI '$uri'.
Allowed web dav options are: '$allowed_options'."
	    return
	}
    }    

    # Register filters for selected tDAV options. Do not register a
    # filter for GET, POST or HEAD.

    # change /example/* to /example* to accomodate the
    # url matching for registered filters
    set filter_uri "[string trimright $uri /*]*"
    foreach option $options {
	if {[lsearch -exact [list GET POST HEAD] $option] < 0} {
	    ns_log debug "tDAV registering filter for $filter_uri on $option"
	    ns_register_filter postauth [string toupper $option] "${filter_uri}" tdav::filter_webdav_[string tolower $option]
        }
    }
    ns_log notice "tDAV: Registered filters on $filter_uri"
    
    # Register procedures for selected tDAV options. Do not register a
    # proc for OPTIONS, GET, POST or HEAD.

    if {[string equal "true" $enable_filesystem]} {    
	
	foreach option $options {
	    if {[lsearch -exact [list OPTIONS GET POST HEAD] $option] < 0} {
		ns_log debug "tDAV registering proc for $uri on $option"
		ns_register_proc [string toupper $option] "${uri}" tdav::webdav_[string tolower $option]
	    }
	}
	ns_log notice "tDAV: Registered procedures on $uri"
    } else {
	ns_log notice "tDAV: Filesystem access by WebDAV disabled"
    }
    # Store the tDAV properties in an nsv set so that the registerd
    # filters and procedures don't have to read the config file
    # anymore.

    nsv_set tdav_options $uri $options
}

proc tdav::add_user {user encpass} {
    ns_perm adduser $user $encpass ""
}

proc tdav::setpass {user encpass} {
    ns_perm setpass $user $encpass
}

proc tdav::remove_user {user} {
    # no corresponding ns_perm function.
    # ns_perm setpass 
    # ns_perm denyuser /*
    # might work
}

proc tdav::allow_user {uri user} {
    foreach {share_uri options} [nsv_array get tdav_options] {
	if {[regexp $share_uri $uri]} {
	    foreach option $options {
		ns_perm allowuser [string toupper $option] ${uri} $user
	    }
	    break
	}
    }
}

proc tdav::deny_user {uri user} {
    foreach {share_uri options} [nsv_array get tdav_options] {
	if {[regexp $share_uri $uri]} {
	    foreach option $options {
		ns_perm denyuser [string toupper $option] ${uri} $user
	    }
	    break
	}
    }
}

proc tdav::allow_group {uri group} {
    foreach {share_uri options} [nsv_array get tdav_options] {
	if {[regexp $share_uri $uri]} {
	    foreach option $options {
		ns_perm allowgroup [string toupper $option] ${uri} $group
	    }
	    break
	}
    }
}

proc tdav::deny_group {uri group} {
    foreach {share_uri options} [nsv_array get tdav_options] {
	if {[regexp $share_uri $uri]} {
	    foreach option $options {
		ns_perm denygroup [string toupper $option] ${uri} $group
	    }
	    break
	}
    }
}

# and finally, install all that.

if {![nsv_exists tdav_filters_installed filters_installed]} {
    nsv_set tdav_filters_installed filters_installed 1

    # Uncomment the default user and password for testing.  The
    # application of permissions will be application specific.  To use
    # ns_perm your application will need to fill the ns_perm data
    # every time the server is loaded and when anything changes in a
    # running server. SkipLocks must be set to On in the AOLserver
    # config file and ns_perm module must be loaded.

    # The alternative is to define preauth filters on the WebDAV
    # methods and write your own code to handle authentication. This
    # is how the OpenACS implementation that uses tDAV works.
    
#     ns_perm adduser tdav [ns_crypt tdav salt] userfield
#     ns_perm adduser tdav1 [ns_crypt tdav1 salt] userfield    
#     ns_perm addgroup tdav tdav tdav1

    set tdav_shares [ns_configsection "ns/server/[ns_info server]/tdav/shares"]
    if { ![string equal "" $tdav_shares] } {
        for {set i 0} {$i < [ns_set size $tdav_shares]} {incr i} {
            set tdav_share [ns_configsection "ns/server/[ns_info server]/tdav/share/[ns_set key $tdav_shares $i]"] 
            tdav::apply_filters [ns_set get $tdav_share uri] [ns_set get $tdav_share options] [ns_set get $tdav_share enablefilesystem]
            # uncomment the next line if you are using ns_perm authentication
            # tdav::allow_group [ns_set get $tdav_share uri] tdav
        }
    }
}
