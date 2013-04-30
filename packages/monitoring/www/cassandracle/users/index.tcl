# /admin/monitoring/cassandracle/users/one-user-constraints.tcl

ad_page_contract {
    Displays what we want to know for a database user:
    info about a session, info about ownership, space usage
    @cvs-id $Id: index.tcl,v 1.1.1.2 2006/08/24 14:41:41 alessandrol Exp $
} {
}

doc_return 200 text/html "

[ad_header "Users"]

<h2>Users</h2>

[ad_context_bar [list "[ad_conn package_url]/cassandracle" "Cassandracle"] "Users"]

<hr>

<ul>
<li><a href=\"sessions-info\">Who is connected and what query did they last run?</a>

<li><a href=\"user-owned-objects\">Who owns which objects?</a>
<li><a href=\"user-owned-constraints\">Who owns which constraints?</a>

<p>

<li><a href=\"concurrent-active-users\">From an Oracle license point of view, 
how many users on the system now and how does this compare to the limits?</a>

</ul>
[ad_admin_footer]
"
