ad_library {
    Procs for the diagram builder.

    @author Nima Mazloumi (mazloumi@uni-mannheim.de)
    @creation-date 2005-11-18
    @cvs-id $Id$
}

namespace eval template {}
namespace eval template::diagram {}
namespace eval template::diagram::element {}

#####
#
# template::diagram namespace
#
#####

ad_proc -public template::diagram::create {
    {-name:required}
    {-multirow ""}
    {-title ""}
    {-x_label "x"}
    {-y_label "y"}
    {-scales "1 1"}
    {-color "#c0c0c0"}
    {-left 0}
    {-top 0}
    {-right 100}
    {-bottom 100}
    {-ulevel 1}
    {-elements:required}
    {-template "curve"}
} {
    Defines a diagram to be displayed in a template. The diagram works in conjunction with a multirow, which contains the data for the diagram.
    The diagram is output using templating tag &lt;diagram&gt; and internally also &lt;diagramelement&gt;.

    Three diagrams types are currently supported: "curve", "pie" and "cockpit". The type is defined by passing the name to the template switch.
    The templates are defined in the diagram package under resources/diagram/.
    <p>

    Here's an example of a fairly simple diagram. Note that you must specify the multirow before the diagram since the columns names of the multirow
    are retrieved dynamically.

    <pre>
    db_multirow mydata select_objects {
	select x, y from logs
    }

    template::diagram::create
	-name mydiagram
	-multirow mydata
	-title "My Diagram"
	-x_label "X-Label"
	-y_label "Y-Label"
	-left $left -top $top -right $width -bottom $height
	-scales "1 1"
	-template curve
	-elements {
	    mycurve {
		color "\#c0c0c0"
		type 1
		label "My Curve"
		size 2
		dot_type 1
	    }
	}
    </pre>

    And the ADP template would include this:

    <pre>
    &lt;property name="header_stuff"&gt;&lt;SCRIPT Language="JavaScript" src="/resources/diagram/diagram/diagram.js"&gt;&lt;/SCRIPT&gt;&lt;/property&gt;
    &lt;diagram name="mydiagram"&gt;&lt;/diagram&gt;
    </pre>

    You can also provide a csv export of the data rendered in the diagram by simply adding this to you page:

    <pre>
    #at the beginning of your tcl page
    ad_page_contract {
    } {
	{csv ""}
    }
    </pre>

    <pre>
    #after you template definition
    if {[exists_and_not_null csv]} {
	template::diagram::write_output -name mydiagram
    }
    </pre

    Thus if a parameter called "csv" was passed to you page return the "diagram.csv" file containing the data.

    @param  name           The name of the diagram you want to build.
    @param  multirow       The name of the multirow which you want to loop over. Defaults to name of the diagram.
    @param  title          The diagram title
    @param  x_label        The label to use for the x axis
    @param  y_label        The label to use for the y axis
    @param  scales         An two value list: 0 = no scale, 1=numeric, 2,3,4=date scales.
    @param  color          The color of the diagram
    @param  left           The relative postition of the diagram
    @param  top            ..
    @param  right          ..
    @param  bottom         ..
    @param  ulevel         The number of levels to uplevel when doing subst on values for elements. Defaults to one level up, which means the caller of template::diagram::create's scope.
    @param  elements        The list elements
                           The value should be an array-list of (name, spec) pairs, like in the example above. Each spec, in turn, is an array-list of
                           property-name/value pairs, where the value is 'subst'ed in the caller's environment, except for the *_eval properties, which are
                           'subst'ed in the multirow context.
                           See <a href="/api-doc/proc-view?proc=template::diagram::element::create">template::diagram::element::create</a> for details.
    @param  template       The template to use for the rendering. Currently there is support only for Javascript based diagrams. They have been tested for firefox, IE, Opera, safari and camino.
                           Other ways to generated the diagrams can be integrated by writing your own templates and for instance using GNUPlot.
                           The current templates availabe are: "curve", "pie" and "cockpit"

    @see template::diagram::element::create
    @author Nima Mazloumi (nima.mazloumi@gmx.de)

} {
    set level [template::adp_level]

    # Get an upvar'd reference to diagram_properties
    get_reference -create -name $name
    
    # Setup some list defaults
    array set diagram_properties {
	title {}
        x_label {}
	y_label {}
	scales {}
	color {}
	left {}
	top {}
	right {}
	bottom {}
	multirow {}
        template {}
    }

    # These are defauls for internally maintained properties
    array set diagram_properties {
        elements {}
        element_refs {}
        display_elements {}
        ulevel {}
        output {}
    }

    # Set default for no_data
    # Set ulevel to the level of the page, so we can access it later
    set diagram_properties(ulevel) "\#[expr [info level] - $ulevel]"

    # Set properties from the parameters passed
    foreach elm { 
        name
	title
	x_label
	y_label
	scales
	color
	left
	top
	right
	bottom
        multirow
	template
    } {
        set diagram_properties($elm) [set $elm]
    }

    # Default 'multirow' to list name
    if { [empty_string_p $diagram_properties(multirow)] } {
	set diagram_properties(multirow) $name
    }

    set columns [template::multirow columns $multirow]
    set i 0
    foreach {curve spec} $elements {

	set x [lindex $columns $i]
	set y [lindex $columns [expr "$i+1"]]

	# Need to uplevel 2 the subst command to get to our caller's namespace
	template::diagram::element::create \
	    -diagram_name $name \
	    -element_name $x \
	    -spec $spec \
	    -ulevel 2

	template::diagram::element::create \
	    -diagram_name $name \
	    -element_name $y \
	    -spec $spec \
	    -ulevel 2
	
	incr i 2
    }

    # Done, prepare the list. This has to be done while we still have access to the caller's scope
    prepare \
        -name $name \
        -ulevel 2
}


