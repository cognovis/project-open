# /packages/intranet-search-pg/tcl/intranet-search-pg-procs.tcl
#
# Copyright (C) 1998-2004 various parties
# The code is based on ArsDigita ACS 3.4
#
# This program is free software. You can redistribute it
# and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option)
# any later version. This program is distributed in the
# hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.

ad_library {
    Procedures for tsearch full text enginge driver

    @author Dave Bauer (dave@thedesignexperience.org)
    @author frank.bergmann@project-open.com
    @creation-date 2004-06-05
    @arch-tag: 49a5102d-7c06-4245-8b8d-15a3b12a8cc5
    @cvs-id $Id: intranet-search-pg-procs.tcl,v 1.6 2006/04/07 23:07:40 cvs Exp $

}


ad_proc -public im_package_search_id { } {
    Returns the ID of the current package. Please
    not that there is no "_pg" in the procedure name.
    This is in order to keep the rest of the system
    identical, no matter whether it's a PostgreSQL
    TSearch2 implementation of search or an Oracle
    Intermedia implementation.
} {
    return [db_string im_package_search_id {
        select package_id from apm_packages
        where package_key = 'intranet-search-pg'
    } -default 0]
}


ad_proc -public im_tsvector_to_headline { 
    tsvector
} {
    Converts a tsvector (or better: its string representation)
    into a text string, obviously without the stop words.

    Example: 'frank':3 'bergmann':4 'www.project-open.com':2
          => "www.project-open.com frank bergmann"

    @author Frank Bergmann (frank.bergmann@project-open.com)
    @creation-date 2005-01-05
} {
    set word ""
    set counters ""
    set result ""
    set ts_list [split $tsvector "'"]

    set ctr 0
    set maxpos 0
    foreach token $ts_list {
	set token [string trim $token]

	if {1 == [expr $ctr % 2]} {
	    set word $token
	} else {
	    set token [string range $token 1 end]
	    set positions [split $token ","]

	    foreach pos $positions {
		set res($pos) $word
		
		if {$pos > $maxpos} { set maxpos $pos }
	    }
	}
	incr ctr
    }

    set last_i 0
    for {set i 0} {$i <= $maxpos} {incr i} {
	if {[info exists res($i)]} {
	    append result $res($i)
	    append result " "
	    set last_id $i
	}
	if {1 == [expr $i - $last_i]} {
	    append result ".. "
	}
    }

    return $result
}


namespace eval tsearch2 {}

ad_proc -public tsearch2::index {
    object_id
    txt
    title
    keywords
} {
    add object to full text index

    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-06-05

    @param object_id
    @param txt
    @param title
    @param keywords

    @return nothing
} {
    set index_exists_p [db_0or1row object_exists "select 1 from txt where object_id=:object_id"]
    if {!$index_exists_p} {
	db_dml index "
            insert into txt (object_id,fti)
            values ( :object_id,
                     setweight(to_tsvector('default',coalesce(:title,'')),'A')
                   ||setweight(to_tsvector('default',coalesce(:keywords,'')),'B')
                   ||to_tsvector('default',coalesce(:txt,'')))"
    } else {
	tsearch2::update_index $object_id $txt $title $keywords
    }
}

ad_proc -public tsearch2::unindex {
    object_id
} {
    Remove item from FTS index

    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-06-05

    @param object_id

    @return nothing
} {
    db_dml unindex "delete from txt where object_id=:object_id"
}

ad_proc -public tsearch2::update_index {
    object_id
    txt
    title
    keywords
} {
    update full text index

    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-06-05

    @param object_id
    @param txt
    @param title
    @param keywords

    @return nothing
} {
    set index_exists_p [db_0or1row object_exists "select 1 from txt where object_id=:object_id"]
    if {!$index_exists_p} {
	tsearch2::index $object_id $txt $title $keywords
    } else {
	db_dml update_index "
            update txt set fti =
                     setweight(to_tsvector('default',coalesce(:title,'')),'A')
                   ||setweight(to_tsvector('default',coalesce(:keywords,'')),'B')
                   ||to_tsvector('default',coalesce(:txt,''))
            where object_id=:object_id
        "
    }
}

ad_proc -public tsearch2::search {
    query
    offset
    limit
    user_id
    df
    dt
} {
    
    ftsenginedriver search operation implementation for tsearch2
    
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-06-05

    @param query

    @param offset

    @param limit

    @param user_id

    @param df

    @param dt

    @return

    @error
} {
    # clean up query
    # turn and into &
    # turn or into |
    # turn not into !
    set query [tsearch2::build_query -query $query]

    set limit_clause ""
    set offset_clause ""

    if {[string is integer $limit]} {
	set limit_clause " limit :limit "
    }
    if {[string is integer $offset]} {
	set offset_clause " offset :offset "
    }
    set query_text "select object_id from txt where fti @@ to_tsquery('default',:query) and exists (select 1
                   from acs_object_party_privilege_map m
                   where m.object_id = txt.object_id
                     and m.party_id = :user_id
                     and m.privilege = 'read') order by rank(fti,to_tsquery('default',:query)) desc  ${limit_clause} ${offset_clause}"
    set results_ids [db_list search $query_text]
    set count [db_string count "select count(*) from txt where fti @@ to_tsquery('default',:query)  and exists
                  (select 1 from acs_object_party_privilege_map m
                   where m.object_id = txt.object_id
                     and m.party_id = :user_id
                     and m.privilege = 'read')"]
    set stop_words [list]
    # lovely the search package requires count to be returned but the
    # service contract definition doesn't specify it!
    return [list ids $results_ids stopwords $stop_words count $count]
}

ad_proc -public tsearch2::summary {
    query
    txt
} {
    Highlights matching terms.

    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-06-05

    @param query

    @param txt

    @return summary containing search query terms

    @error
} {
    set query [tsearch2::build_query -query $query]
   return [db_string summary "select headline('default',:txt,to_tsquery('default',:query))"]
}

ad_proc -public tsearch2::driver_info {
} {
   
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-06-05
    
    @return 
    
    @error 
} {
    return [list package_key tsearch2-driver version 2 automatic_and_queries_p 0  stopwords_p 1]
}

ad_proc tsearch2::build_query { -query } {
    Convert conjunctions to query characters for tsearch2
    and => &
    not => !
    or => |
    space => | (or)
    
    @param string string to convert
    @return returns formatted query string for tsearch2 tsquery
} {
    # get rid of everything that isn't a letter or number
    regsub -all {[^-/@.\d\w\s]+} $query { } query

    # replace boolean words with boolean operators
    set query [string map {" and " & " or " | " not " " ! "} " $query "]
    # remove leading and trailing spaces so they aren't turned into |
    set query [string trim $query]
    # remove any spaces between words and operators
    regsub -all {\s*([!&|])\s+} $query {\1} query
    # all remaining spaces between words turn into |
    regsub -all {\s+} $query {\&} query
    # if a ! is by itself then prepend &
    regsub {(\w)([!])} $query {\1\&!} query

    return $query
}

