<master src="@master_src@" />
<property name="party_id">@party_id@</property>
<div id="contact-info">
  <div class="primary">
    <include src="/packages/intranet-contacts/lib/contact-privacy" party_id="@party_id@" />
    <include src="/packages/intranet-contacts/lib/contact-attributes-portlet" party_id="@party_id@" /> <br />
    <include src="/packages/intranet-contacts/lib/contact-relationships-portlet" party_id="@party_id@" sort_by_date_p="1"/>
  </div>
  <div class="secondary">
    <if @dotlrn_club_enabled_p@>
      <h3 class="contact-title"><a href="@club_url@">#intranet-contacts.Visit_Club#</a></h3>
      </if>
    <include
      src="/packages/intranet-contacts/lib/groups-portlet"
      party_id="@party_id@"
      hide_form_p="t" />
      <br />
    <if @tasks_enabled_p@>
      <include
	src="/packages/intranet-contacts/lib/tasks-tasks-portlet"
	object_id="@party_id@"
	hide_form_p="t"
	page_size="15" 
	show_filters_p="0"
        hide_elements="checkbox process_title"/>
	<br />
    </if>
    <include
      src="/packages/intranet-contacts/lib/history-portlet"
      party_id="@party_id@"
      limit="3"
      truncate_len="100"
      size="small"
      recent_on_top_p="1" />
      <br />
    <if @pm_package_id@>
      <include src="/packages/intranet-contacts/lib/projects-portlet"
	orderby=@orderby;noquote@ 
	elements="planned_end_date category_id" 
	package_id=@pm_package_id@ 
	actions_p="1" 
	bulk_p="1" 
	assignee_id="" 
	filter_p="0" 
	base_url="@pm_base_url@" 
	customer_id="@party_id@" 
	status_id="1" 
	fmt="%x %r">
	<br />
    </if>
    <if @projects_enabled_p@>
	<if @freelancer_p@>
		<include src="/packages/intranet-contacts/lib/ap-tasks-portlet"
		    from_party_id="@party_id@"
		    page="@page@"
		    page_size="15"	
		    orderby_p="t"
		    pt_orderby="@pt_orderby@"
		    elements="task_item_id title project_item_id priority slack_time"
		/>
        </if>
    </if>
    <if @projects_enabled_p@>
      <if @project_url@ ne "">
	  <include
	    src="/packages/intranet-contacts/lib/subprojects-portlet"
	    project_item_id="@project_id@"
	    base_url="@base_url@" />
	<br />
      </if>
    </if>
    <if @object_type@ eq "organization">
      <if @invoices_enabled_p@>
	<include src="/packages/intranet-contacts/lib/offers-portlet" 
		organization_id="@party_id@" 
		elements="offer_nr title amount_total" 
		package_id="@iv_package_id@" 
		base_url="@iv_base_url@" />
	<br />

	<include src="/packages/intranet-contacts/lib/projects-billable-portlet" 
		organization_id="@party_id@" 
		elements="project_id title amount_open" 
		package_id="@iv_package_id@" 
		base_url="@iv_base_url@" />
	<br />

	<include src="/packages/intranet-contacts/lib/glossar-list-portlet" 
		owner_id=@party_id@ 
		orderby=@orderby@ 
		customer_id=@party_id@ 
		format=table />
	<br />
      </if>
      <if @projects_enabled_p@>
	<include src="/packages/intranet-contacts/lib/contact-complaint-list-portlet" 
	    customer_id=@party_id@
	    elements="title supplier state description"
	    select_menu="@select_menu;noquote@" />
	<br />

	<include src="/packages/intranet-contacts/lib/customer-group-portlet" 
	    customer_id=@party_id@
	    group_name="Freelancer"
	    elements="name project_name deadline"
	    cgl_orderby=@cgl_orderby;noquote@
	    page=@page@
	>
	<br />

        <include src="/packages/intranet-contacts/lib/pm-tasks-portlet"
		display_mode="list"
		elements="task_item_id title slack_time project_item_id percent_complete"
		is_observer_p="f"
		orderby="title,asc"
		status_id="1"
		party_id=@dotlrn_club_id@
		assign_group_p="1" />
      </if>
    </if>
    <if @update_date@ not nil>
      <p class="last-updated">#intranet-contacts.Last_updated# @update_date@</p>
    </if>
  </div>
</div>
