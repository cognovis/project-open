#
# author: Timo Hentschel (timo@timohentschel.de)
#

if {![info exists object_id]} {
    set object_id 0
}
if {![info exists package_id]} {
    set package_id [ad_conn package_id]
}
if {![info exists name]} {
    set name category_ids
}

template::multirow create trees tree_id tree_name category_id selected_p category_name indent assign_single_p require_category_p

template::util::list_to_lookup [category::get_mapped_categories $object_id] mapped

foreach tree [category_tree::get_mapped_trees $package_id] {
    util_unlist $tree tree_id tree_name subtree_id assign_single_p require_category_p
    set one_tree [list]
    foreach category [category_tree::get_tree -subtree_id $subtree_id $tree_id] {
	util_unlist $category category_id category_name deprecated_p level
	set indent ""
	if {$level>1} {
	    set indent "[string repeat "&nbsp;" [expr {2*$level -4}]].."
	}
	set selected_p [info exists mapped($category_id)]

	template::multirow append trees $tree_id $tree_name $category_id $selected_p $category_name $indent $assign_single_p $require_category_p
    }
}
