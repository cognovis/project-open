<master src="../../../intranet-core/www/master">
<property name="title">@page_title@</property>
<property name="focus">@focus;noquote@</property>
<property name="context">@context;noquote@</property>
<property name="main_navbar_label">finance</property>

<if @message@ not nil>
  <div class="general-message">@message@</div>
</if>

<table cellspacing=1 cellpadding=1 border=0>
<tr>
  <td valign=top>

	    <table cellspacing=1 cellpadding=1 border=0>
	    <tr>
	      <td class=rowtitle align=center>@page_title@</td>
	    </tr>
	    <tr>
	      <td>
	        <formtemplate id="cost"></formtemplate>
	      </td>
	    </tr>
	    </table>
	
  </td>
  <td valign=top>
  <if "" ne @admin_html@>

	    <table cellspacing=1 cellpadding=1 border=0>
	    <tr>
	      <td class=rowtitle align=center>#intranet-cost.Administration#</td>
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
