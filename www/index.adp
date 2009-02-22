<master>
<property name="title">@page_title@</property>
<property name="context">@context_bar@</property>
<property name="main_navbar_label">freelance_rfqs</property>
<property name="sub_navbar">@project_navbar_html;noquote@</property>
<property name="left_navbar">@left_navbar_html;noquote@</property>

<h2>Available RFQs</h2>

<if @project_id@ eq "">
<table cellspacing=0 cellpadding=1>
	<tr class=rowtitle>
	  <td class=rowtitle align=center>#intranet-freelance-rfqs.Filter_RFQs#</td>
	</tr>
	<tr>
	  <td><formtemplate id="rfq_filters"></formtemplate></td>
	</tr>
</table>
</if>


<table border=0 cellpadding=0 cellspacing=0>
<tr>
  <td> <!-- TD for the left hand filter HTML -->

	<listtemplate name="rfqs_list"></listtemplate>

  </td> <!-- end of left hand filter TD -->
  <td>&nbsp;</td>
  <td valign=top>
<!--
    <table border=0 cellpadding=0 cellspacing=0>
    <tr>
      <td class=rowtitle align=center>
        #intranet-core.Admin_Links#
      </td>
    </tr>
    <tr>
      <td>
	@admin_links;noquote@
      </td>
    </tr>
    </table>
  </td>
-->
</tr>
</table>


<if @view_rfq_p@>
<p>
Explanation:
</p>

<ul>
<li>#intranet-freelance-rfqs.Num_Invitations# - #intranet-freelance-rfqs.Num_Inv_Explanation#
<li>#intranet-freelance-rfqs.Num_Confirmations# - #intranet-freelance-rfqs.Num_Conf_Explanation#
<li>#intranet-freelance-rfqs.Num_Declinations# - #intranet-freelance-rfqs.Num_Decl_Explanation#
<li>#intranet-freelance-rfqs.Num_Remaining# - #intranet-freelance-rfqs.Num_Rem_Explanation#
</ul>
</if>