ad_proc -private template::diagram::resources_path {
} {
    return "/resources/diagram/diagram/"
}

ad_proc -private template::diagram::prepare_value {
    -value:required
    -scale:required
} {
    prepares the values given the scale. 0 nothing, 1 numerical, 2,... date
} {
    switch $scale {
	0 - 1 {return $value;}
	default {return "Date.UTC($value)";}
    }
}

ad_proc -private template::diagram::prepare_positioning {
    -name:required
} {
    Sets the position of the diagram in accordance to the given coordinates
} {
    get_reference -name $name
    set bottom $diagram_properties(bottom)
    set right $diagram_properties(right)
    set diagram_properties(height) [expr "$bottom + 30"]
    set diagram_properties(width) [expr "$right + 20"]
}

ad_proc -private template::diagram::get_slice_color {
    {-part:required}
    {-sum:required}
} {
} {
    if { $sum == 0 } { set sum 1}

    set d [expr $sum - $part]

    set r [expr 255 / $sum * $part]
    set g [expr 255 / $sum * $d]
    set b 0

    return "$r,$g,$b"
}

ad_proc -private template::diagram::update_borders {
    {-scale:required}
    {-list:required}
    {-min:required}
    {-max:required}
    {-sum:required}
    {-local_list:required}
} {
} {
    upvar $min mn
    upvar $max mx
    upvar $sum sm
    upvar $local_list l

    set _min ""
    set _max ""

    switch $scale {
	#its numerical
	0 - 1 {
	    set l [lsort -real -increasing $list]
	    set _min [lindex $l 0]
	    set _max [lindex $l [expr "[llength $l] - 1"]]
	    lappend sm [expr "[join $l "+"]"]
	}
	#its a date scale
	default {
	    set l [lsort -increasing $list]
	    set _min "Date.UTC([lindex $l 0])"
	    set _max "Date.UTC([lindex $l [expr "[llength $l] - 1"]])"
	}
    }
    #ns_log Notice "List: $l"

    if {[empty_string_p $mn] || $_min < $mn} {
	set mn $_min
    }
    
    if {[empty_string_p $mx] || $_max > $mx} {
	set mx $_max
    }
}

