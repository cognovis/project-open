<master>
<property name="title">#calendar.Calendar_Item#: @cal_item.name;noquote@</property>
<property name="context">#calendar.Item#</property>
<property name="displayed_object_id">@cal_item_id@</property>




<div id="viewadp-mini-calendar">
  <include src="mini-calendar" base_url="view" view="day" date="@date@">
  <include src="cal-options">	
</div>	

<div id="viewadp-cal-table" class="margin-form margin-form-div">
		
		<h1>#calendar.calendar_event_details#</h1>
		
		<div class="form-item-wrapper">
			<div class="form-label">
				<strong>#calendar.Title#</strong>
			</div>
			<div class="form-widget">                  
				@cal_item.name@
			</div>	  
		</div>
                <if @cal_item.description@ not nil>
		  <div class="form-item-wrapper">
			<div class="form-label">
				<strong>#calendar.Description#:</strong>
			</div>
			<div class="form-widget">                  
				@cal_item.description;noquote@
			</div>  
		  </div>
                </if>
                <if @cal_item.related_link_url@ not nil>
		  <div class="form-item-wrapper">
                    <div class="form-label">
                      <strong>#calendar.RelatedLink#:</strong>
                    </div>
                    <div class="form-widget">                  
                      <a href="@cal_item.related_link_url;noquote@" title="@cal_item.related_link_text@">
                        @cal_item.related_link_text@
                      </a>
                    </div>  
                  </div>
                </if>
		<div class="form-item-wrapper">
			<div class="form-label">
				<strong>#calendar.Sharing#:</strong>
			</div>
			<div class="form-widget">                  
				@cal_item.calendar_name@
			</div>  
		</div>
		<div class="form-item-wrapper">
			<div class="form-label">
				<strong>#calendar.Date_1#<if @cal_item.no_time_p@ eq 0> #calendar.and_Time#</if>:</strong>
			</div>
			<div class="form-widget">                  
				<a href="@goto_date_url@" title="#calendar.goto_cal_item_start_date#">@cal_item.pretty_short_start_date@</a>
			    <if @cal_item.no_time_p@ eq 0>, #calendar.from# @cal_item.start_time@ #calendar.to# @cal_item.end_time@</if>
			</div>  
		</div>
		
		<if @cal_item.item_type@ not nil>
			<div class="form-item-wrapper">
				<div class="form-label">
					<strong>#calendar.Type#</strong>
				</div>
				<div class="form-widget">                  
					@cal_item.item_type@
				</div>  
			</div>
		</if>
		
		<if @cal_item.n_attachments@ gt 0>
			<div class="form-item-wrapper">
				<div class="form-label">
					<strong>#calendar.Attachments#</strong>
				</div>
				<div class="form-widget">                  
					<ul>
						<%
						foreach attachment $item_attachments {
							template::adp_puts "<li><img src=\"/resources/acs-subsite/attach.png\"><a href=\"[lindex $attachment 2]\">[lindex $attachment 1]</a> &nbsp;\[<a href=\"[lindex $attachment 3]\">#attachments.remove#</a>\]</li>"
						}
						%>
					</ul>
					<!-- @attachment_options;noquote@ -->
				</div>  
			</div>
		</if>
		
		<div class="form-button">
			<if @write_p@ true>
		        <a href="@cal_item_new_url@" title="#calendar.edit#" class="button">#calendar.edit#</a>
		        <a href="@cal_item_delete_url@" title="#calendar.delete#" class="button">#calendar.delete#</a>
				@attachment_options;noquote@ 
			 	<a href="ics/@cal_item_id@.ics" title="#calendar.sync_with_Outlook#" class="button">#calendar.sync_with_Outlook#</a>
				<if @cal_item.recurrence_id@ not nil>(<a href="ics/@cal_item_id@.ics?all_occurences_p=1" title="#calendar.all_events#">#calendar.all_events#</a>)</if>
		
			</if>
		</div>
</div>
