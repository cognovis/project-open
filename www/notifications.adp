<master src="../lib/master">
<property name="title">@page_title;noquote@</property>
<property name="context">@context;noquote@</property>

<table cellspacing="1" cellpadding="3" class="bt_listing">
  <tr class="bt_listing_header">
    <th>Notifications for</th>
    <th>Subscribe</th>
    <th>Unsubscribe</th>
  </tr>
  <multiple name="notifications">
    <if @notifications.rownum@ odd>
      <tr class="bt_listing_odd">
    </if>
    <else>
      <tr class="bt_listing_even">
    </else>
      <td class="bt_listing">
        @notifications.label@
      </td>
      <td class="bt_listing">
        <if @notifications.url_on@ ne "">
          <a href="@notifications.url_on@">Subscribe</a>
        </if>
      </td>
      <td class="bt_listing">
        <if @notifications.url_off@ ne "">
          <a href="@notifications.url_off@">Unsubscribe</a>
        </if>
      </td>
    </tr>
  </multiple>
  <tr>
    
  </td>
</table>

<p>
  <a href="@manage_url@">Manage your notifications</a>
</p>
