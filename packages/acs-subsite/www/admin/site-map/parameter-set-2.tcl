ad_page_contract {

    Set parameters on a package instance.

    @author Bryan Quinn (bquinn@arsdigita.com)
    @creation-date 12 September 2000
    @cvs-id $Id: parameter-set-2.tcl,v 1.5 2009/01/06 02:25:34 gustafn Exp $

} {
    package_key:notnull
    package_id:naturalnum,notnull
    instance_name:notnull
    {return_url "."}
    params:array
}

ad_require_permission $package_id admin

if { [catch {
    db_foreach apm_parameters_set {} {
	if {[info exists params($parameter_id)]} {
	    parameter::set_value -value $params($parameter_id) -package_id $package_id -parameter $parameter_name 
	}
    }
} errmsg] } {
    ad_return_error "Database Error" "The parameters could not be set.  The database error was:<p>
<blockquote><pre>[ad_quotehtml $errmsg]</pre></blockquote>."
} else {
    ad_returnredirect $return_url
}
