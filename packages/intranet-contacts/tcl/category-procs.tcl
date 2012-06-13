ad_library {

  Support procs for the categorys in the contacts package

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-07-28
    @cvs-id $Id$

}


namespace eval contacts::categories:: {


    ad_proc -public enabled_p {
    } {
        returns 1 if categories are enabled or 0 if not
    } {
        if { [empty_string_p [category_tree::get_mapped_trees [ad_conn package_id]]] } {
            return 0
        } else {
            return 1
        }
    }


    ad_proc -public get_selects {
        {-export_vars ""}
        {-category_id ""}
    } {
    } {
    # this is borrowed from project-manager but will be re-written


    # Categories are arranged into category trees. 
    # Set up an array for each tree. The array contains the category for each tree
        set package_id [ad_conn package_id]
    
    set category_select ""
    set number_of_categories 0
    set last_tree ""
    set category_select ""

    db_foreach get_categories {} {

        if {![string equal $tree_name $last_tree] } {
            append category_select "<option value=\"\">** $tree_name **</option>"
        }

        if {[string equal $cat_id $category_id]} {
            set select "selected"
        } else {
            set select ""
        }

        append category_select "<option $select value=\"$cat_id\">$cat_name</option>"

        set last_tree $tree_name
        incr number_of_categories
    }

    if {$number_of_categories < 1} {
        return ""
    }

    set return_val "<form method=\"post\" action=\"index\">$export_vars
<select name=\"category_id\"><option value=\"\">--All Categories--</option>$category_select"

    append return_val "</select><input type=\"submit\" value=\"Go\" /></form>"
    
    return $return_val
}

}

