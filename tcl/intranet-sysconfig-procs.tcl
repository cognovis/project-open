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
	<h2>$po Configuration Wizard</h2>
	<p>Please let us know about the purpose of your installation.</p>

	<h3>What is the purpose of this installation?</h3>
	<table border=0>
	<tr valign=top>
	  <td><input type=radio name=config_purpose value=first_try></td>
	  <td>	<b>First Evaluation</b><br>
		<p>I want to get a first impression of $po, but don't confuse me.<br>
		Show me a demo system with the essential functionality.<br>&nbsp;
	  </td>
	</tr>
	<tr valign=top>
	  <td><input type=radio name=config_purpose value=second_try></td>
	  <td>	<b>Second Evaluation</b><br>
		<p>I want to see if $po has the right functionality for my company.<br>
		Show me a demo system with all functionality that you've got.<br>&nbsp;
	  </td>
	</tr>
	<tr valign=top>
	  <td><input type=radio name=config_purpose value=second_try></td>
	  <td>	<b>Production Use</b><br>
		<p>I want to start using $po in my company.<br>
		Delete all demo data and configure the system for my first project.<br>&nbsp;
	  </td>
	</tr>
	</table>
    "

    set asdf asdf

    set progress "
	<table cellspacing=0 cellpadding=4 border=0>
	<tr>
		<td><a class=button href=''>&lt;&lt; Previous</a></td>
		<td><a class=button href='[export_vars -base "/intranet-sysconfig/index" {asdf {sdfg $asdf}}]'>Next &gt;&gt;</a></td>
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