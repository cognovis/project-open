# /packages/lang/www/locale-set.tcl
ad_page_contract {

    Sets a locale for the browser

    @author John Lowry (lowry@ardigita.com)
    @creation-date 29 September 2000
    @cvs-id $Id: locale-set.tcl,v 1.1 2005/04/18 19:25:53 cvs Exp $
} {
    locale
    {redirect_url {[ns_set iget [ns_conn headers] referer]}}
}

# set the locale property
ad_locale_set locale $locale

ad_returnredirect $redirect_url

