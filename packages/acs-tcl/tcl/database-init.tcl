ad_library {

    Initialization code for database routines.

    @creation-date 7 Aug 2000
    @author Jon Salz (jsalz@arsdigita.com)
    @cvs-id $Id: database-init.tcl,v 1.2 2010/10/19 20:12:54 po34demo Exp $

}

#DRB: the default value is needed during the initial install of OpenACS
ns_cache create db_cache_pool -size \
    [parameter::get_from_package_key  \
        -package_key acs-kernel \
        -parameter DBCacheSize -default 50000]
