# /Users/matthewburke/development/web/bitdojo/packages/categories/tcl/tagcloud-procs.tcl
ad_library {
     
     Procs to generate a tag cloud for a given category tree.

     @author Matthew Burke (matt-oacs@bluedino.net)
     @creation-date Sun Oct  2 16:58:34 2005
     @cvs-id
}


namespace eval category::tagcloud {}


ad_proc -private category::tagcloud::get_minmax_tagweights {
    -tag_list:required
} {
    Returns a list with the minimum and maximum weight values in the given list.

    @author Matthew Burke (matt-oacs@bluedino.net)
} {
    set max_weight 0
    set min_weight [lindex [lindex $tag_list 0] 1]
    foreach tag $tag_list {
        set tag_weight [lindex $tag 1]
        if {$tag_weight < $min_weight} {
            set min_weight $tag_weight
        }
        if {$tag_weight > $max_weight} {
            set max_weight $tag_weight
        }
    }
    return [list $min_weight $max_weight]
}


ad_proc -private category::tagcloud::scale_weight {
    -weight:required
    -extremes:required
} {
    Returns the weight as a font-size between 10px and 36px scaled between
    the min and max weights passed in.

    @author Matthew Burke (matt-oacs@bluedino.net)
} {
    set denominator [expr {[lindex $extremes 1] - [lindex $extremes 0]}]
    if {$denominator != 0} {
        set multiplier [expr ($weight * 1.0)/$denominator]
    } else {
        set multiplier 0
    }
    set result [expr {10 + round($multiplier*(36-10))}]
    return $result
}


ad_proc -public category::tagcloud::tagcloud {
    -tree_id:required
} {
    Generate a tag cloud for the categories in the given category
    tree.

    @option tree_id tree_id of the tree fro which to generate the cloud.
    @return HTML fragment for the tag cloud.
    @author Matthew Burke (matt-oacs@bluedino.net)
} {
    set html_fragment "<div class=\"tagcloud\">\n"
    set tag_list [category::tagcloud::get_tags -tree_id $tree_id]

    # now build the frag
    set weights [category::tagcloud::get_minmax_tagweights -tag_list $tag_list]

    # and what if category package isn't mounted at /category?

    foreach tag $tag_list {
        append html_fragment "<a href=\"/categories/categories-browse?tree_ids=$tree_id&category_ids=[lindex $tag 0]\" style=\"font-size: [category::tagcloud::scale_weight -weight [lindex $tag 1] -extremes $weights]px;\" class=\"tag\">[lindex $tag 2]</a>\n"
    }
    append html_fragment "</div>"

    return $html_fragment
}


ad_proc -private category::tagcloud::get_tags_no_mem {
    -tree_id:required
} {
    Returns a list of categories and their weights (number of objects mapped
    to each category) for a give category tree.

    @author Matthew Burke (matt-oacs@bluedino.net)
    @creation-date  Oct 1, 2005

} {

    set user_locale [ad_conn locale]
    set user_id [ad_conn user_id]
    set default_locale [parameter::get -parameter DefaultLocale -default en_US]
    ns_log Warning "def loc $default_locale"

    # this whole locale thing isn't handled well.
    # categories get inserted in the site's default_locale and
    # the category creator's locale (?)

    # so we should check for the reader's locale and use that
    # or the default_locale, but ...

    set tag_list [db_list_of_lists tagcloud_get_keys {
        select category_id, count(com.object_id), min(trans.name)
        from categories natural left join category_object_map com natural join category_trees
        natural join category_translations trans
        where tree_id = :tree_id and trans.locale = :default_locale
	and exists (select 1 from acs_object_party_privilege_map ppm
                    where ppm.object_id = com.object_id
                    and ppm.privilege = 'read'
                    and ppm.party_id = :user_id)
        group by category_id
    }]
}



ad_proc -public category::tagcloud::get_tags {
    -tree_id:required
} {
    Returns a list of categories and their weights (number of objects mapped
    to each category) for a give category tree.

    This is a memoized function which caches for two hours.

    @author Matthew Burke (matt-oacs@bluedino.net)
    @creation-date  Oct 1, 2005
    @see category::tagcloud::get_tags_no_mem

} {
    return [util_memoize [list category::tagcloud::get_tags_no_mem -tree_id $tree_id] 7200]
}



