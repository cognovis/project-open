<master src="../../intranet-core/www/po-master">
<property name="context">@context;noquote@</property>
<property name="title">@page_title@</property>
<property name="main_navbar_label">indicators</property>
<property name="header_stuff">
   <script language="JavaScript" type="text/javascript" src="/resources/diagram/diagram/diagram.js"></script>
</property>

<table cellspacing=0 cellpadding=0 width="100%">
    <tr valign=top>
	<td width="50%">

	</td>

<if @user_admin_p@>
	<td width="60%">

	<table>
	<tr class=rowtitle>
	<td class=rowtitle>Admin Reports</td>
	</tr>
	<tr>
	<td>
		<ul>
<if @add_reports_p@>
		<li><a href=new>Add a new Indicator</a>
</if>
<!--
		<li><a href=compare>Compare yourself with other companies</a>
-->
		</ul>
	</td>
	</tr>
	</table>


	</td>
</if>

    </tr>
</table>



<listtemplate name="report_list"></listtemplate>
