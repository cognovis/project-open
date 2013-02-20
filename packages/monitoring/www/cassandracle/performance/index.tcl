ad_page_contract {
    Displays options for monitoring database performance.

    @cvs-id $Id: index.tcl,v 1.1.1.2 2006/08/24 14:41:40 alessandrol Exp $
} {
}

doc_return 200 text/html "
[ad_header "Performance"]

<h2>Performance</h2>

[ad_context_bar [list "[ad_conn package_url]/cassandracle" "Cassandracle"] "Performance"]

<hr>

<ul>
<li><a href=\"pct-large-table-scans\">Large Table Scans</a>

<li><a href=\"data-block-waits\">Data Block Waits</a>

</ul>

[ad_admin_footer]
"
