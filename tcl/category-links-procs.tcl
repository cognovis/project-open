ad_library {
    category-links procs for the site-wide categorization package.

    @author Timo Hentschel (timo@timohentschel.de)

    @creation-date 04 February 2004
    @cvs-id $Id$
}

namespace eval category_link {}

ad_proc -public category_link::add {
    {-from_category_id:required}
    {-to_category_id:required}
} {
    Insert a new category link.

    @option from_category_id category_id the links comes from.
    @option to_category_id category_id the link goes to.
    @return link_id
    @author Timo Hentschel (timo@timohentschel.de)
} {
    db_transaction {
	set link_id [db_exec_plsql insert_category_link ""]
    }
    return $link_id
}

ad_proc -public category_link::delete { link_id } {
    Deletes a category link.

    @param link_id category link to be deleted.
    @author Timo Hentschel (timo@timohentschel.de)
} {
    db_exec_plsql delete_category_link ""
}
