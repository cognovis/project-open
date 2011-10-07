# 

ad_page_contract {
    
    hack login
    
    @author <yourname> (<your email>)
    @creation-date 2011-09-21
    @cvs-id $Id$
} {
    
} -properties {
} -validate {
} -errors {
}

ad_user_login -forever 624
ad_returnredirect http://kolibri.cognovis.de/acs-admin
