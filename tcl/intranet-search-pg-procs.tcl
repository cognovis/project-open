# /packages/intranet-forum/tcl/intranet-forum.tcl
#
# Copyright (C) 2003-2004 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    This procs implements support for ftscontentprovider to intranet-core/projects
    TODO:
    	Add support to filestorage
	Much more!
	
    @author pepels@gmail.com
}



ad_proc -public projects__datasource{
    object_id
} {
    @author pepels@gmail.com
} {
    db_0or1row projects_datasource{
	select p.project_id as object_id, 
	       p.project_name as title, 
	       p.description as content,
	       'text/plain' as mime,
	       '' as keywords,
	       'text' as storage_type
	from im_projects p
	where project_id = :object_id
    } -column_array datasource

    return [array get datasource]
}


ad_proc -public projects__url {
    object_id
} {
    @author pepels@gmail.com
} {

    set package_id [apm_package_id_from_key intranet-core]
    db_1row get_url_stub "
        select site_node__url(node_id) as url_stub
        from site_nodes
        where object_id=:package_id
    "

    set url "${url_stub}projects/view?project_id=$object_id"
    return $url
}

