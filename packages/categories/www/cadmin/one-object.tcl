ad_page_contract {
    
    Deprecated page to map objects to category trees.

    @author Timo Hentschel (timo@timohentschel.de)
    @cvs-id $Id:
} {
    object_id:integer,notnull
    {locale ""}
}

ad_returnredirect [export_vars -no_empty -base object-map { locale object_id }]
