ad_page_contract {
    Toggle the approved flag for a given spam queue entry

    @author markd@arsdigita.com
} {
    spam_id:integer,notnull
}

db_dml toggle_approval {
    update spam_messages
       set approved_p = util.logical_negation(approved_p)
     where spam_id = :spam_id
}

db_1row spam_get_message_for_approval {
    select to_char(send_date, 'yyyy-mm-dd hh24:mi:ss') as sql_send_time,
      sql_query, approved_p
    from spam_messages
    where spam_id = :spam_id
}

ad_returnredirect index
