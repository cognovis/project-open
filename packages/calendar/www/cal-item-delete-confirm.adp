  <master>
    <property name="title">#calendar.Calendar_Item_Delete#: @cal_item.name;noquote@</property>
    <property name="context">#calendar.Delete#</property>

    <div id="viewadp-mini-calendar">
      <include src="mini-calendar" base_url="view" view="day" date="@date@">
    </div>	

    <div id="viewadp-cal-table" class="margin-form margin-form-div">

      <div class="form-item-wrapper">
        <div class="form-label"><strong>#calendar.Title#</strong></div>
        <div class="form-widget">@cal_item.name@</div>
      </div>

      <if @cal_item.item_type@ not nil>
        <div class="form-item-wrapper">
          <div class="form-label"><strong>#calendar.Type#</strong></div>
          <div class="form-widget">@cal_item.item_type@</div>
        </div>
      </if>

      <div class="form-item-wrapper">
        <div class="form-label">
          <strong>
            #calendar.Date_1#
            <if @cal_item.no_time_p@ eq 0> #calendar.and_Time#</if>:
          </strong>
        </div>
        <div class="form-widget">
          <a href="@view_url@">@cal_item.pretty_short_start_date@</a>
          <if @cal_item.no_time_p@ eq 0>, #calendar.from# @cal_item.start_time@ #calendar.to# @cal_item.end_time@</if>
        </div>
      </div>
      <div class="form-item-wrapper">
        <div class="form-label"><strong>#calendar.Description#</strong></div>
        <div class="form-widget">@cal_item.description@</div>
      </div>

      <div class="form-button">
        <if @cal_item.recurrence_id@ not nil>
          <p>
            <strong>#calendar.lt_This_is_a_repeating_e#</strong>
            #calendar._You_may_choose_to#
          </p>
          <p>
            <a href="@delete_one@" class="button">#calendar.lt_delete_only_this_inst#</a>
            <a href="@delete_all@" class="button">#calendar.lt_delete_all_occurrence#</a>
        </if>
        <else>
          <p>#calendar.lt_Are_you_sure_you_want_1#</p>
          <p>
            <a href="@delete_confirm@" title="#calendar.yes_delete_it#" class="button">#calendar.yes_delete_it#</a>
            <a href="@delete_cancel@" title="#calendar.no_keep_it#" class="button">#calendar.no_keep_it#</a>
          </p>
        </else>
      </div>
    </div>
