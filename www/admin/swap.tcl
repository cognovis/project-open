#/faq/www/admin/swap.tcl

ad_page_contract {
    Swaps a faq entry with the following entry

    @author Elizabeth Wirth (wirth@ybos.net)
    @author Jennie Housman (jennie@ybos.net)
    @creation-date 2000-10-26

    taken largely from acs 3.4 faq/swap.tcl
   
} {
    entry_id:integer,notnull
    faq_id:integer,notnull
}

set package_id [ad_conn package_id]

permission::require_permission -object_id $package_id -privilege faq_modify_faq


# get the sort_key for this entry_id, faq_id 
db_1row faq_sortkey_get "
select sort_key as current_sort_key
from   faq_q_and_as 
where  entry_id = :entry_id"

db_transaction {
    # I want the next sort_key
    db_1row faq_nextsortkey_get "
    select entry_id as next_entry, sort_key as next_sort_key
    from faq_q_and_as
    where sort_key = (select min(sort_key)
    from faq_q_and_as 
    where sort_key > :current_sort_key
    and faq_id = :faq_id)

    and faq_id = :faq_id
    for update"

    db_dml faq_sortkey_update "
    update faq_q_and_as
    set sort_key = :next_sort_key
    where entry_id = :entry_id"

    db_dml faq_sortkey_update "
    update faq_q_and_as
    set sort_key = :current_sort_key
    where entry_id = :next_entry"
}

db_release_unused_handles

ad_returnredirect "one-faq?[export_url_vars faq_id]" 

