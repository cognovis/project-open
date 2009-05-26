# -----------------------------------------------------
# notes02.tcl
#
# (c) 2009 ]project-open[
# Licensed under the GPL 2.0 or higher
# -----------------------------------------------------


# Please check "TCL for Web Nerds" if you have any questions
# concerning the TCL syntax: http://philip.greenspun.com/tcl/


# -----------------------------------------------------
# The "Page Contract":
#
# ad_page_contract comment parameters
#	The "ad_page_contract" acts similar to a procedure 
#	definition in procedural languages such PHP or Java.
#	The command extracts extracts HTTP parameters from 
#	the URL ("GET method") or the HTTP request form 
#	("POST method") and maps them into local variables.
#	In this example, the form below includes a field
#	"new_note". 
#	Thanks to the ad_page_contract,	the value of "new_note" 
#	becomes available as a local variable that we can
#	use in the rest of this page.
#
ad_page_contract {
    Notes02 Tutorial
    @param new_note - Value for a new note.
    @author frank.bergmann@project-open.com
} {
    new_note:optional
}


# -----------------------------------------------------
# Create the database table "notes02".
# The table contains just a single text filed for 
# storing the note...
#
# catch {...}
#	We put a "catch {...}" around the DB statement so that
#	we won't get an error creating the table if the table
#	already exists (when we run the page a 2nd time...).
#
# db_dml label sql
#	"db_dml" executes a database statement that doesn't
#	return values. The "label" argument is just a name
#	for the SQL statement for debugging and other 
#	purposes. The SQL statement is delimited by
#	double quotes. It's OK to span several lines.
#	
catch {
    db_dml lable01 "
	create table notes02 (
		note		text
	)
    "
}



# -----------------------------------------------------
# Save values for creating a new note.
# This piece is executed AFTER the user has pressed the
# "Create New Note" button, so this code is executed 
# after the user has pressed the button.
#
if {[info exists new_note]} {
    db_dml lable01 "
	insert into notes02 (
		note
	) values (
		:new_note
	)
    "
}



# -----------------------------------------------------
# Let's display the contents of the notes02 table.
#
# db_foreach label sql code_block
#	Runs the sql statement and executes the
#	code_block for every row returned from the
#	database.
#	Columns pulled out of the DB are mapped 
#	into local variables which you can use 
#	directly in your code.
#	In the example below, the table column 
#	"note" is pulled out of the DB and used
#	in "...<td>$note</td>...".
#
set notes_sql "
	select	note
	from	notes02
"

set table_html ""
db_foreach label02 $notes_sql {
    append table_html "<tr><td>$note</td></tr>\n"
}

set table_html "
	<table>
	$table_html
	</table>
"



# -----------------------------------------------------
# Create a form to add a new note
#
set form_html "
	<form action='notes02' method='GET'>
	<input type='text' name='new_note'>
	<input type='submit' value='Create New Note'>
	</form>
"


# -----------------------------------------------------
# Let's put the pieces together and return the HTML.
#
doc_return 200 "text/html" "
<h1>Notes02</h1>
$table_html
$form_html
"

