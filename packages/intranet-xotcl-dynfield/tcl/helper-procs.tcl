# packages/intranet-xo-dynfield/tcl/helper-procs.tcl
#
# Copyright (c) 2011, cognovís GmbH, Hamburg, Germany
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.



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

::xo::db::Object instproc json_object {} {
    foreach var [my info vars] {
        lappend json_list $var
        lappend json_list [my set $var]
    }
    # Make sure we have no " " " unescaped
    regsub -all {"} $json_list {\"} json_list
    return [util::json::object::create $json_list]
}


    

