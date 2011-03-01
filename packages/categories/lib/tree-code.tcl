set default_locale [lang::system::site_wide_locale]

array set tree [category_tree::get_data $tree_id $default_locale]

multirow create categories name level pad
foreach category [category_tree::get_tree -all $tree_id $default_locale] {
    util_unlist $category category_id category_name deprecated_p level
    multirow append categories $category_name $level [string repeat "&nbsp;" [expr {2 * $level - 2}]]
}
