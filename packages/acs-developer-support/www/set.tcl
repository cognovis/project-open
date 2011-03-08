ad_page_contract {
    Consolidated the various toggle pages into one.
    
    @author Lars Pind (lars@pinds.com)
    @author Jeff Davis <davis@xarg.net>
    @creation-date 2003-10-28
    @cvs-id $Id: set.tcl,v 1.2 2010/01/09 01:56:09 donb Exp $
} {
    field 
    enabled_p
    {return_url "."}
}

ds_require_permission [ad_conn package_id] "admin"

switch -- $field {
    com {
        parameter::set_value -package_id [ds_instance_id] -parameter ShowCommentsInlineP -value $enabled_p
    }
    adp {
        ds_set_adp_reveal_enabled $enabled_p
    }
    db {
        ds_set_database_enabled $enabled_p
    }
    prof {
        ds_set_profiling_enabled $enabled_p
    }
    ds {
        nsv_set ds_properties enabled_p $enabled_p
    }
    frag {
        nsv_set ds_properties page_fragment_cache_p $enabled_p
    }
    user {
        ds_set_user_switching_enabled $enabled_p
    }
    default { 
        ns_return 200 text/plain "bad field $field"
    }
}
ad_returnredirect $return_url
