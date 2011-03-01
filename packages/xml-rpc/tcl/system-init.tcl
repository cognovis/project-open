# /packages/xml-rpc/tcl/system-init.tcl
ad_library {
     Register standard system procs
     @author Vinod Kurup [vinod@kurup.com]
     @creation-date Thu Oct  9 22:21:14 2003
     @cvs-id $Id: system-init.tcl,v 1.1 2003/11/26 02:59:13 vinodk Exp $
}

xmlrpc::register_proc system.listMethods
xmlrpc::register_proc system.methodHelp
xmlrpc::register_proc system.multicall
xmlrpc::register_proc system.add
