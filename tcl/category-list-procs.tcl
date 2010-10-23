ad_library {
    Procs for the integration in listbuilder of the site-wide categorization package.

    Please note: This is highly experimental and is subject to ongoing development
                 so the interfaces might be unstable.

    @author Timo Hentschel (timo@timohentschel.de)

    @creation-date 17 February 2004
    @cvs-id $Id$
}

namespace eval category::list {}

ad_proc -public category::list::collapse_multirow {
    {-category_column "category_id"}
    -object_column:required
    -name:required
} {
    Takes a multirow, collapses it so that for each object there's the tcl-list of mapped
    categories in the category multirow column.

    @param object_column multirow column name that holds the object_id of the categorized object.
    @param category_column multirow column name that holds the category_id and will later
           hold the tcl-list of category_ids
    @param name name of the multirow
    @author Timo Hentschel (timo@timohentschel.de)
    @see category::list::prepare_display
    @see category::list::elements
    @see category::list::get_pretty_list
} {
    upvar 1 ${name}:rowcount rowcount
    if {$rowcount == 0} {
	return
    }

    set rownum 1
    set counter 1
    set category_list ""
    upvar 1 ${name}:1 cur_row

    while {$counter <= $rowcount} {
        upvar 1 ${name}:$counter row
	set row_id $row($object_column)
	set category_id $row($category_column)

	if {$category_id ne ""} {
	    lappend category_list $category_id
	}

	incr counter
	if {$counter <= $rowcount} {
	    upvar 1 ${name}:$counter next_row
	    set next_row_id $next_row($object_column)
	    if {$row_id != $next_row_id} {
		set cur_row($category_column) $category_list
		set category_list ""
		incr rownum
		upvar 1 ${name}:$rownum cur_row
		array set cur_row [array get next_row]
		set cur_row(rownum) $rownum
	    }
	} else {
	    set cur_row($category_column) $category_list
	}
    }

    for {set counter [expr {$rownum+1}]} {$counter < $rowcount} {incr counter} {
        uplevel 1 unset ${name}:$counter
    }
    set rowcount $rownum
}


ad_proc -public category::list::get_pretty_list {
    {-category_delimiter ", "}
    {-category_link ""}
    {-category_link_eval ""}
    {-category_link_html ""}
    {-remove_link ""}
    {-remove_link_eval ""}
    {-remove_link_text ""}
    {-tree_delimiter "; "}
    {-tree_colon ": "}
    {-tree_link ""}
    {-tree_link_eval ""}
    {-tree_link_html ""}
    {-category_varname "__category_id"}
    {-tree_varname "__tree_id"}
    {-uplevel 1}
    category_id_list
    {locale ""}
} {
    Accepts a list of category_ids and returns a pretty list of tree-names and
    category-names with optional links for each tree and category.

    @param category_delimiter string that seperates the categories in the pretty list
    @param category_link optional link for every category-name
    @param category_link_eval optional command that returns the link for every category-name.
                              normaly this would be a export_vars command that could
                              contain __category_id and __tree_id which refer to
                              category_id and tree_id of the category-name the link will wrap.
    @param category_link_html optional list of key value pairs for additional html in a link.
    @param tree_delimiter string that seperates the tree-names in the pretty list
    @param tree_colon string that seperates a tree-name from the category-names in that tree.
    @param tree_link optional link for every tree-name
    @param tree_link_eval optional command that returns the link for every tree-name.
                          normaly this would be a export_vars command that could
                          contain __tree_id which refer to tree_id of the tree-name
                          the link will wrap.
    @param tree_link_html optional list of key value pairs for additional html in a link.
    @param category_varname name of the variable that will hold the category_id for
                            category link generation.
    @param tree_varname name of the variable that will hold the tree_id for category
                        and tree link generation.
    @param uplevel upvar level to set __tree_id and __category_id for link generation.
    @param category_id_list tcl-list of categories to display.
    @param locale locale of the category-names and tree-names.
    @return pretty list of tree-names and category-names
    @author Timo Hentschel (timo@timohentschel.de)
    @see category::list::collapse_multirow
    @see category::list::prepare_display
    @see category::list::elements
} {
    if {$category_link_eval ne ""} {
	upvar $uplevel $category_varname category_id $tree_varname tree_id
    } elseif {$tree_link_eval ne ""} {
	upvar $uplevel $tree_varname tree_id
    }

    set sorted_categories [list]
    foreach category_id $category_id_list {
	lappend sorted_categories [category::get_data $category_id $locale]
    }
    set sorted_categories [lsort -dictionary -index 3 [lsort -dictionary -index 1 $sorted_categories]]

    set cat_link_html ""
    foreach {key value} $category_link_html {
	append cat_link_html " $key=\"$value\""
    }
    set cat_tree_link_html ""
    foreach {key value} $tree_link_html {
	append cat_tree_link_html " $key=\"$value\""
    }

    set result ""
    set old_tree_id 0
    foreach category $sorted_categories {
	util_unlist $category category_id category_name tree_id tree_name

	set category_name [ad_quotehtml $category_name]
	if {$category_link_eval ne ""} {
	    set category_link [uplevel $uplevel concat $category_link_eval]
	}

	if {$remove_link_eval ne ""} {
	    set remove_link [uplevel $uplevel concat $remove_link_eval]
	}
	if {$category_link ne ""} {
	    set category_name "<a href=\"$category_link\"$cat_link_html>$category_name</a>"
	}
        if {$remove_link ne ""} { 
            append category_name "&nbsp;<a href=\"$remove_link\" title=\"Remove this category\">$remove_link_text</a>"
        }

	if {$tree_id != $old_tree_id} {
	    if {$result ne ""} {
		append result $tree_delimiter
	    }
	    set tree_name [ad_quotehtml $tree_name]
	    if {$tree_link_eval ne ""} {
		set tree_link [uplevel $uplevel concat $tree_link_eval]
	    }
	    if {$tree_link ne ""} {
		set tree_name "<a href=\"$tree_link\"$cat_tree_link_html>$tree_name</a>"
	    }
	    append result "$tree_name$tree_colon$category_name"
	} else {
	    append result "$category_delimiter$category_name"
	}
	set old_tree_id $tree_id
    }

    return $result
}

