ad_page_contract {

    Show all objects mapped to a category.

    @author Timo Hentschel (timo@timohentschel.de)
    @cvs-id $Id:
} {
    category_id:integer
    tree_id:integer
    {locale ""}
    object_id:integer,optional
    {page:integer,optional 1}
    {orderby:optional object_name}
} -properties {
    page_title:onevalue
    context_bar:onevalue
    locale:onevalue
    url_vars:onevalue
    object_count:onevalue
    page_count:onevalue
    page:onevalue
    orderby:onevalue
    items:onevalue
    info:onerow
    pages:onerow
}

set user_id [auth::require_login]
array set tree [category_tree::get_data $tree_id $locale]
if {$tree(site_wide_p) == "f"} {
    permission::require_permission -object_id $tree_id -privilege category_tree_read
}

set tree_name [category_tree::get_name $tree_id $locale]
set category_name [category::get_name $category_id $locale]
set page_title "Objects using category \"$category_name\" of tree \"$tree_name\""
set url_vars [export_vars -no_empty {category_id tree_id locale object_id}]

set context_bar [category::context_bar $tree_id $locale [value_if_exists object_id]]
lappend context_bar "\"$category_name\" Usage"

set table_def {
    {object_name "Object Name" {upper(n.object_name) $order} {<td><a href="/o/$object_id">$object_name</a></td>}}
    {instance_name "Package" {} {<td align=right><a href="/o/$package_id">$instance_name</a></td>}}
    {package_type "Package Type" {} r}
    {creation_date "Creation Date" {} r}
}

set order_by_clause [ad_order_by_from_sort_spec $orderby $table_def]

set p_name "category-usage"
request create
request set_param page -datatype integer -value 1

# execute query to count objects and pages
paginator create get_category_usages $p_name "" -pagesize 20 -groupsize 10 -contextual -timeout 0

set first_row [paginator get_row $p_name $page]
set last_row [paginator get_row_last $p_name $page]

# execute query to get the objects on current page
set items [ad_table -Torderby $orderby get_objects_using_category "" $table_def]

paginator get_display_info $p_name info $page
set group [paginator get_group $p_name $page]
paginator get_context $p_name pages [paginator get_pages $p_name $group]
paginator get_context $p_name groups [paginator get_groups $p_name $group 10]

set object_count [paginator get_row_count $p_name]
set page_count [paginator get_page_count $p_name]

ad_return_template
