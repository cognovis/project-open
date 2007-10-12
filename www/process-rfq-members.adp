<master>
<property name=title>@page_title@</property>
<property name="context">@context;noquote@</property>
<property name="main_navbar_label">user</property>

<br>
@project_menu;noquote@

<H2>@page_title@</H2>

<form method="POST" action="process-rfq-members-2">
@export_vars;noquote@

<table width="600" cellspacing=1 cellpadding=1>

	<tr>
		<td colspan=2>
			#intranet-freelance-rfqs.Available_Variables#
			<br>&nbsp;<br>
		</td>
	</tr>
	<tr class=rowtitle>
		<td class=rowtitle colspan=2 align=center>@rfq_name@</td>
	</tr>
	<tr class=form-element>
		<td class=form-label>#intranet-freelance-rfqs.Header#</td>
		<td class=form-widget>
			<textarea name=email_header rows=1 cols=70 wrap="<%=[im_html_textarea_wrap]%>">@email_header@</textarea>
		</td>
	</tr>
	<tr>
		<td class=form-label>#intranet-freelance-rfqs.Body#</td>
		<td class=form-widget>
			<textarea name=email_body rows=10 cols=70 wrap="<%=[im_html_textarea_wrap]%>">@email_body@</textarea>
		</td>
	</tr>
<!--	<tr>
		<td class=form-label>
			<nobr><%= [lang::message::lookup "" intranet-freelance-rfqs.Send_Invitations "Send Invitations?"] %></nobr>
		</td>
		<td class=form-widget>
			<input type=checkbox name=send_out_invitations_p value=1>
		</td>
	</tr> -->
	<tr>
		<td class=form-label>
			<nobr><%= [lang::message::lookup "" intranet-freelance-rfqs.Add_to_Project "Add to project?"] %></nobr>
		</td>
		<td class=form-widget>
			<input type=checkbox name=add_to_project_p value=1 @add_to_project_checked@>
		</td>
	</tr>
	<tr>
		<td class=form-label>
			<nobr><%= [lang::message::lookup "" intranet-freelance-rfqs.Send_me_a_copy "Send me a copy"] %></nobr>
		</td>
		<td class=form-widget>
			<input type=checkbox name=send_me_a_copy_p value=1>
		</td>
	</tr>
	<tr>
		<td class=form-label></td>
		<td class=form-widget>
			<input type="submit" name=email_send value="#intranet-freelance-rfqs.Send_Invitations#" />
			<input type="submit" name=email_nosend value="#intranet-freelance-rfqs.Dont_Send_Invitations#" />
		</td>
	</tr>
</table>
</form>
</p>



