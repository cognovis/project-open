ad_library {

    Additional Widgets for use with the intranet-dynfield
    extensible architecture

    @creation-date 2005-01-25
    @cvs-id $Id: generic-sql-widget-procs.tcl,v 1.11 2009/02/18 01:43:24 cvs Exp $
}


ad_proc -public template::widget::skype { element_reference tag_attributes } {
    Skype Widget

    @param select A SQL select statement returning a list of key-value
                  pairs that serve to define the values of a select
                  widget. A single select is suitable to display some
                  200 values. Please use a different widget if you
                  have to display more then these values.
} {
    upvar $element_reference element

#   Show all availabe variables in the variable frame
#   ad_return_complaint 1 "<pre>\n'$element(custom)'\n[array names element]\n</pre>"
    array set attributes $tag_attributes

    set skype_html ""
    set value ""
    if {[info exists element(value)]} { set value $element(value) }
    if { "edit" != $element(mode) } {
	if {1} {
	    append skype_html "<table><tr><td>$value</td><td> <!--
Skype 'Skype Me™!' button
http://www.skype.com/go/skypebuttons
-->
<script type=\"text/javascript\" src=\"http://download.skype.com/share/skypebuttons/js/skypeCheck.js\"></script>
<a href=\"skype:$value?call\"><img src=\"http://download.skype.com/share/skypebuttons/buttons/call_blue_transparent_34x34.png\" style=\"border: none;\" width=\"34\" height=\"34\" alt=\"Skype Me™!\" /></a>
</td></tr></table>"
	} else {
	    append skype_html "$value - <!--
Skype 'My status' button
http://www.skype.com/go/skypebuttons
-->
<script type=\"text/javascript\" src=\"http://download.skype.com/share/skypebuttons/js/skypeCheck.js\"></script>
<a href=\"skype:$value?call\"><img src=\"http://mystatus.skype.com/bigclassic/$value\" style=\"border: none;\" width=\"182\" height=\"44\" alt=\"$value status\" /></a>"
	}
    } else {
      set skype_html [input text element $tag_attributes]
    }

    return $skype_html
}
