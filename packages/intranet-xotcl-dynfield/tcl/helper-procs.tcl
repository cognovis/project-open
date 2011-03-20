# 

ad_library {
    
    
    
    @author <yourname> (<your email>)
    @creation-date 2011-03-19
    @cvs-id $Id$
}

::xo::db::CrItem instproc update_from_form {} {
    foreach var [my info vars] {
        set value [ns_queryget $var "--notthere--"]
        if {$value ne "--notthere--"} {
            my set $var [ns_queryget $var]
        }
    }
}

::xo::db::CrItem instproc json_object {} {
    foreach var [my info vars] {
        lappend json_list $var
        lappend json_list [my set $var]
    }
    # Make sure we have no " " " unescaped
    regsub -all {"} $json_list {\"} json_list
    return [util::json::object::create $json_list]
}


    