ad_proc -private template::diagram::set_borders {
    -name:required
} {
    Sets the borders for the axis
} {
    get_reference -name $name

    set count [expr "[llength $diagram_properties(display_elements)] / 2"]
    set diagram_properties(count) $count

    for {set j 1} {$j <= [llength $diagram_properties(display_elements)]} {incr j} {
	set col$j [list] 
    }

    #iterate over the multirow
    template::multirow foreach $diagram_properties(multirow) {

        #iterate over each column
        for {set j 0} {$j < [llength $diagram_properties(display_elements)]} {incr j} {
            set element [lindex $diagram_properties(display_elements) $j]
            template::diagram::element::get_reference \
                -diagram_name $name \
                -element_name $element \
                -local_name __element_properties

            if { [info exists $__element_properties(name)] } {
		lappend "col[expr "$j + 1"]" "[lindex [set $__element_properties(name)] 0]"
            }
        }
    }

    set x_min ""
    set x_max ""
    set y_min ""
    set y_max ""

    set scales $diagram_properties(scales)
    set minima [list]
    set sum [list]

    #lets iterate over all columns and get the borders
    for {set j 1} {$j <= [llength $diagram_properties(display_elements)]} {incr j} {

	#first we check which axis to use (odd columns represent the x, even the y axis)
	set xy [expr "$j % 2"]

	#now we need a counter for each diagram
	set d [expr "int(ceil(($j/2) % $count)) + 1"]

	#we need to update min and max

	set list [list]

	#its the x axis
	if {$xy == 1} {
	    update_borders -scale [lindex $scales 0] -list [set col$j] -local_list list -min x_min -max x_max -sum sum
	    lappend minima "x$d=D.ScreenX([prepare_value -value [lindex $list 0] -scale [lindex $scales 0]])"

	#its the y axis
	} else {
	    update_borders -scale [lindex $scales 1] -list [set col$j] -local_list list -min y_min -max y_max -sum sum
	    lappend minima "y$d=D.ScreenY([prepare_value -value [lindex $list 0] -scale [lindex $scales 1]])"
	}

	#ns_log Notice "X($x_min,$x_max), Y($y_min,$y_max)"
    }

    set borders [list $x_min $x_max $y_min $y_max]

    #some important helpers
    set diagram_properties(sum) $sum
    set diagram_properties(minima) "var [join $minima ";\nvar "];"
    set diagram_properties(borders) "[join $borders ","]"
    set diagram_properties(x0) "D.ScreenX($x_min)"
    set diagram_properties(y0) "D.ScreenY($y_min)"
    set diagram_properties(scales) "D.XScale=[lindex $scales 0];\nD.YScale=[lindex $scales 1];"
    set diagram_properties(x_scale) [lindex $scales 0]
    set diagram_properties(y_scale) [lindex $scales 1]
    #ns_log Notice "\nSum $sum\nMinima $minima\nBorders $borders" 
}

ad_proc -private template::diagram::prepare {
    {-name:required}
    {-ulevel 1}
} {
    Prepare list for rendering
} {
    # Get an upvar'd reference to diagram_properties
    get_reference -name $name

    # Default the display_elements property to be all elements
    if { [llength $diagram_properties(display_elements)] == 0 } {
        set diagram_properties(display_elements) $diagram_properties(elements)
    }
}

ad_proc -private template::diagram::get_refname {
    {-name:required}
} {
    return "$name:properties"
}

ad_proc -private template::diagram::get_reference {
    {-name:required}
    {-local_name "diagram_properties"}
    {-create:boolean}
} {
    set refname [get_refname -name $name]
    
    if { !$create_p && ![uplevel \#[template::adp_level] [list info exists $refname]] } {
        error "List '$name' not found"
    }
    
    uplevel upvar #[template::adp_level] $refname $local_name
}

ad_proc -private template::diagram::write_output {
    -name:required
} {
    Writes the output to the connection if output isn't set to template.
    Will automatically issue an ad_script_abort, if the output has been written
    directly to the connection instead of through the templating system.
} {
    # Get an upvar'd reference to diagram_properties
    get_reference -name $name
    
    write_csv -name $name
    ad_script_abort
}

ad_proc -private template::diagram::csv_quote {
    string
} {
    Quote a string for inclusion as a csv element
} {
    regsub -all {\"} $string {""} result
    return $result
}

ad_proc -private template::diagram::write_csv {
    -name:required
} {
    Writes a CSV to the connection
    @author Nima Mazloumi (nima.mazloumi@gmx.de)
} { 
    # Creates the '_eval' columns and aggregates
    template::diagram::prepare -name $name
 
    get_reference -name $name
    
    set __diagram_name $name
    set __output {}

    # Output header row
    set __cols [list]
    foreach __element_name $diagram_properties(display_elements) {
        lappend __cols [csv_quote $__element_name]
    }
    append __output "\"[join $__cols "\";\""]\"\n"

    # Output rows
    template::multirow foreach $diagram_properties(multirow) {

        set __cols [list]

        foreach __element_name $diagram_properties(display_elements) {
            template::diagram::element::get_reference \
                -diagram_name $__diagram_name \
                -element_name $__element_name \
                -local_name __element_properties

            if { [info exists $__element_properties(csv_col)] } {
                lappend __cols [csv_quote [set $__element_properties(csv_col)]]
            }
        }
        append __output "\"[join $__cols "\";\""]\"\n"
    }

    ns_set put [ad_conn outputheaders] Content-Disposition "attachment;filename=diagram.csv"
    ns_return 200 text/csv $__output
}

