<!-- This page goes into /packages/apm-tcl/lib/page-error.adp -->
<master>
<property name="title">#acs-tcl.Server#</property>


<p>
<if @top_message@ not nil>
	@top_message;noquote@
</if>
<else>
  #acs-tcl.There#
</else>
</p>


<% set error_url [im_url_with_query] %>
<% set error_location "[ns_info address] on [ns_info platform]" %>
<% set report_url [ad_parameter -package_id [im_package_core_id] "ErrorReportURL" "" ""] %>
<% set system_url [ad_parameter -package_id [ad_acs_kernel_id] SystemURL "" ""] %>
<% set first_names "undefined" %>
<% set last_name "undefined" %>
<% set email "undefined" %>
<% set username "undefined" %>
<% db_0or1row user_info "select * from cc_users where user_id=[ad_get_user_id]" %>
<% set publisher_name [ad_parameter -package_id [ad_acs_kernel_id] PublisherName "" ""] %>
<% set package_versions [db_list package_versions "select v.package_key||':'||v.version_name from (select max(version_id) as version_id, package_key from apm_package_versions group by package_key) m, apm_package_versions v where m.version_id = v.version_id"] %>
<% set system_id [im_system_id] %>
<% set hardware_id [im_hardware_id] %>
<% if {![info exists error_content]} { set error_content "" } %>
<% if {![info exists error_content_filename]} { set error_content_filename "" } %>
<% if {![info exists error_type]} { set error_type "default" } %>
<% if {![info exists top_message]} { set top_message "" } %>
<% if {![info exists bottom_message]} { set bottom_message "" } %>

<br>
<form action="@report_url;noquote@" method=POST>
<input type=submit name=submit value="Report this Error">
<br>
<input type=checkbox name=privacy_statement_p checked>
I agree with the <a href="http://www.project-open.com/en/company/project-open-privacy.html">privacy statement</a>.
<br>
<input type=hidden name=error_url value=@error_url@>
<input type=hidden name=error_location value=@error_location@>
<input type=hidden name=system_url value=@system_url@>
<input type=hidden name=error_first_names value=@first_names;noquote@>
<input type=hidden name=error_last_name value=@last_name;noquote@>
<input type=hidden name=error_user_email value=@email;noquote@>
<input type=hidden name=error_type value=@error_type;noquote@>
<input type=hidden name=package_versions value="@package_versions;noquote@">
<input type=hidden name=publisher_name value="@publisher_name;noquote@">
<input type=hidden name=system_id value=@system_id@>
<input type=hidden name=hardware_id value=@hardware_id@>
<if @message@ not nil>
  <input type=hidden name=error_message value="@message;noquote@">
</if>
<if @stacktrace@ not nil>
  <input type=hidden name=error_info value="@stacktrace@">
</if>
<input type=hidden name=error_content value='@error_content@'>
<input type=hidden name=error_content_filename value='@error_content_filename@'>
</form>
<br>

<if @bottom_message@ not nil>
	@bottom_message;noquote@
</if>

<if @message@ not nil>
  <p>
    @message;noquote@
  </p>
</if>

<if @stacktrace@ not nil>

  <p>
    Here is a detailed dump of what took place at the time of the error, which may assist a programmer in tracking down the problem:
  </p>

  <blockquote><pre>@stacktrace@</pre></blockquote>
</if>
<else>
  <p>
    The error has been logged and will be investigated by our system programmers.
  </p>
</else>




