ad_page_contract {
    @author Luke Pond
    @creation-date 2002-03-06

    Code generator to give you a head start with using ATS forms.
    Generates template::form::element commands for each of the 
    attributes in a table.  PostgreSQL only.

} {
    {table_name "acs_objects"}
    {object_name "object"}
    {primary_key "object_id"}
}

if {![empty_string_p $table_name] && ![db_0or1row table_name_check {
    select oid from pg_class where lower(relname) = lower(:table_name)
}]} {
    ad_returnredirect "formwizard"
}

set form_name $table_name

# maps PG datatype to ATS widget
array set widget_map { bool select date date timestamp date time date}

# maps PG datatype to ATS date format 
# (can be more extensively customized; see ATS date-procs.tcl)
array set date_format_map { date "MONTH DD, YYYY" timestamp "MONTH DD, YYYY HH24:MI" time "HH24:MI" }

# maps PG datatype to ATS datatype used for automatic form validation
array set datatype_map { int4 integer date date timestamp date time date}

# maps PG column name to option list (obtained from check constraints)
array set options_map { }

db_foreach get_checks {
    select rcsrc
      from pg_relcheck r, pg_class c
     where r.rcrelid = c.oid
       and lower(c.relname) = lower(:table_name)
} {
    # This works for check constraints of the form "check (col_name in ('a', 'b', 'c'))"
    set options {}
    set column_name ""
    while {[regexp {([A-Za-z_]+) = '([^']+)'(.*)$} $rcsrc match key val rcsrc]} {
	lappend options [list $val $val]
	if {$column_name == ""} {
	    set column_name $key
	} elseif {$column_name != $key} {
	    # bail out - this isn't what we think it is
	    set options {}
	    break
	}
    }
    if {[llength $options] > 0} {
	set options_map($key) $options
    }
}

set form_elements ""
set set_values ""
set get_values ""
set code ""

db_foreach get_columns {
    select a.oid,
           a.attname, a.attnotnull, a.atthasdef, a.attnum,
           t.typname, t.typlen
      from pg_attribute a, pg_type t, pg_class c
     where a.attrelid = c.oid
       and a.atttypid = t.oid
       and lower(c.relname) = lower(:table_name)
       and a.attnum > 0
     order by a.attnum
} {
    # Make a nicer looking element name
    set element_name $attname
    set label [string totitle [join [split $attname _]]]

    set widget text
    set datatype text
    set optional ""
    set format ""
    set options ""

    # See if the datatype implies another widget
    if {[info exists widget_map($typname)]} {
	set widget $widget_map($typname)
    }
	
    # See if the datatype implies another form-validation datatype
    if {[info exists datatype_map($typname)]} {
	set datatype $datatype_map($typname)
    }

    # If the not null constraint does not exist, make it optional
    if {$attnotnull == "f"} {
	set optional "-optional"
    } 

    # If we're using the ATS date widget, look up the format 
    if {$widget == "date"} {
	set format "-format \"$date_format_map($typname)\""
    }

    # If the column name ends in "_id", make it a hidden form variable
    # (which won't always be correct; sometimes it might be a foreign
    # key that you want to set with a select widget...this is just a guess.
    if {[regexp {_id$} $attname]} {
	set element_name $attname
	set datatype integer
	set widget hidden
    }

    # If the column has a check constraint with a set of 
    # allowable values, make a select widget
    if {[info exists options_map($attname)]} {
	set widget select
	set options "-options {$options_map($attname)}"
    }

    # If it's a boolean, add "Yes" and "No" options
    # Note: this is not necessarily the best UI choice.  
    # Checkbox and radio elements are also available.
    if {$typname == "bool"} {
	set options "-options {{Yes t} {No f}}"
    }

    # TODO: If I could figure out that this attribute references the
    # primary key of another table, I would like to make a select
    # widget and populate it with a database query.  Unfortunately
    # I don't know how to get that info from postgresql.

    append form_elements "template::element create $form_name $element_name -label \"$label\" -widget $widget -datatype $datatype $optional $format $options\n"

    append set_values "        template::element set_properties $form_name $element_name -value \$$element_name\n"
    append get_values "    set $element_name \[template::element::get_value $form_name $element_name\]\n"

    append insert_columns "$attname, "

    if {$widget == "date"} {
	append get_values "    if {!\[empty_string_p \$$element_name\]} {
	set $element_name \[template::util::date::get_property sql_date \$$element_name\]
    } else {	
	set $element_name NULL
    }
"
	append insert_bind_vars "\$$attname, "
	append update_columns "$attname=\$$attname, "
	append select_columns "to_char($attname, 'YYYY MM DD HH24 MI') as $attname, "
    } else {
	append insert_bind_vars ":$attname, "
	append update_columns "$attname=:$attname, "
	append select_columns "$attname, "
    }
}

