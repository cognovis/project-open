# File: /www/intranet/allocations/note-edit.tcl

ad_page_contract {
    Lets you edit an allocation note
    
    @param allocation_note_start_block
    @param start_block :optional
    @param end_block : optional
    
    @author Mike Bryzek (mbryzek@arsdigita.com)
    @creation-date Jan 2000
    @cvs-id note-edit.tcl,v 3.6.6.6 2000/09/22 01:38:26 kevin Exp
} {
    allocation_note_start_block:notnull
    start_block:optional
    end_block:optional 
}


set note [db_string allocation_note "select note from im_start_blocks
where start_block = :allocation_note_start_block"]

set page_title  "Edit note for $allocation_note_start_block"
set context_bar "[im_context_bar [list "index.tcl" "Project allocations"] "Edit note"]"

set page_content " 
<form action=note-edit-2 method=post>
[export_form_vars start_block end_block allocation_note_start_block]
<table>
<th valign=top>Note:</th> 
<td><textarea name=note cols=50 rows=5>[ns_quotehtml $note]</textarea></td>
</tr>
</table>
<center>
<input type=submit name=submit value=Submit>
</center>
</form>
<p>
"



doc_return  200 text/html [im_return_template]

