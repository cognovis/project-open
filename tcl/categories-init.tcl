ad_library {
    Procs for the site-wide categorization package.

    @author Timo Hentschel (timo@timohentschel.de)

    @creation-date 16 April 2003
    @cvs-id $Id$
}

category::reset_translation_cache
category_tree::reset_translation_cache
category_tree::reset_cache

ad_schedule_proc -thread t -schedule_proc ns_schedule_daily [list 0 16] category_synonym::search_sweeper
