# /admin/monitoring/configuration/index.tcl

ad_page_contract { 
    Displays some basic information about this installation of AOLServer:
    IP Address, System Name, and System Owner.

    @cvs-id $Id: index.tcl,v 1.1.1.2 2006/08/24 14:41:42 alessandrol Exp $
} {
}

set title "System Configuration"
set context [list "$title"]


set whole_page "
<h2>[ad_system_name] Configuration</h2>

<ul>
<li>IP Address: [ns_conn peeraddr]
<li>System Name: [ad_system_name]
<li>System Owner: <a href=mailto:[ad_system_owner]>[ad_system_name]</a>
</ul>

"
