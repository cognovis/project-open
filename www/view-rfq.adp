<master>
<property name="title">@page_title@</property>
<property name="context_bar">@context_bar;noquote@</property>
<property name="main_navbar_label">projects</property>
<!-- <property name="focus">@focus;noquote@</property> -->


<br>
@project_menu;noquote@


<if @message@ not nil>
  <div class="general-message">@message@</div>
</if>


<table cellspacing=2 cellpadding=2>
<tr valign=top>
<td width="50%">
	<h2>@page_title@</h2>


	<table cellspacing=0 cellpadding=1>
		<tr class=rowtitle>
		  <td class=rowtitle align=center>#intranet-freelance-rfqs.RFQ_Base_Data#</td>
		</tr>
		<tr>
		  <td><formtemplate id="@form_id@"></formtemplate></td>
		</tr>
	</table>


</td>
<td width="50%">
	<h2><%= [lang::message::lookup "" intranet-freelance-rfqs.Required_RFQ_Skills "Required RFQ Skills"] %></h2>
	<listtemplate name="skill_list"></listtemplate>
	
	<br>

	<form action=add-rfq-skills method=POST>
	<%= [export_form_vars rfq_id] %>
	<input type=hidden name=return_url value="@return_url2;noquote@">
	<table>
	<tr>
	  <td colspan=4 class=rowtitle align=center>
	    <%= [lang::message::lookup "" intranet-freelance-rfqs.Add_Required_Skills "Add Required Skills"] %>
	  </td>
	</tr>
	<tr>
	  <td class=rowtitle align=center>
	    <%= [lang::message::lookup "" intranet-freelance-rfqs.Skill_Type "Skill Type"] %>
	  </td>
	  <td class=rowtitle align=center>
	    <%= [lang::message::lookup "" intranet-freelance-rfqs.Skill "Skill"] %>
	  </td>
	  <td class=rowtitle align=center>
	    <%= [lang::message::lookup "" intranet-freelance-rfqs.Minimum_Skill_Level "Min. Level"] %>
	  </td>
	  <td class=rowtitle align=center>
	    <%= [lang::message::lookup "" intranet-freelance-rfqs.Skill_Weight "Skill Weight"] %>
	  </td>
	</tr>
	@add_skill_trs;noquote@
	<tr>
	  <td></td>
	  <td colspan=2>
	    <input type=submit value='<%= [lang::message::lookup "" intranet-freelance-rfqs.Add_Required_Skills "Add Required Skills"] %>'>
	  </td>
	</tr>
	</table>
	</form>

</td>
</tr>
</table>



<h2><%= [lang::message::lookup "" intranet-freelance-rfqs.RFQ_Candidates "RFQ Candidates"] %></h2>
<listtemplate name="candidate_list"></listtemplate>

