ad_page_contract {
    This include expects "message" to be set as html
    and if no title is present uses "Message".  Used to inform of actions
    in registration etc.

    @cvs-id $Id$
}
if {![exists_and_not_null title]} {
    set page_title Message
}
set context [list $title]