ad_proc -private template::diagram::template { 
    {-name:required}
    {-template ""} 
} {
    Process a list template with the special hacks into becoming a
    'real' ADP template, as if it was included directly in the page.
    Will provide that template with a multirow named 'elements'.
} { 
    set level [template::adp_level]
    
    # Get an upvar'd reference to diagram_properties
    get_reference -name $name


    #
    # Create 'elements' multirow
    #

    # Manually construct a multirow by upvar'ing each of the element refs
    set elements:rowcount 0

    foreach element_name $diagram_properties(display_elements) {
        set element_ref [template::diagram::element::get_refname \
                             -diagram_name $name \
                             -element_name $element_name]
        upvar #$level $element_ref element_properties

	incr elements:rowcount
	
	# get a reference by index for the multirow data source
	upvar #$level $element_ref elements:${elements:rowcount} 
	
	# Also set the rownum pseudocolumn
	set "elements:${elements:rowcount}(rownum)" ${elements:rowcount}
    }

    #
    # Find the list template
    #

    if { [string equal $template {}] } { 
        set template $diagram_properties(template)
    }

    if { [string equal $template {}] } { 
      set template [parameter::get \
                     -package_id [ad_conn subsite_id] \
                     -parameter DefaultDiagramTemplate \
                     -default [parameter::get \
                                   -package_id [apm_package_id_from_key "diagram"] \
                                   -parameter DefaultDiagramTemplate \
                                   -default "curve"]]
    }
    set file_stub "[acs_root_dir]/packages/diagram/resources/diagram/$template"

    # ensure that the template template has been compiled and is up-to-date
    template::adp_init adp $file_stub

    # get result of template output procedure into __adp_output
    # the only data source on which this template depends is the "elements"
    # multirow data source.  The output of this procedure will be
    # placed in __adp_output in this stack frame.
   
    template::code::adp::$file_stub

    return $__adp_output
}

ad_proc -private template::diagram::render {
    {-name:required}
    {-template ""}
} {
    set level [template::adp_level]
    
    set_borders -name $name
    prepare_positioning -name $name

    # Get an upvar'd reference to diagram_properties
    get_reference -name $name

    # This gets and actually compiles the dynamic template into the template to use for the output
    # Thus, we need to do the dynamic columns above before this step
    set __adp_output [template -name $name -template $template]
    
    # set __adp_stub so includes work. Only fully qualified includes will work with this
    
    set __list_code {
	set __adp_stub ""
    }
    append __list_code [template::adp_compile -string $__adp_output]
    
    # Get the multirow upvar'd to this namespace
    template::multirow upvar $diagram_properties(multirow)

    # evaluate the code and return the rendered HTML for the list
    set __output [template::adp_eval __list_code]

    return $__output
}

#####
#
# template::diagram::element namespace
#
#####

ad_proc -private template::diagram::element::create {
    {-diagram_name:required}
    {-element_name:required}
    {-spec:required}
    {-ulevel 1}
} {
    Adds an element to a diagram builder diagram.
    
    <p>
    This proc shouldn't be called directly, only through <a href="/api-doc/proc-view?proc=template::diagram::create">template::diagram::create</a>.
    <p>
    
    The properties depend on the diagram type used (-template switch of <a href="/api-doc/proc-view?proc=template::diagram::create">template::diagram::create</a>).
    These are the general properties in the spec:
    
    <p>
    <ul>
     <li>
      <b>label</b>: The label to use for the element.
     </li>
     <li>
      <b>color</b>: The color of the element. Currently you have to use the hex presentation. i.e. \#c0c0c0
     </li>
     <li>
      <b>size</b>: The size of the diagram element
     </li>
    </ul>
    
    The curve diagram type has the following properties as well:
    <ul>  
     <li>
      <b>type</b>: The curve type: 1=dot, 2=bar, 3=box, 4=line.
     </li>
    </ul>

    For the curve type dot you can specify another property called "dot_type": 1,3,4,5=different plus types, 2,5=rectangles.

    @param diagram_name     Name of diagram.
    @param element_name  Name of the element.
    @param spec          The spec for this element. This is an array list of property/value pairs, where the right hand side
                         is 'subst'ed in the caller's namespace, except for *_eval properties, which are 'subst'ed inside the multirow.
    @param ulevel        Where we should uplevel to when doing the subst's. Defaults to '1', meaning the caller's scope.

    @see  template::diagram::create
    @author Nima Mazloumi (nima.mazloumi@gmx.de)
} {
    # Get an upvar'd reference to diagram_properties
    template::diagram::get_reference -name $diagram_name
    
     # Get the list properties
    lappend diagram_properties(elements) $element_name

    # We store the full element ref name, so its easy to find later
    lappend diagram_properties(element_refs) [get_refname -diagram_name $diagram_name -element_name $element_name]

    # Create the element properties array
    get_reference -create -diagram_name $diagram_name -element_name $element_name

    # Setup element defaults
    array set element_properties {
        label {}
	color {}
	type {}
        csv_col {}
	image {}
	dot_type {}
	size {}
    }

    # These attributes are internal listbuilder attributes
    array set element_properties {
        subrownum 0
    }

    # Let the element know its own name
    set element_properties(name) $element_name
        
    # Let the element know its owner's name
    set element_properties(diagram_name) $diagram_name

    incr ulevel
    
    set_properties \
        -diagram_name $diagram_name \
        -element_name $element_name \
        -spec $spec \
        -ulevel $ulevel

    # Default csv_col to name
    if { [empty_string_p $element_properties(csv_col)] } {
        set element_properties(csv_col) $element_properties(name)
    }
}

