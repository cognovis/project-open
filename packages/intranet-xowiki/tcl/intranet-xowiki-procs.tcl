# intranet-xowiki-procs.tcl
ad_library {
    Procedures to support intranet-xowiki package

    @author Iuri Sampaio (iuri.sampaio@gmail.com)
    @creation-date 2011-04-18
}

namespace eval intranet_xowiki {}

# ----------------------------------------------------------------------
# Xowiki View Component
# ---------------------------------------------------------------------
ad_proc -public im_xowiki_view_component {
    {-object_id:required}
    {-return_url ""}
} {

    @author iuri sampaio (iuri.sampaio@gmail.com)
    @creation-date 2011-04-18
} {

    set project_id $object_id
    set project_name [db_exec_plsql select_project_name "select im_name_from_id($object_id)"]

    # Get the XoWIKI Parent installation
    set xowiki_node_id [db_string select_xowiki_instance {
	SELECT sn.node_id FROM apm_packages ap, site_nodes sn WHERE ap.package_key= 'xowiki' AND ap.package_id = sn.object_id and sn.name = 'xowiki'
    } -default 0]
    
    if {[exists_and_not_null xowiki_node_id]} {
	set project_wiki_node_id [db_string wiki_instance "SELECT sn.node_id FROM apm_packages ap, site_nodes sn WHERE ap.package_key= 'xowiki' AND ap.package_id = sn.object_id and sn.name = '$project_id'" -default ""]

	ds_comment "$project_id ::: $project_wiki_node_id"
	if {$project_wiki_node_id eq ""} {
	    site_node::instantiate_and_mount -parent_node_id $xowiki_node_id \
		-node_name $project_id -package_key "xowiki" \
		-package_name "XoWIKI $project_name"

	    set project_wiki_package_id [db_string wiki_instance "SELECT ap.package_id FROM apm_packages ap, site_nodes sn WHERE ap.package_key= 'xowiki' AND ap.package_id = sn.object_id and sn.name = '$project_id'" -default ""]

	    # index page doesn't exist in this point of time. This code will never work here
	    #set PackageClass [::xo::PackageMgr get_package_class_from_package_key "xowiki"]
	    #set Package [$PackageClass initialize -url "/xowiki/$project_id"]
	    #set folder_id [$Package folder_id]
	    #set package_id [$Package id]
	    #ds_comment "folder $folder_id"
	    #::xowiki::Package import_prototype_page -package_key "intranet-xowiki" -name "index" -parent_id $folder_id -package_id $package_id

	    
	    #set item_name "xowiki: $project_wiki_package_id"
	    
	    #set revision_id [db_string revision id {
	#	select live_revision from cr_items where parent_id = (select item_id from cr_items where name = :item_name) and name = 'en:index';
	 #   }]

	  #  db_dml update_revision "update cr_revisions set content = '{{recent -max_entries 25}}' where revision_id = :revision_id"



	   
	    
#	    db_1row select_item_id {
#		SELECT item_id as page_item_id FROM cr_items WHERE parent_id = ( SELECT item_id FROM cr_items WHERE name = :item_name) AND name = 'en:index'
#	    }    
#	    content::revision::new -item_id $page_item_id -content "{{recent -max_entries 25}}" -is_live "t"

	    # Set Instance parameter
	    parameter::set_value -package_id $project_wiki_package_id -parameter "template_file" -value "oacs-view"
	    parameter::set_value -package_id $project_wiki_package_id -parameter "top_includelet" -value ""
	    
	    # Map Tree
	    set tree_id [category_tree::get_id "Projects Tree"]
	    ns_log Notice "TREE ID $tree_id"
	    set tree_maped_p [db_0or1row tree_maped_p { 
		SELECT tree_id FROM category_tree_map WHERE object_id = :project_wiki_package_id AND tree_id = :tree_id 
	    }]
	    
	    ns_log Notice "MAPPED TREE $tree_maped_p"
	    if {[exists_and_not_null tree_maped_p]} { 
		category_tree::map -tree_id $tree_id -object_id $project_wiki_package_id
	    }
	   
	} else {
	    set project_wiki_package_id [db_string wiki_instance "SELECT ap.package_id FROM apm_packages ap, site_nodes sn WHERE ap.package_key= 'xowiki' AND ap.package_id = sn.object_id and sn.name = '$project_id'" -default ""]  

	    set item_name "xowiki: $project_wiki_package_id"
	    
	    set revision_id [db_string revision_id {
		select item_id from cr_items where parent_id = (select item_id from cr_items where name = :item_name) and name = 'en:index';
	    } -default ""]
	    if {$revision_id ne ""} {
		ns_log Notice "REVISION $revision_id"
		content::revision::new -item_id $revision_id -content "{{recent -max_entries 25}}" -is_live "t"

		set PackageClass [::xo::PackageMgr get_package_class_from_package_key "xowiki"]
		set Package [$PackageClass initialize -url "/xowiki/$project_id"]
		set folder_id [$Package folder_id]
		set package_id [$Package id]
		ds_comment "folder $folder_id"
		::xowiki::Package import_prototype_page -package_key "intranet-xowiki" -name "index" -parent_id $folder_id -package_id $package_id
	    }


	}

#	ad_return_template "/xowiki/?import_prototype_page=/packages/intranet-xowiki/www/prototype/index.page"

#	::xowki::Package import_prototype_page -package_key "intranet-xowiki" -name "index" -parent_id (folder of the XoWIKI instance...)

        set params [list [list url "/xowiki/$project_id"] [list project_id $object_id] [list package_id $project_wiki_package_id] [list return_url $return_url]]

	set result [ad_parse_template -params $params "/packages/intranet-xowiki/lib/page"]
	return [string trim $result]
    }
}