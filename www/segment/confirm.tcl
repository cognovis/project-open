# /packages/intranet-sysconfig/www/sector/sector.tcl
#
# Copyright (c) 2003-2006 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract {

} {

}


# ---------------------------------------------------------------
# Frequently used variables
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_need_to_be_a_syst]"
    return
}

set bg "/intranet/images/girlongrass.600x400.jpg"
set po "<span class=brandsec>&\#93;</span><span class=brandfirst>project-open</span><span class=brandsec>&\#91;</span>"


set sector [ns_set iget [ad_conn form] "sector"]

# Gather information about the system:
set core_version [im_core_version]
set core_version_id [join [lrange [split $core_version "."] 0 2] ""]
set platform [ns_info platform]

# Default value
set iframe_url "http://www.project-open.org/en/install_${platform}_${core_version_id}"


switch [string tolower $platform] {
    win32 {
	set iframe_url "http://www.project-open.org/en/install_${platform}_${core_version_id}"
    }
    linux {
	set linux_distro [im_linux_distro]
	set vmware_p [im_linux_vmware_p]
	if {$vmware_p} {
	    set plaform "vm"
	    set iframe_url "http://www.project-open.org/en/install_vm_${core_version_id}"
	} else {
	    set iframe_url "http://www.project-open.org/en/install_${linux_distro}_${core_version_id}"
	}
    }
    default {
	set iframe_url "http://www.project-open.org/en/install_${platform}_${core_version_id}"
    }
}

# Make sure the XoWiki page doesn't show a clumsy template
# 20120906 fraber: please note the additional "&" behind the variable.
# That's necessary now because both firefox and chrome swallow the last char...
append iframe_url "?no%5ftemplate%5fp=1&"

# ---------------------------------------------------------------
# Check if everything is together
# ---------------------------------------------------------------

set pages [list sector deptcomp features orgsize]
set ready 1

foreach v $pages {
    set $v [ns_set iget [ad_conn form] $v]
    if {![exists_and_not_null $v]} { set ready 0 }
}


# ---------------------------------------------------------------
# Write variables to parameters
# ---------------------------------------------------------------


set package_key "intranet-sysconfig"
set default_value ""
set datatype "string"
set section_name ""
set min_n_values 1
set max_n_values 1


foreach param {Sector DeptComp OrgSize Features} {

    set lower_param [string tolower $param]
    set parameter_name "Company${param}"
    set parameter_description $parameter_name

    set parameter_id [db_string param "
        select  parameter_id
        from    apm_parameters
        where   package_key = :package_key
                and parameter_name = :parameter_name
    " -default ""]

    if {"" == $parameter_id} {
        catch {
            set parameter_id [apm_parameter_register \
                                  -parameter_id $parameter_id \
                                  $parameter_name \
                                  $parameter_description \
                                  $package_key \
                                  "" \
                                  "string" \
                                  "" \
                                  1 \
                                  1 \
	     ]
        } err_msg
    }

    set value [ns_set iget [ad_conn form] $lower_param]
    set package_id [apm_package_id_from_key $package_key]
    parameter::set_value \
        -package_id $package_id \
        -parameter $parameter_name \
        -value $value

}

