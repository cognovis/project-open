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
	<form action='/intranet-sysconfig/segment/sector' method=POST>
	<table cellspacing=0 cellpadding=4 border=0>
	<tr>
		<td></td>
		<td><input type=submit value='Next &gt;&gt;'></td>
	</tr>
	</table>
	</form>
    "

    return "
	<table height=400 width=600 cellspacing=0 cellpadding=0 border=0 background='$bg'>
	<tr valign=top><td>$wizard</td></tr>
	<tr align=center valign=bottom><td>$progress<br>&nbsp;</td></tr>
	</table>
    "
}
