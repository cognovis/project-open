ad_library {

  @author rhs@mit.edu
  @creation-date 2000-09-07
  @cvs-id $Id: site-nodes-init.tcl,v 1.5 2008/10/10 11:30:35 gustafn Exp $

}

nsv_set site_nodes_mutex mutex [ns_mutex create oacs:site_nodes]

site_node::init_cache
