<if @calendars:rowcount@ gt 0>
<p>
#calendar.Calendars#:
<ul>
<multiple name="calendars">
<li> @calendars.calendar_name@
<if @calendars.calendar_admin_p@ true>
  <br>
  <font size=-2>[<a href="@base_url@calendar-item-types?calendar_id=@calendars.calendar_id@">Manage Types</a>]</font>
</if>
</multiple>
</ul>
</if>

<p>