ad_proc -public category::list::prepare_display {
    {-category_delimiter ", "}
    {-category_link ""}
    {-category_link_eval ""}
    {-category_link_html ""}
    {-tree_delimiter "; "}
    {-tree_colon ": "}
    {-tree_link ""}
    {-tree_link_eval ""}
    {-tree_link_html ""}
    {-category_varname "__category_id"}
    {-tree_varname "__tree_id"}
    {-category_column "category_id"}
    {-categories_column "categories"}
    {-tree_ids ""}
    {-exclude_tree_ids ""}
    {-container_object_id ""}
    {-locale ""}
    -one_category_list:boolean
    -name:required
} {
    Extends a given multirow with either one extra column holding a pretty list
    of the tree-names and category-names or one column per tree holding a pretty
    list of category-names. These extra column can then be used in the listbuilder
    to display a pretty list of categorized objects.

    @param category_delimiter string that seperates the categories in the pretty list
    @param category_link optional link for every category-name
    @param category_link_eval optional command that returns the link for every category-name.
                              normaly this would be a export_vars command that could
                              contain __category_id and __tree_id which refer to
                              category_id and tree_id of the category-name the link will wrap.
    @param category_link_html optional list of key value pairs for additional html in a link.
    @param tree_delimiter string that seperates the tree-names in the pretty list
    @param tree_colon string that seperates a tree-name from the category-names in that tree.
    @param tree_link optional link for every tree-name
    @param tree_link_eval optional command that returns the link for every tree-name.
                          normaly this would be a export_vars command that could
                          contain __tree_id which refer to tree_id of the tree-name
                          the link will wrap.
    @param tree_link_html optional list of key value pairs for additional html in a link.
    @param category_varname name of the variable that will hold the category_id for
                            category link generation.
    @param tree_varname name of the variable that will hold the tree_id for category
                        and tree link generation.
    @param category_column name of the column in the multirow holding the tcl-list
                           of mapped categories.
    @param categories_column beginning of the names of the multirow columns holding the
                             category names.
    @param tree_ids tcl-list of trees that should be displayed.
    @param exclude_tree_ids tcl-list of trees that should not be displayed.
    @param container_object_id object the trees are mapped to (instead of providing tree_ids).
    @param locale locale of the category-names and tree-names.
    @param one_category_list switch to generate only one additional column in the multirow
                             that holds a pretty list of tree-names and category-names.
    @param name name of the multirow to extend.
    @author Timo Hentschel (timo@timohentschel.de)
    @see category::list::collapse_multirow
    @see category::list::elements
    @see category::list::get_pretty_list
} {
    if {$category_link_eval ne ""} {
	upvar 1 $category_varname category_id $tree_varname tree_id
    } elseif {$tree_link_eval ne ""} {
	upvar 1 $tree_varname tree_id
    }

    set cat_link_html ""
    foreach {key value} $category_link_html {
	append cat_link_html " $key=\"$value\""
    }
    set cat_tree_link_html ""
    foreach {key value} $tree_link_html {
	append cat_tree_link_html " $key=\"$value\""
    }

    # get trees to display
    if {$tree_ids eq ""} {
	foreach mapped_tree [category_tree::get_mapped_trees $container_object_id] {
	    lappend tree_ids [lindex $mapped_tree 0]
	}
    }
    set valid_tree_ids ""
    foreach tree_id $tree_ids {
	if {[lsearch -integer $exclude_tree_ids $tree_id] == -1} {
	    lappend valid_tree_ids $tree_id
	}
    }

    template::multirow upvar $name list_data
    # check for existing multirow
    if {![info exists list_data:rowcount] || ![info exists list_data:columns]} { 
        return 
    } 

    if {!$one_category_list_p} {
	# extend multirow with a variable per tree
	foreach tree_id $valid_tree_ids {
	    uplevel 1 template::multirow extend $name $categories_column\_$tree_id
	}

	# loop over multirow
	for {set i 1} {$i <= ${list_data:rowcount}} {incr i} {

	    upvar 1 $name:$i row
	    if {$category_link_eval ne ""} {
		foreach column_name ${list_data:columns} {
		    upvar 1 $column_name column_value
		    if { [info exists row($column_name)] } {
			set column_value $row($column_name)
		    } else {
			set column_value ""
		    }
		}
	    }

	    # get categories per tree
	    foreach tree_id $valid_tree_ids {
		set tree_categories($tree_id) ""
	    }
	    foreach category_id $row($category_column) {
		set tree_id [category::get_tree $category_id]
		if {[lsearch -integer $valid_tree_ids $tree_id] > -1} {
		    lappend tree_categories($tree_id) [list $category_id [category::get_name $category_id $locale]]
		}
	    }

	    # generate pretty category list per tree
	    foreach tree_id [array names tree_categories] {
		set tree_categories($tree_id) [lsort -dictionary -index 1 $tree_categories($tree_id)]
		set pretty_category_list ""

		foreach category $tree_categories($tree_id) {
		    util_unlist $category category_id category_name
		    set category_name [ad_quotehtml $category_name]
		    if {$category_link_eval ne ""} {
			set category_link [uplevel 1 concat $category_link_eval]
		    }
		    if {$category_link ne ""} {
			set category_name "<a href=\"$category_link\"$cat_link_html>$category_name</a>"
		    }
		    if {$pretty_category_list ne ""} {
			append pretty_category_list "$category_delimiter$category_name"
		    } else {
			set pretty_category_list $category_name
		    }
		}
		
		# set multirow columns with pretty category lists
		set row($categories_column\_$tree_id) $pretty_category_list
	    }
	    unset tree_categories
	}

	############
    } else {
	############

	# extend multirow with one variable for pretty list of trees and categories
	template::multirow extend list_data $categories_column\_all

	# loop over multirow
	for {set i 1} {$i <= ${list_data:rowcount}} {incr i} {

	    upvar 1 $name:$i row
	    if {$category_link_eval ne ""} {
		foreach column_name ${list_data:columns} {
		    upvar 1 $column_name column_value
		    if { [info exists row($column_name)] } {
			set column_value $row($column_name)
		    } else {
			set column_value ""
		    }
		}
	    }

	    # get categories of given trees
	    set valid_categories ""
	    foreach category_id $row($category_column) {
		set tree_id [category::get_tree $category_id]
		if {[lsearch -integer $valid_tree_ids $tree_id] > -1} {
		    lappend valid_categories $category_id
		}
	    }

	    # set multirow column with pretty list of trees and categories
	    set row($categories_column\_all) [category::list::get_pretty_list \
						   -category_delimiter $category_delimiter \
						   -category_link $category_link \
						   -category_link_eval $category_link_eval \
						   -category_link_html $category_link_html \
						   -tree_delimiter $tree_delimiter \
						   -tree_colon $tree_colon \
						   -tree_link $tree_link \
						   -tree_link_eval $tree_link_eval \
						   -tree_link_html $tree_link_html \
						   -category_varname $category_varname \
						   -tree_varname $tree_varname \
						   -uplevel 2 $valid_categories $locale]
	}
    }
}

