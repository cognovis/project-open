ad_page_contract {

    Multi-dimensional browsing of selected category trees.
    Shows a list of all objects mapped to selected categories
    using ad_table, ad_dimensional and paginator.

    @author Timo Hentschel (timo@timohentschel.de)
    @cvs-id $Id:
} {
    tree_ids:integer,multiple
    {category_ids:integer,multiple,optional ""}
    {page:integer,optional 1}
    {orderby:optional object_name}
    {subtree_p:optional f}
    {letter:optional all}
    {join:optional or}
    package_id:optional
} -properties {
    page_title:onevalue
    context_bar:onevalue
    trees:multirow
    url_vars:onevalue
    form_vars:onevalue
    object_count:onevalue
    page_count:onevalue
    page:onevalue
    orderby:onevalue
    items:onevalue
    dimension_bar:onevalue
    info:onerow
    pages:onerow
}

set user_id [auth::require_login]

set page_title "Browse categories"

set context_bar [list "Browse categories"]
set url_vars [export_url_vars tree_ids:multiple category_ids:multiple subtree_p letter join package_id]
set form_vars [export_form_vars tree_ids:multiple orderby subtree_p letter package_id]

db_transaction {
    # use temporary table to use only bind vars in queries
    foreach tree_id $tree_ids {
	db_dml insert_tmp_category_trees ""
    }
    set tree_ids [db_list check_permissions_on_trees ""]
}
db_dml delete_tmp_category_trees ""

template::multirow create trees tree_id tree_name category_id category_name indent selected_p
template::util::list_to_lookup $category_ids category_selected

# get tree structures and names from the cache
foreach tree_id $tree_ids {
    set tree_name [category_tree::get_name $tree_id]
    foreach category [category_tree::get_tree $tree_id] {
	util_unlist $category category_id category_name deprecated_p level
	set indent ""
	if {$level>1} {
	    set indent "[string repeat "&nbsp;" [expr {2*$level -4}]].."
	}
	template::multirow append trees $tree_id $tree_name $category_id $category_name $indent [info exists category_selected($category_id)]
    }
}

set table_def {
    {object_name "Object Name" {upper(n.object_name) $order} {<td><a href="/o/$object_id">$object_name</a></td>}}
    {instance_name "Package" {} {<td align=right><a href="/o/$package_id">$instance_name</a></td>}}
    {package_type "Package Type" {} r}
    {creation_date "Creation Date" {} r}
}

set order_by_clause [ad_order_by_from_sort_spec $orderby $table_def]

set dimensional_def {
    {subtree_p "Categorization" f {
	{f "Exact"}
	{t "Include Subcategories"}
    }}
    {letter "Name" all {{A "A"} {B "B"} {C "C"} {D "D"} {E "E"} {F "F"} {G "G"} {H "H"} {I "I"} {J "J"} {K "K"} {L "L"} {M "M"} {N "N"} {O "O"} {P "P"} {Q "Q"} {R "R"} {S "S"} {T "T"} {U "U"} {V "V"} {W "W"} {X "X"} {Y "Y"} {Z "Z"} {other "Other"} {all "All"}
    }}
}

set form [ns_getform]
ns_set delkey $form page
ns_set delkey $form button
set dimension_bar [ad_dimensional $dimensional_def categories-browse $form]

# generate sql for selecting object names beginning with selected letter
switch -exact $letter {
    other {
	set letter_sql [db_map other_letter]
    }
    all {
	set letter_sql ""
    }
    default {
	set bind_letter "$letter%"
	set letter_sql [db_map regular_letter]
    }
}

if {[info exists package_id]} {
    set package_sql [db_map package_objects]
} else {
    set package_sql ""
}

set category_ids_length [llength $category_ids]
if {$join eq "and"} {
    # combining categories with and
    if {$subtree_p eq "t"} {
	# generate sql for exact categorizations plus subcategories
	set subtree_sql [db_map include_subtree_and]
    } else {
	# generate sql for exact categorization
	set subtree_sql [db_map exact_categorization_and]
    }
} else {
    # combining categories with or
    if {$subtree_p eq "t"} {
	# generate sql for exact categorizations plus subcategories
	set subtree_sql [db_map include_subtree_or]
    } else {
	# generate sql for exact categorization
	set subtree_sql [db_map exact_categorization_or]
    }
}

set p_name "browse_categories"
request create
request set_param page -datatype integer -value 1

db_transaction {
    # use temporary table to use only bind vars in queries
    foreach category_id $category_ids {
	db_dml insert_tmp_categories ""
    }

    # execute query to count objects and pages
    paginator create get_categorized_object_count $p_name "" -pagesize 20 -groupsize 10 -contextual -timeout 0

    set first_row [paginator get_row $p_name $page]
    set last_row [paginator get_row_last $p_name $page]

    # execute query to get the objects on current page
    set items [ad_table -Torderby $orderby get_categorized_objects "" $table_def]
}
db_dml delete_tmp_category_trees ""

paginator get_display_info $p_name info $page
set group [paginator get_group $p_name $page]
paginator get_context $p_name pages [paginator get_pages $p_name $group]
paginator get_context $p_name groups [paginator get_groups $p_name $group 10]

set object_count [paginator get_row_count $p_name]
set page_count [paginator get_page_count $p_name]

ad_return_template
