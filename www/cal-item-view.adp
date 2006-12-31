<master>
<property name="title">#calendar.Calendar_Item#: @cal_item.name;noquote@</property>
<property name="context">#calendar.Item#</property>
<property name="header_stuff">
  <link href="/resources/calendar/calendar.css" rel="stylesheet" type="text/css">
</property>
<property name="displayed_object_id">@cal_item_id@</property>

<table width="95%">

  <tr>
  <td valign="top" width="150">
  <include src="mini-calendar" base_url="view" view="day" date="@date@">
  </td>	

  <td valign="top"> 
  <table class="cal-table-display">
    <caption>Calendar Event Details</caption>
    <tr>
     <th class="cal-table-data-title">#calendar.Title#</th>
     <td>@cal_item.name@</td>
    </tr>

    <tr>
     <th class="cal-table-data-title">#calendar.Description#:</th>
     <td>@cal_item.description;noquote@</td>
    </tr>

    <tr>
     <th class="cal-table-data-title">#calendar.Sharing#:</th>
     <td>@cal_item.calendar_name@</td>
    </tr>

    <tr>
     <th class="cal-table-data-title">#calendar.Date_1#<if @cal_item.no_time_p@ eq 0> #calendar.and_Time#</if>:</th>
     <td><a href="./view?view=day&date=@cal_item.start_date@">@cal_item.pretty_short_start_date@</a>
     <if @cal_item.no_time_p@ eq 0>, #calendar.from# @cal_item.start_time@ #calendar.to# @cal_item.end_time@</if></td>
    </tr>

    <if @cal_item.item_type@ not nil>
     <tr>
      <th class="cal-table-data-title">#calendar.Type#</th>
      <td>@cal_item.item_type@</td>
     </tr>
    </if>
    
    <if @cal_item.n_attachments@ gt 0>
      <tr>
      <th class="cal-table-data-title">#calendar.Attachments#</th>
      <td>
	<ul>
      <%
        foreach attachment $item_attachments {
        template::adp_puts "<li><a href=\"[lindex $attachment 2]\">[lindex $attachment 1]</a> &nbsp;\[<a href=\"[lindex $attachment 3]\">#attachments.remove#</a>\]</li>"
        }
      %>
	</ul>
      	@attachment_options;noquote@
      </td>
      </tr>
    </if>
  <tr>
    <td colspan="2">
      <if @write_p@ true>
        <a href="cal-item-new?cal_item_id=@cal_item_id@&return_url=@return_url@" class="button">#calendar.edit#</a>
        <a href="./cal-item-delete?cal_item_id=@cal_item_id@&return_url=@return_url@" class="button">#calendar.delete#</a>
	</if>
      <p><a href="ics/@cal_item_id@.ics">#calendar.sync_with_Outlook#</a>
	<if @cal_item.recurrence_id@ not nil>(<a  href="ics/@cal_item_id@.ics?all_occurences_p=1">#calendar.all_events#</a>)</if>
    </td>
  </tr>


</table>
</table>
