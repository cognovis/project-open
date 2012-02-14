ad_page_contract {

    Prepare some datasources for the explain-persistent-cookies .adp

    @author Bryan Quinn (bquinn@arsdigita.com)
    @creation-date Mon Oct 16 09:27:34 2000
    @cvs-id $Id: explain-persistent-cookies.tcl,v 1.2 2010/10/19 20:12:43 po34demo Exp $
} {

} -properties {
    home_link:onevalue
}

set home_link [ad_site_home_link]
ad_return_template

