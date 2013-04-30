# /www/admin/monitoring/cassandracle/index.tcl

ad_page_contract {

    Stepping stone to the individual Oracle status queries

    @author Jin Choi (jsc@arsdigita.com)
    @cvs-id $Id: index.tcl,v 1.1.1.2 2006/08/24 14:41:40 alessandrol Exp $

} { }

set errno [catch { db_string count_start "select count(*) from v\$parameter"}]

if { $errno != 0 } {
    ad_return_error "Cassandracle not configured" "Cassandracle is not configured for this database user. <p> To configure cassandracle:
<ul>
<li> Log into Oracle via sqlplus
<li> connect internal;
<li> @ [acs_package_root_dir monitoring]/sql/cassandracle.sql
<li> grant ad_cassandracle to  [ns_config  "ns/db/pool/main" User][ns_config  "ns/db/pool/pool1" User];
<li> restart-aolserver [ns_info server]
</ul>"
    return
}

doc_return 200 text/html "
[ad_header "Cassandracle"]

<h2>Cassandracle</h2>

[ad_context_bar "Cassandracle"]

<hr>

<ul>

<h4>by question</h4>

<li><a href=\"./oracle-settings\">What are the initialization parameters?</a>
<li><a href=\"tablespaces/space-usage\">How full are my tablespaces?</a>
<li><a href=\"users/hit-ratio\">Are any users becoming pigs?</a>
<li><a href=\"performance/pct-large-table-scans\">Are any queries becoming pigs?</a>
<li>Are any tables becoming pigs?
<li><a href=\"users/sessions-info\">Who is connected to the DB, and what can you tell me about their sessions?</a>
<li><a href=\"performance/data-block-waits\">Are there any performance bottlenecks in the DB?</a>
<li><a href=\"objects/list-all-functions-and-procedures\">What PL/SQL procedures and functions are defined?</a>
<li><a href=\"users/user-owned-objects\">What objects are defined?</a>

<h4>by object</h4>

<li><a href=\"users/\">Users</a>
<li><a href=\"tablespaces/space-usage\">Tablespaces</a>
</ul>
[ad_admin_footer]
"
