ad_page_contract {
    
    This entry page for different object in ACS that
    need to manage which categories that can be mapped
    to contained objects. 

    @author Timo Hentschel (timo@timohentschel.de)
    @cvs-id $Id:
} {
    object_id:integer,notnull
    ctx_id:integer,optional
    {locale ""}
} -properties {
    page_title:onevalue
    context:onevalue
    locale:onevalue
    mapped_trees:multirow
    unmapped_trees:multirow
    object_name:onevalue
}

set user_id [auth::require_login]
permission::require_permission -object_id $object_id -privilege admin

set context_bar [category::get_object_context $object_id]
set object_name [lindex $context_bar 1]
set page_title [_ categories.cadmin]
set context_bar [list $context_bar $page_title]

template::multirow create mapped_trees tree_name tree_id \
    site_wide_p assign_single_p require_category_p widget view_url unmap_url edit_url

db_foreach get_mapped_trees "" {
    set tree_name [category_tree::get_name $tree_id $locale]
    if {$subtree_category_id ne ""} {
      append tree_name " :: [category::get_name $subtree_category_id $locale]"
    }
    template::multirow append mapped_trees $tree_name $tree_id $site_wide_p \
	$assign_single_p $require_category_p $widget \
	[export_vars -no_empty -base tree-view { tree_id locale object_id ctx_id}] \
	[export_vars -no_empty -base tree-unmap { tree_id locale object_id ctx_id}] \
	[export_vars -no_empty -base tree-map-2 { tree_id locale object_id {edit_p 1} ctx_id}]
}

template::multirow sort mapped_trees -dictionary tree_name

template::multirow create unmapped_trees tree_id tree_name site_wide_p view_url map_url subtree_url

db_foreach get_unmapped_trees "" {
    if { $has_read_permission == "t" || $site_wide_p == "t" } {
	set tree_name [category_tree::get_name $tree_id $locale]

	template::multirow append unmapped_trees $tree_id $tree_name $site_wide_p \
	[export_vars -no_empty -base tree-view { tree_id locale object_id ctx_id}] \
	[export_vars -no_empty -base tree-map-2 { tree_id locale object_id ctx_id}] \
	[export_vars -no_empty -base tree-map { tree_id locale object_id ctx_id}]
    }
}

template::multirow sort unmapped_trees -dictionary tree_name

template::list::create \
    -name mapped_trees \
    -no_data "None" \
    -elements {
	tree_name {
	    label "Name"
	    link_url_col view_url
	}
        flags {
	    display_template {
		(<if @mapped_trees.site_wide_p@ eq t>Site-Wide Tree, </if>
                 <if @mapped_trees.widget@>@mapped_trees.widget@, </if>
		 <if @mapped_trees.assign_single_p@ eq t>single, </if><else>multiple, </else>
		 <if @mapped_trees.require_category_p@ eq t>required) </if><else>optional) </else>
	    }
	}
	action {
	    label "Action"
	    display_template {
		<a href="@mapped_trees.unmap_url@">Unmap</a> &nbsp; &nbsp;
		<a href="@mapped_trees.edit_url@">Edit parameters</a>
	    }
	}
    }

template::list::create \
    -name unmapped_trees \
    -no_data "None" \
    -elements {
	tree_name {
	    label "Name"
	    link_url_col view_url
	}
	site_wide_p {
	    display_template {
		<if @unmapped_trees.site_wide_p@ eq t> (Site-Wide Tree) </if>
	    }
	}
	action {
	    label "Action"
	    display_template {
		<a href="@unmapped_trees.map_url@">Map tree</a> &nbsp; &nbsp;
		<a href="@unmapped_trees.subtree_url@">Map a subtree</a>
	    }
	}
    }

set create_url [export_vars -no_empty -base tree-form { locale object_id ctx_id }]

ad_return_template
