# /packages/intranet-xmlrpc/tcl/intranet-xmlrpc-init.tcl
ad_library {
     Register intranet-xmlrpc  procs
     @author Frank Bergmann (frank.bergmann@project-open.com)
}

xmlrpc::register_proc sqlapi.login

