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


<table cellspacing="1" cellpadding="3">
  <tr class="rowtitle">
    <th colspan="2">Notifications</th>
    <th>Subscribe</th>
  </tr>
  <multiple name="notifications">
    <if @notifications.rownum@ odd>
      <tr class="bt_listing_odd">
    </if>
    <else>
      <tr class="bt_listing_even">
    </else>
      <td align="center" class="bt_listing_narrow">
        <if @notifications.subscribed_p@ true>
          <b>&raquo;</b>
        </if>
        <else>
          &nbsp;
        </else>
      </td>
      <td class="bt_listing">
        @notifications.label@
      </td>
      <td class="bt_listing">
        <if @notifications.subscribed_p@ false>
          <a href="@notifications.url@" title="@notifications.title@">Subscribe</a>
        </if>
	<else>
          <a href="@notifications.url@" title="@notifications.title@">Unsubscribe</a>
	</else>
      </td>
    </tr>
  </multiple>
</table>

<!-- <p><a href="@manage_url@">Manage your notifications</a></p> -->


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


