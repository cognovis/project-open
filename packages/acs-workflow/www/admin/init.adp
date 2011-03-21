<master>
<property name="title">Initialize Case</property>
<property name="context">@context;noquote@</property>

<blockquote><em> 

Note! This page is not supposed to be part of the final UI.

<p>

In real life, what will happen is that every time a new ticket (in the ticket-tracker), 
a new application (for a job applicant management application) is created, we automatically initialize 
a business process case for that object.

<p>

Until we make that happen, this is the way to start a new case.  Just
select a random object ... we just use it to tell the user what he's
working on.

</em></blockquote>

<form action=init-2 method=get name="init">
@export_vars;noquote@
<table border=0>

<!--
<tr><th>Context</th><td>
    <select name="context_key">
        <multiple name="contexts">
	    <option value="@contexts.context_key@" @contexts.selected@>@contexts.context_name@</option>
	</multiple>
    </select>
</td></tr>
-->

<tr><th>Object</th><td>
    <select name="object_id">
        <multiple name="objects">
	    <option value="@objects.object_id@">@objects.name@</option>
	</multiple>
    </select>
</td></tr>

<tr><td colspan=2 align=center><input type=submit value="Initialize"></td></tr>

</table>

</form>

</master>