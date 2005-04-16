# 

ad_library {
    
    procs for wiki style cms
    
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-09-03
    @arch-tag: 407a000b-0f99-4129-ae94-40679a0d4df2
    @cvs-id $Id$
}

namespace eval wiki:: {}

ad_proc -public wiki::get_info {
    ref
} {
    Tries to resolve a wiki reference to
    a URL within OpenACS

    @author Dave Bauer dave@thedesignexperience.org
    @creation-date 2004-09-03

    @param ref Wiki reference to a file/url

    @return id, name, date
} {

    # resolve reference to a package_id/package_key

    # see if package_key::wiki_info exists, if so call it
    # first element is the relative URL of the link
    # second element I have no idea
    # 3rd element is the last modified date. leave empty if the
    # ref doesn't exist yet
    # this sucks we have to hammer the databse for every link
    set package_id [ad_conn package_id]
    set d [db_string get_lm "
	select 
		o.last_modified 
	from 
		acs_objects o, 
		cr_items ci, 
		cr_folders cf 
	where 
		cf.package_id = :package_id 
		and ci.parent_id = cf.folder_id 
		and ci.name = :ref 
		and o.object_id = ci.item_id
    " -default ""]

    set ret [list "${ref}" "${ref}" "$d"]

    ns_log debug "
DB --------------------------------------------------------------------------------
DB DAVE debugging procedure wiki::get_info
DB --------------------------------------------------------------------------------
DB ref = '${ref}'
DB ret = '${ret}'
DB --------------------------------------------------------------------------------"
    return $ret
    
}

ad_proc -public wiki::get_folder_id {
    {-package_id ""}
} {
     Return content repository folder_id for the
     specified wiki package_id.
    
     @author Dave Bauer (dave@thedesignexperience.org)
     @creation-date 2004-09-06
    

     @param package_id If not speicifed use the current package_id from
     ad_conn. It there is no current connection or folder does not
     exist, returns empty string.

     @return 
    
     @error 
} {
    # should really map site_nodes to cr_folders, but I
    # want to see what can be done with stock OpenACS
    if {$package_id == ""} {
       if  {[ad_conn -connected_p]} {
           set package_id [ad_conn package_id]
       } else {
           return ""
       }
    }
    return [db_string get_folder_id \
                "select folder_id from cr_folders where package_id=:package_id" \
                -default ""]
}


# procs for generic wiki::info procedure

# procs to index and for search syndication/rss

# procs for recent changes (use search syndication??)

# attachments/images/uploads?


# TODO figure out where this belongs!
# it needs to integrate with the richtext widget someday

ad_proc -public ad_wiki_text_to_html {
    text
    {info_proc "ad_wiki_info"}
} {
    Converts Wiki formatted text to html
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-09-03
} {
    set stream [Wikit::Format::TextToStream $text]

    # wiki::info will find the parent site node of a reference, and
    # look for a proc called package-key::wiki_info which should
    # return the id, name, modified date of the item
    # (i think id means "url" but I might be wrong!)
    set html [Wikit::Format::StreamToHTML $stream " " $info_proc]
    return [lindex $html 0]
}

ad_proc -public ad_wiki_info {
    ref
} {
    Tries to resolve a wiki reference to
    a URL within OpenACS

    @author Dave Bauer dave@thedesignexperience.org
    @creation-date 2004-09-03

    @param ref Wiki reference to a file/url

    @return id, name, date
} {

    # resolve reference to a package_id/package_key

    # see if package_key::wiki_info exists, if so call it
    # first element is the relative URL of the link
    # second element I have no idea
    # 3rd element is the last modified date. leave empty if the
    # ref doesn't exist yet
    
    set ret [list "${ref}" "${ref}" "1"]
#    ns_log debug "
#DB --------------------------------------------------------------------------------
#DB DAVE debugging procedure wiki::ad_wiki_info
#DB --------------------------------------------------------------------------------
#DB ref = '${ref}'
#DB ret = '${ret}'
#DB --------------------------------------------------------------------------------"
    return $ret
    
}
