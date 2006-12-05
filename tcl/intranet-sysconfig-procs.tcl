# /packages/intranet-sysconfig/tcl/intranet-sysconfig-procs.tcl
#
# Copyright (c) 2006 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    SysConfig Conviguration Wizard
    @author frank.bergmann@project-open.com
}


# ----------------------------------------------------------------------
# 
# ----------------------------------------------------------------------

ad_proc -public im_package_sysconfig_id {} {
    Returns the package id of the intranet-sysconfig module
} {
    return [util_memoize "im_package_sysconfig_id_helper"]
}

ad_proc -private im_package_sysconfig_id_helper {} {
    return [db_string im_package_core_id {
        select package_id from apm_packages
        where package_key = 'intranet-sysconfig'
    } -default 0]
}


# ----------------------------------------------------------------------
# 
# ----------------------------------------------------------------------

ad_proc -public im_sysconfig_component { } {
    Returns a formatted HTML block as the very first page
    of a freshly installed V3.2 and higher system, allowing
    the user to configure the system
} {
    set bg "/intranet/images/girlongrass.600x400.jpg"
    set po "<span class=brandsec>&\#93;</span><span class=brandfirst>project-open</span><span class=brandsec>&\#91;</span>"

    set wizard "
	<h2>License Agreement</h2>

	<p>
	This software has been developed by $po<br>
	(<a href=http://www.project-open.org/>http://www.project-open.org/</a>) 
	based on the work of <br>
	several open-source projects and other contributors.
	</p>
<table cellpadding=2>
<tr><td>Novell/SuSE</td>	<td>http://www.novell.com/licensing/eula/suse_pro_93.pdf</td></tr>
<tr><td>&\#93;project-open&\#91;</td>	<td>http://www.project-open.com/license/</td></tr>
<tr><td>AOLserver</td>		<td>http://www.aolserver.com/license/</td></tr>
<tr><td>OpenACS</td>		<td>http://openacs.org/about/licensing/</td></tr>
<tr><td>VMWare Tools</td>	<td>http://www.vmware.com/support/</td></tr>
</table>

	<p>
	You need to agree with the license terms of ALL of <br>
	these authors prio to using the software.
	</p>

"

    set progress "
	<table cellspacing=0 cellpadding=4 border=0>
	<tr>
		<td><span class=button>&lt;&lt; Previous</span></td>
		<td><a class=button href='[export_vars -base "/intranet-sysconfig/segment/sector"]'>Next &gt;&gt;</a></td>
	</tr>
	</table>
    "

    return "
	<table height=400 width=600 cellspacing=0 cellpadding=0 border=0 background='$bg'>
	<tr valign=top><td>$wizard</td></tr>
	<tr align=center valign=bottom><td>$progress<br>&nbsp;</td></tr>
	</table>
    "
}


ad_proc -public im_sysconfig_progress_bar {
    {-wizard_stage 0}
    {-wizard_stages ""}
} {
    Returns a formatted HTML block representing the advancing
    of the configuration process.
    @param wizard_stages - A list of wizard stages
           Each stage consists of {Name URL Var}
} {
    set po "<span class=brandsec>&\#93;</span><span class=brandfirst>project-open</span><span class=brandsec>&\#91;</span>"

    set progress ""
    set stage [lindex $wizard_stages $wizard_stage]

    # Element is "previous"
    if {0 == $wizard_stage} {
	append progress "<td>[lindex $stage 0]</td>\n"
    } else {
	append progress "<td><a href=[lindex $stage 1]>[lindex $stage 0]</a></td>\n"
    }

    if {$wizard_stage > 0 && $wizard_stage < [llength $wizard_stages]} {

    }

    return "
	<table border=0>
	<tr>
		<td><font color=grey>Previous</font></td>
		<td><font color=grey><a href=/intranet-sysconfig/index?Purpose</font></td>
	</tr>
	</table>
    "

}



ad_proc -public im_sysconfig_navigation_bar_sector {
    page
} {
    Returns a formatted HTML block representing the advancing
    of the configuration process.
    @param wizard_stages - A list of wizard stages
    Each stage consists of {Name URL Var}
} {
    set pages [list index sector deptcomp features orgsize]
    set vars [list sector deptcomp features orgsize]

    set base_url "/intranet-sysconfig/segment"

    # Determine prev & next links
    set index [lsearch $pages $page]
#    ad_return_complaint 1 "$index $page"
    set prev "$base_url/[lindex $pages [expr $index-1]]"
    set next "$base_url/[lindex $pages [expr $index+1]]"

    # Deal with Exceptions
    switch $page {
	index {
	    set prev ""
	}
    }

    set prev_link "<a class=button href='[export_vars -base $prev]'>&lt;&lt; Previous </a>"
    set next_link "<a class=button href='[export_vars -base $next]'>Next &gt;&gt;</a>"

    set prev_link "<input type=image class=button onClick=\"window.document.wizard.action='[lindex $pages [expr $index-1]]'; submit();\" title='&lt;&lt; Prev' alt='&lt;&lt; Prev'>"
    set next_link "<input type=image class=button onClick=\"window.document.wizard.action='[lindex $pages [expr $index+1]]'; submit();\" title='Next &gt;&gt;' alt='Next &gt;&gt;'>"

#    if {"" == $prev} { set prev_link "" }
#    if {"" == $next} { set next_link "" }

    set navbar "
	<table cellspacing=0 cellpadding=4 border=0>
	<tr>
		<td>$prev_link</td><td>$next_link</td>
	</tr>
	</table>
    "
    return $navbar
}