ad_proc -public category::list::elements {
    {-categories_column "categories"}
    {-tree_ids ""}
    {-locale ""}
    -one_category_list:boolean
    -name:required
    {spec ""}
} {
    Adds list-elements to display mapped categories. To be used in list::create.

    <p>
 <b>Scenario:</b><br>you prepare a multirow which is then displated via template::list::create
 <p>
 <b>Usage:</b><br>
        you change the list query by adding an outer join to <i>category_object_map</i>
        and selecting the object_id and the category_id.
        After having built the multirow holding the list of objects you add a call to
<pre>
    category::list::collapse_multirow -object_column &lt;&lt;columnname-holding-object_id&gt;&gt; -name &lt;&lt;multirowname&gt;&gt;</i>
</pre>
        to collapse the multirow so that it holds only one row per object with a
        tcl-list of mapped categories in the category column.
<p>
        After you got the multirow, use
<pre>
    category::list::prepare_display -name &lt;&lt;multirowname&gt;&gt; -container_object_id $package_id
</pre>
        (or an object other than package_id that the trees are mapped to).
        This proc will generate one extra multirow column per mapped tree that
        will hold a pretty list of the categories. The pretty list can be changed
        with various options (delimiter, links etc).
        If you want to have only one extra multirow column holding a pretty list
        of the mapped trees and categories, then you should use the -one_category_list
        option.
<p>
        To automatically generate the appropriate input to be used in the elements
        section of template::list::create, use 
<pre>
    category::list::elements -name &lt;&lt;multirowname&gt;&gt;
</pre>
        followed by extra spec to be used per element. Again, to display only one
        column use the -one_category_list option.

    @param categories_column beginning of the names of the multirow columns holding
                             the category-names.
    @param tree_ids trees to be displayed. if not provided all tree columns in the
                    multirow will be displayed.
    @param locale locale to display the tree-names in columns.
    @param one_category_list switch to generate only one additional column in the list
                             that holds a pretty list of tree-names and category-names.
    @param name name of the multirow for the list.
    @param spec extra spec used for the list-elements. you can override the display_template
                with using "categories" as column holding the pretty list of category-names.
    @author Timo Hentschel (timo@timohentschel.de)
    @see template::list::create
    @see template::list::element::create
    @see category::list::collapse_multirow
    @see category::list::prepare_display
    @see category::list::get_pretty_list
} {
    array set spec_array $spec
    if {[info exists spec_array(display_template)]} {
	set display_template $spec_array(display_template)
	array unset spec_array display_template
    } else {
	set display_template " @$name\.$categories_column;noquote@ "
    }
    if {[info exists spec_array(label)]} {
	set label $spec_array(label)
	array unset spec_array label
    } else {
	set label "Categories"
    }
    set spec [array get spec_array]

    if {$one_category_list_p} {
	# generate listbuilder input to display one column with pretty list
	# of tree-names and category-names
	set result "$categories_column\_all {
	    label \"$label\"
	    display_template {[regsub -all "@$name\.$categories_column\(;noquote\)?@" $display_template "@$name\.$categories_column\_all\\1@"]}
	    $spec
	}"
	return $result
    } else {
	if {$tree_ids eq ""} {
	    # get tree columns in multirow
	    template::multirow upvar $name list_data
	    foreach column ${list_data:columns} {
		if {[regexp "$categories_column\_(\[0-9\]+)\$" $column match tree_id]} {
		    lappend tree_ids $tree_id
		}
	    }
	    foreach tree_id $tree_ids {
		lappend trees [list [category_tree::get_name $tree_id $locale] $tree_id]
	    }
	    set trees [lsort -dictionary -index 0 $trees]
	} else {
	    foreach tree_id $tree_ids {
		lappend trees [list [category_tree::get_name $tree_id $locale] $tree_id]
	    }
	}

	# generate listbuilder input to display one column per tree-name showing
	# pretty list of category-names
	set result ""
	foreach tree $trees {
	    util_unlist $tree tree_name tree_id
	    append result "$categories_column\_$tree_id {
		label \"$tree_name\"
		display_template {[regsub -all "@$name\.$categories_column\(;noquote\)?@" $display_template "@$name\.$categories_column\_$tree_id\\1@"]}
		$spec
	    }\n"
	}
	return $result
    }
}

ad_proc -public category::list::rewrite_query {
    -object_column:required
    {-category_column "category_id"}
    {-dbn "" }
    sql
} {
    Takes a sql-query and adds an outer join to category_object_map

    @param object_column column name that holds the object_id of the categorized object.
    @param category_column column name of the mapped category_id.
    @param sql sql-query to be rewritten
    @author Timo Hentschel (timo@timohentschel.de)
    @see category::list::collapse_multirow
    @see category::list::prepare_display
    @see category::list::elements
    @see category::list::get_pretty_list
} {
    set driverkey [db_driverkey $dbn]
    switch $driverkey {
	oracle {
	    set new_sql "select s.*, m.category_id as $category_column
		from ($sql) s, category_object_map m
		where s.$object_column = m.object_id(+)
		order by s.$object_column"
	}
	postgresql {
	    set new_sql "select s.*, m.category_id as $category_column
		from ($sql) s left outer join category_object_map m
		on (s.$object_column = m.object_id)
		order by s.$object_column"
	}
    }
    return $new_sql
}
