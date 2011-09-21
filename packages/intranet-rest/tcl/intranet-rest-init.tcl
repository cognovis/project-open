ad_library {

    Initialization for intranet-rest module
    
    @author Frank Bergmann (frank.bergmann@project-open.com)
    @creation-date 10 May, 2011
    @cvs-id $Id: intranet-rest-init.tcl,v 1.2 2011/06/30 16:06:19 po34demo Exp $

}


# Register handler procedures for the various HTTP methods
ad_register_proc GET /intranet-rest/* im_rest_call_get
ad_register_proc POST /intranet-rest/* im_rest_call_post
ad_register_proc PUT /intranet-rest/* im_rest_call_put
ad_register_proc DELETE /intranet-rest/* im_rest_call_delete


# Create a global cache for im_rest entries
# The cache is bound by global timeout of 1 hour currently.
ns_cache create im_rest -timeout 3600


