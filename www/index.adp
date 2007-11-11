<master src="../../intranet-core/www/master">
<property name="context">@context;noquote@</property>
<property name="title">@page_title@</property>
<property name="main_navbar_label">reporting</property>


<table cellspacing=0 cellpadding=0 width="100%">
    <tr valign=top>
	<td width="50%">
	<listtemplate name="report_list"></listtemplate>
	</td>

<if @user_admin_p@>
	<td width="50%">

	<table>
	<tr class=rowtitle>
	<td class=rowtitle>Admin Reports</td>
	</tr>
	<tr>
	<td>
		<ul>
		<li><a href=new>Add a new Indicator</a>
		</ul>
	</td>
	</tr>
	</table>


	</td>
</if>

    </tr>
</table>


