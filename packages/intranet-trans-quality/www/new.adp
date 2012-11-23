<!-- /packages/intranet-trans-quality/www/new.adp -->
<!-- @author Frank Bergmann (frank.bergmann@project-open.com) -->

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
<master src="../../intranet-core/www/master">
<property name="title">@page_title@</property>
<property name="context">@context_bar@</property>


<table border=0 cellspacing=2 cellpadding=2>
<tr valign=top>
  <td>

<if @form_mode@ eq "display">

    <form action=new method=POST>
    <%= [export_form_vars task_id report_id return_url] %>
    <input type=hidden name=form_mode value="edit">

</if> <else>

    <form action=new-2 method=POST>
    <%= [export_form_vars task_id report_id expected_quality_id project_id return_url] %>

</else>


	<table border=0 cellspacing=1 cellpadding=1>
	<tr>
	  <td colspan=2 class=rowtitle align=center>Review</td>
	</tr>
	<tr class=roweven>
	  <td>QC Reviewer</td>
	  <td>@current_user_name@</td>
	</tr>
	<tr class=rowodd>
	  <td>Date</td>
	  <td>
<if @form_mode@ eq "display">
	    @report_date@
</if> <else>
	    <input type=text name=report_date value="@report_date@">
</else>
	  </td>
	</tr>
	<tr class=roweven>
	  <td>Sample Size</td>
	  <td>
<if @form_mode@ eq "display">
	    @sample_size@
</if> <else>
	    <input type=text name=sample_size value="@sample_size@"
</else>
	  </td>
	</tr>
	<!--
	<tr>
	  <td>Max. errors allowed</td>
	  <td>max_errors</td>
	</tr>
	-->
	</table>

	<br>

	@errors_html;noquote@

<if @add_trans_quality_p@>

    <if @form_mode@ eq "display">
        <input type=submit name=submit value="Edit Report">
    </if> <else>
        <input type=submit name=submit value="Submit Report">
    </else>

</if>

    </form>


  </td>
  <td>

<table cellpadding=5 cellspacing=0 border=0 width='100%'>
  <tr>
    <td class=tableheader>Context</td>
  </tr>
  <tr>
    <td class=tablebody>

	<table border=0 cellspacing=1 cellpadding=1>
	<tr>
	  <td colspan=2 class=rowtitle align=center>Project</td>
	</tr>
	<tr class=roweven>
	  <td>Project Name</td>
	  <td>
	    <A href=/intranet/projects/view?project_id=@project_id@>
	      @project_name@
	    </a>
	  </td>
	</tr>
	<tr class=rowodd>
	  <td>Project Nr</td>
	  <td>
	    <A href=/intranet/projects/view?project_id=@project_id@>
	      @project_nr@
	    </a>
	  </td>
	</tr>
	<tr class=roweven>
	  <td>Customer Name</td>
	  <td>
	    <A href=/intranet/companies/view?company_id=@company_id@>
	      @company_name@
	  </td>
	</tr>
	<tr class=rowodd>
	  <td>Project Manager</td>
	  <td>@manager_name@</td>
	</tr>
	<tr class=roweven>
	  <td>Source/Target Language</td>
	  <td>@source_language@ / @target_language@</td>
	</tr>
	<tr class=rowodd>
	  <td>Quality Level</td>
	  <td>@expected_quality@</td>
	</tr>
	</table>


<br>

	<table border=0 cellspacing=1 cellpadding=1>
	<tr>
	  <td colspan=2 class=rowtitle align=center>Task</td>
	</tr>
	<tr class=roweven>
	  <td>Task Name</td>
	  <td>
		@task_name@
	  </td>
	</tr>
	<tr class=rowodd>
	  <td>Task Filename</td>
	  <td>
		@task_filename@
	  </td>
	</tr>
	<tr class=roweven>
	  <td>Task Type</td>
	  <td>
		@task_type@
	  </td>
	</tr>
	<tr class=rowodd>
	  <td>Task Status</td>
	  <td>
		@task_status@
	  </td>
	</tr>
	<tr class=roweven>
	  <td>Translator</td>
	  <td>
 	    <a href=@view_user_url@?user_id=@trans_id@>
	      @translator_name@
	    </a>
	  </td>
	</tr>
	<tr class=rowodd>
	  <td>Editor</td>
	  <td>
 	    <a href=@view_user_url@?user_id=@edit_id@>
		@editor_name@
	    </a>
	  </td>
	</tr>
	<tr class=roweven>
	  <td>Proof Reader</td>
	  <td>
 	    <a href=@view_user_url@?user_id=@proof_id@>
		@proofer_name@
	    </a>
	  </td>
	</tr>
	<tr class=rowodd>
	  <td>Other</td>
	  <td>
 	    <a href=@view_user_url@?user_id=@other_id@>
		@other_name@
	    </a>
	  </td>
	</tr>
	</table>

    </td>
  </tr>
</table>





  </td>
</tr>
</table>


