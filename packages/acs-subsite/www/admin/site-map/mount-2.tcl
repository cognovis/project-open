# packages/acs-core-ui/www/admin/site-nodes/mount-2.tcl

ad_page_contract {

  @author rhs@mit.edu
  @creation-date 2000-09-12
  @cvs-id $Id: mount-2.tcl,v 1.2 2010/10/19 20:12:36 po34demo Exp $
} {
  node_id:integer,notnull
  package_id:integer,notnull
  {expand:integer,multiple {}}
  root_id:integer,optional
}

ad_require_permission $package_id read

site_node::mount -node_id $node_id -object_id $package_id

ad_returnredirect ".?[export_url_vars expand:multiple root_id]"