if {[info exists insert_columns]} {
    regsub {, $} $insert_columns {} insert_columns
    regsub {, $} $insert_bind_vars {} insert_bind_vars
    regsub {, $} $update_columns {} update_columns
    regsub {, $} $select_columns {} select_columns

    # The magic with the cvs-id below is to prevent CVS from catching this instance
    # and expanding it.

    set user_id [ad_conn user_id]
    if { [empty_string_p $user_id] || $user_id == 0 } {
        set author "formwizard.tcl"
    } else {
        set author [db_string author { select first_names || ' ' || last_name || ' (' || email || ')' from cc_users where user_id = :user_id }]
    }

    set code "
ad_page_contract {
    Add/Edit form for $object_name.
    (Auto-generated by formwizard.tcl)

    @author $author
    @creation-date [ns_fmttime [ns_time] "%B %d, %Y"]
    @cvs-id $Id$
} {
    cancel:optional
    {$primary_key \"\"}
    {return_url \"\"}
}

# If the user hit cancel, ignore everything else
if { \[exists_and_not_null cancel\] } {
    ad_returnredirect \$return_url
    return
}

# Set some common bug-tracker variables
set project_name \[bug_tracker::conn project_name\]
set package_id \[ad_conn package_id\]
set package_key \[ad_conn package_key\]

# TODO: check that the handling of the primary key is okay.  If there is
# no primary key and you're only inserting, you can just ignore it.  
# Add handling for any other incoming URL variables that should become part of the form.

template::form create $form_name

$form_elements
template::element create $form_name insert_or_update -widget hidden -datatype text
template::element create $form_name return_url -widget hidden -datatype text -value \$return_url

if { \[template::form is_request $form_name\] } {

    if {\[empty_string_p \$$primary_key\]} {    
	set insert_or_update insert
	template::element set_properties $form_name insert_or_update -value insert
	# TODO: If the form contains hidden elements that represent 
	# primary keys or foreign keys that were passed to this
	# page as URL parameters, set them here as follows:
	set $primary_key \[db_string get_seq {select nextval('${table_name}_${primary_key}_seq')}\]
	template::element set_properties $form_name $primary_key -value \$$primary_key
    } else {
	set insert_or_update update
	template::element set_properties $form_name insert_or_update -value update
        # Since we're editing a row, get the current values
	# TODO: make sure none of the columns being selected are 
	# clobbering URL variables you added to ad_page_contract!!
	db_1row get_current_values \"
	    select $select_columns
	      from $table_name
	     where $primary_key = :$primary_key
	\"
$set_values

    }
}

set insert_or_update \[template::element::get_value $form_name insert_or_update\]
if {\$insert_or_update == \"insert\"} {
    set page_title \"Adding a new $object_name\"
    set context_bar \[ad_context_bar \"Add $object_name\"\]
} else {
    set page_title \"Editing $object_name \$$primary_key\"
    set context_bar \[ad_context_bar \"Edit $object_name\"\]
}

if { \[template::form is_valid $form_name\] } {
    # valid form submission
$get_values

    if {\$insert_or_update == \"insert\"} {
	if {\[db_0or1row check_exists \"
	    select 1 from $table_name where $primary_key = :$primary_key
        \"\]} {
	    # detected a double form submission - you can return
	    # an error if you want, but it's not really necessary
	} else {
	    db_dml insert_row \"
	        insert into $table_name ($insert_columns)
	        values ($insert_bind_vars)
	    \"
	}
    } else {
	db_dml update_row \"
	    update $table_name
	    set $update_columns
	    where $primary_key = :$primary_key
	\"
    }

    ad_returnredirect \$return_url
    ad_script_abort
}
"
}

set page_title "Form Wizard"

ns_return 200 text/html "
<html>
<head><title>$page_title</title></head>
<body>
<h2>$page_title</h2>
automatically generates code for ATS forms from PostgreSQL data model
<hr>
<form action=formwizard method=get>
<center><table>
<tr><td><b>Table name:</b></td><td><input name=table_name value=\"$table_name\"></td></tr>
<tr><td><b>Object name:</b></td><td><input name=object_name value=\"$object_name\"> <font size=-1>(human-readable name)</font></td></tr>
<tr><td><b>Primary key:</b></td><td><input name=primary_key value=\"$primary_key\"></td></tr>
<tr><td colspan=2 align=center><input type=submit value=\"Run Form Wizard\"></td></tr>
</table></center>
</form>

<script language=\"javascript\">
// <!-- 
function code_copy() {
    field = eval(\"document.code.code\");
    field.focus();
    field.select();
    range = field.createTextRange();
    range.execCommand(\"Copy\");
}
// -->
</script>

<h3>In a textarea for easy copying</h3>

<form name=\"code\">
<textarea name=\"code\" cols=80 rows=10>$code</textarea>
<input type=submit value=\"Copy to clipboard\" onclick=\"javascript:code_copy();\">
</form>

<h3>In the page for easy reading</h3>

<pre>
$code
</pre>

</body>
</html>
"





