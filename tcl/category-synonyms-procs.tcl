ad_library {
    category-synonyms procs for the site-wide categorization package.

    @author Bernd Schmeil (bernd@thebernd.de)
    @author Timo Hentschel (timo@timohentschel.de)

    @creation-date 8 January 2004
    @cvs-id $Id$
}


namespace eval category_synonym {}

ad_proc -public category_synonym::add {
    -name:required
    {-locale ""}
    -category_id:required
    {-synonym_id ""}
} {
    Inserts a new synonym.

    @option name synonym name.
    @option locale locale of the language. [ad_conn locale] used by default.
    @option category_id id of the category of the synonym to be inserted.
    @option synonym_id synonym_id of the synonym to be inserted.
    @author Bernd Schmeil (bernd@thebernd.de)
    @author Timo Hentschel (timo@timohentschel.de)
} {
    if {$locale eq ""} {
	set locale [ad_conn locale]
    }

    db_transaction {
	set synonym_id [db_exec_plsql insert_synonym ""]
    }
    
    return $synonym_id
}

ad_proc -public category_synonym::edit {
    -synonym_id:required
    -name:required
    {-locale ""}
} {
    Updates a synonym.

    @option synonym_id synonym_id of the synonym to be updated.
    @option name synonym name.
    @option locale locale of the language. [ad_conn locale] used by default.
    @author Bernd Schmeil (bernd@thebernd.de)
    @author Timo Hentschel (timo@timohentschel.de)
} {
    if {$locale eq ""} {
	set locale [ad_conn locale]
    }

    db_transaction {
	set synonym_id [db_exec_plsql update_synonym ""]
    }

    return $synonym_id
}

ad_proc -public category_synonym::delete { synonym_id } {
    Deletes a synonym.

    @option synonym_id synonym_id of the synonym to be deleted.
    @author Bernd Schmeil (bernd@thebernd.de)
    @author Timo Hentschel (timo@timohentschel.de)
} {
    db_transaction {
	db_exec_plsql delete_synonym ""
    }
}

ad_proc -public category_synonym::search {
    -search_text:required
    {-locale ""}
} {
    Gets all matching synonyms for search text in result table.

    @option search_text string to be matched against.
    @option locale locale of the language. [ad_conn locale] used by default.
    @author Bernd Schmeil (bernd@thebernd.de)
    @author Timo Hentschel (timo@timohentschel.de)
} {
    if {$locale eq ""} {
	set locale [ad_conn locale]
    }

    db_transaction {
	set query_id [db_exec_plsql new_search ""]
    }

    return $query_id
}

ad_proc -private category_synonym::search_sweeper {
} {
    Deletes results of old searches
} {
    db_dml delete_old_searches ""
}
