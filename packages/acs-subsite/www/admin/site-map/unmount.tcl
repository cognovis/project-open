# packages/acs-core-ui/www/admin/site-nodes/unmount.tcl

ad_page_contract {

    @author rhs@mit.edu
    @creation-date 2000-09-12
    @cvs-id $Id: unmount.tcl,v 1.2 2010/10/19 20:12:37 po34demo Exp $

} {
    node_id:integer,notnull
    {expand:integer,multiple ""}
    root_id:integer,optional
}

site_node::unmount -node_id $node_id

ad_returnredirect ".?[export_url_vars expand:multiple root_id]"
