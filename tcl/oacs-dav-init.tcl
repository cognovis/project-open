# 

ad_library {
    
    setup filters
    
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2003-12-18
    @cvs-id $Id$
    
}

set prefix [parameter::get \
		-package_id [apm_package_id_from_key "oacs-dav"] \
		-parameter "WebDAVURLPrefix" \
		-default "/dav"]

set url "${prefix}/*"
set filter_url "${prefix}/*"
ns_register_filter preauth GET ${filter_url} oacs_dav::authorize
ns_register_filter preauth HEAD ${filter_url} oacs_dav::authorize
ns_register_filter preauth PUT ${filter_url} oacs_dav::authorize
ns_register_filter preauth MKCOL ${filter_url} oacs_dav::authorize
ns_register_filter preauth COPY ${filter_url} oacs_dav::authorize
ns_register_filter preauth MOVE ${filter_url} oacs_dav::authorize
ns_register_filter preauth PROPFIND ${filter_url} oacs_dav::authorize
ns_register_filter preauth PROPPATCH ${filter_url} oacs_dav::authorize
ns_register_filter preauth DELETE ${filter_url} oacs_dav::authorize
ns_register_filter preauth LOCK ${filter_url} oacs_dav::authorize
ns_register_filter preauth UNLOCK ${filter_url} oacs_dav::authorize

ns_log notice "OACS-DAV preauth filters loaded on $filter_url"

ns_register_proc GET ${url} oacs_dav::handle_request
ns_register_proc HEAD ${url} oacs_dav::handle_request
ns_register_proc COPY ${url} oacs_dav::handle_request
ns_register_proc PUT ${url} oacs_dav::handle_request
ns_register_proc DELETE ${url} oacs_dav::handle_request
ns_register_proc PROPFIND ${url} oacs_dav::handle_request
ns_register_proc PROPPATCH ${url} oacs_dav::handle_request
ns_register_proc MKCOL ${url} oacs_dav::handle_request
ns_register_proc MOVE ${url} oacs_dav::handle_request
ns_register_proc LOCK ${url} oacs_dav::handle_request
ns_register_proc UNLOCK ${url} oacs_dav::handle_request