ad_proc -private template::diagram::element::get_refname {
    {-diagram_name:required}
    {-element_name:required}
} {
    @return the name used for the list element properties array.
} {
    return "$diagram_name:element:$element_name:properties"
}

ad_proc -private template::diagram::element::get_reference {
    {-diagram_name:required}
    {-element_name:required}
    {-local_name "element_properties"}
    {-create:boolean}
} {
    upvar the list element to the callers scope as $local_name
} {
    # Check that the list exists
    template::diagram::get_reference -name $diagram_name

    set refname [get_refname -diagram_name $diagram_name -element_name $element_name]

    if { !$create_p && ![uplevel \#[template::adp_level] [list info exists $refname]] } {
        error "Element '$element_name' not found in list '$diagram_name'"
    }

    uplevel upvar #[template::adp_level] $refname $local_name
}

ad_proc -private template::diagram::element::set_property {
    {-diagram_name:required}
    {-element_name:required}
    {-property:required}
    {-value:required}
    {-ulevel 1}
} {
    # Get an upvar'd reference to diagram_properties
    template::diagram::get_reference -name $diagram_name
    
    get_reference \
        -diagram_name $diagram_name \
        -element_name $element_name

    switch $property {
        default {
            # We require all properties to be initialized to the empty string in the array, otherwise they're illegal.
            if { ![info exists element_properties($property)] } {
                error "Unknown element property '$property'. Allowed properties are [join [array names element_properties] ", "]."
            }

            # All other vars, do an uplevel subst on the value now
            set element_properties($property) [uplevel $ulevel [list subst $value]]
        }
    }
}

ad_proc -private template::diagram::element::set_properties {
    {-diagram_name:required}
    {-element_name:required}
    {-spec:required}
    {-ulevel 1}
} {
    incr ulevel

    foreach { property value } $spec {
        set_property \
            -diagram_name $diagram_name \
            -element_name $element_name \
            -property $property \
            -value $value \
            -ulevel $ulevel
    }
}

ad_proc -private template::diagram::element::render {
    {-diagram_name:required}
    {-element_name:required}
} {
    Returns an ADP chunk, which must be evaluated
} {
    set level [template::adp_level]

    # Get an upvar'd reference to diagram_properties
    template::diagram::get_reference -name $diagram_name

    set multirow $diagram_properties(multirow)

    set output "@$multirow.$element_name@"

    return $output
}

#####
#
# Templating system ADP tags
#
#####

template_tag diagram { chunk params } {

    set level [template::adp_level]

    set diagram_name [template::get_attribute diagram $params name]
    
    set template [ns_set iget $params template]
    
    template::adp_append_code "set diagram_properties(name) [list $diagram_name]"

    template::adp_append_string \
        "\[template::diagram::render -name \"$diagram_name\" -template \"$template\"\]"
}

template_tag diagramelement { params } {
    
    set element_name [template::get_attribute diagramelement $params name]

    # diagram_properties will be available, because 

    template::adp_append_string \
        "\[template::diagram::element::render -diagram_name \${diagram_properties(name)} -element_name $element_name\]"
}