# /packages/intranet-xmlrpc/tcl/intranet-xmlrpc-init.tcl
ad_library {
     Register intranet-xmlrpc  procs
     @author Frank Bergmann (frank.bergmann@project-open.com)
}

xmlrpc::register_proc sqlapi.login
xmlrpc::register_proc sqlapi.select
xmlrpc::register_proc sqlapi.object_info
xmlrpc::register_proc sqlapi.object_types
xmlrpc::register_proc sqlapi.object_fields
