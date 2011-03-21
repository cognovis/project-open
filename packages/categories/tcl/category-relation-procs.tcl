ad_library {
    Procedures to relate to categories trees (meta category) to one user_id

    @author Miguel Marin (miguelmarin@viaro.net)
    @author Viaro Networks www.viaro.net
    @creation-date  2005-07-26
}

namespace eval category::relation {}


ad_proc -public category::relation::add_meta_category {
    -category_id_one:required
    -category_id_two:required
    {-user_id ""}
} {
    Creates a new meta category by creating a realtion between category_id_one 
    and category_id_two. This relation is also related to the user_id.

    @option user_id user that will be related to the meta category.
    @option category_id_one one of the two category_id's to be related.
    @option category_id_two the other category_id to be related.
    @author Miguel Marin (miguelmarin@viaro.net)
    @author Viaro Networks www.viaro.net
} {
    if { $user_id eq "" } {
	set user_id [ad_conn user_id]
    }
 
    # First we check if the relation exist, if it does, we don't create a new one
    set meta_category_id [db_string get_meta_relation_id {} -default ""]
    if { $meta_category_id eq "" } { 
	set meta_category_id [db_exec_plsql add_meta_relation {}]
    }
    
    # Now we check if the user already has the meta category associated,
    # if it does, we don't create a new one
    set user_meta_category_id [db_string get_user_meta_relation_id {} -default ""]
    if { $user_meta_category_id eq "" } { 
	return [db_exec_plsql add_user_meta_relation {}]
    } else {
	return $user_meta_category_id
    }
}

ad_proc -public category::relation::get_widget {
    -tree_id_one:required
    -tree_id_two:required
} {
    Returns two select menus of the categories on each tree to be used in ad_form. The name of the elements
    are meta_category_one and meta_category_two.
    

    @option tree_id_one 
    @option tree_id_two
    @author Miguel Marin (miguelmarin@viaro.net)
    @author Viaro Networks www.viaro.net
} {
    set label_one [category_tree::get_name $tree_id_one]
    set label_two [category_tree::get_name $tree_id_two]
    set element_one  "\{meta_category_one:integer(select) \{label $label_one\} \{options \{ "
    set element_two  "\{meta_category_two:integer(select) \{label $label_two\} \{options \{ "
   
    foreach category_one [category_tree::get_tree $tree_id_one] {
	set value_one [lindex $category_one 0]
	set label_one [lindex $category_one 1]
	append element_one "\{$label_one $value_one\} "
    }
    foreach category_two [category_tree::get_tree $tree_id_two] {
	set value_two [lindex $category_two 0]
	set label_two [lindex $category_two 1]
	append element_two "\{$label_two $value_two\} "
    }
    append element_one "\} \} \}"
    append element_two "\} \} \}"

    return "$element_one  $element_two"
}

ad_proc -public category::relation::get_meta_categories {
    -rel_id:required
} {
    return cached list of category_one and category_two of the meta-category
} {
    return [util_memoize [list category::relation::get_meta_category_internal -rel_id $rel_id]]
}

ad_proc -private category::relation::get_meta_category_internal {
    -rel_id:required
} {
    get list of category_one and category_two of the meta-category
} {
    db_1row get_categories {}
    return [list $object_id_one $object_id_two]
}
