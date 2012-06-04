ad_library {
    Procs for the integration in ad_form of the site-wide categorization package.

    @author Branimir Dolicki (bdolicki@branimir.com)

    @creation-date 06 February 2004
    @cvs-id $Id$
}

namespace eval category::ad_form {}

ad_proc -public category::ad_form::add_widgets {
    {-container_object_id:required}
    {-categorized_object_id}
    {-form_name:required}
    {-element_name "category_id"}
    {-excluded_trees {}}
    {-help_text {}}
} {
    For each category tree associated with this container_object_id (usually
    package_id) put a category widget into the ad_form.  On form submission the
    procedure category::ad_form::get_categories should be called to collect
    the categories in which this object belongs.

    @author Branimir Dolicki (bdolicki@branimir.com)
} {
    set category_trees [category_tree::get_mapped_trees $container_object_id]
    
    foreach tree $category_trees {
	util_unlist $tree tree_id name subtree_id assign_single_p require_category_p widget
        if {[lsearch -exact $excluded_trees $tree_id] > -1} { 
            continue
        } 
	set options ""
	if {$assign_single_p == "f"} {
	    set options ",multiple"
	}
	if {$require_category_p == "f"} {
	    append options ",optional"
	}
        ad_form -extend -name $form_name -form \
            [list [list __category__ad_form__$element_name\_${tree_id}:category$options \
                       {label $name} \
                       {category_tree_id $tree_id} \
                       {category_subtree_id $subtree_id} \
                       {category_object_id {[value_if_exists categorized_object_id]}} \
		       {category_assign_single_p $assign_single_p} \
		       {category_require_category_p $require_category_p} \
                       {category_widget $widget} \
                       {help_text $help_text} \
                      ]]
        
    }
}

ad_proc -public category::ad_form::get_categories {
    {-container_object_id:required}
    {-element_name "category_id"}
} {

    Collects categories from the category widget in the format compatible with
    category::add_ad_form_elements.  To be used in the -on_submit clause of
    ad_form.

    @author Branimir Dolicki (bdolicki@branimir.com)
} {
    set category_trees [category_tree::get_mapped_trees $container_object_id]
    set category_ids [list]
    foreach tree $category_trees {
	util_unlist $tree tree_id name subtree_id assign_single_p require_category_p widget
        upvar #[template::adp_level] \
          __category__ad_form__$element_name\_${tree_id} my_category_ids
        if {[info exists my_category_ids]} { 
            eval lappend category_ids $my_category_ids
        } else { 
            ns_log Warning "category::ad_form::get_categories: __category__ad_form__$element_name\_${tree_id} for tree $tree_id not found"
        }
    }
    return $category_ids
}
