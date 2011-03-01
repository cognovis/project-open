<!--	
	Displays the basic UI for the calendar
	
	@author Gary Jin (gjin@arsidigta.com)
     	@creation-date Dec 14, 2000
     	@cvs-id $Id: cal-item-create-recurrence.adp,v 1.13 2004/07/12 14:49:55 jeffd Exp $
-->


<master>
<property name="title">#calendar.lt_Calendars_Repeating_E#</property>
<property name="context">#calendar.Repeat#</property>

#calendar.lt_You_are_choosing_to_m#
<p>
<b>#calendar.Date#</b> @cal_item.start_date@<br>
<b>#calendar.Time#</b> @cal_item.start_time@ - @cal_item.end_time@<br>
<b>#calendar.Details#</b> @cal_item.description@
<p>

    <formtemplate id="cal_item"></formtemplate>


