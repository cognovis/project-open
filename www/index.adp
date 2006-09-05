<master src="../../intranet-core/www/master">
<property name="title">Workflow Home</property>
<property name="main_navbar_label">workflow</property>


<table cellspacing=0 cellpadding=0>
<tr valign=top>
  <td>
    @content;noquote@
  </td>
  <td>&nbsp;</td>
  <td>

<if @admin_html@ ne "">
    <table border=0 cellpadding=1 cellspacing=2>
    <tr>
      <td class=rowtitle align=center>
	#intranet-workflow.Admin_workflows#
      </td>
    </tr>
    <tr>
      <td>
        @admin_html;noquote@
      </td>
    </tr>
    </table>
</if>

  </td>
</tr>
</table>


