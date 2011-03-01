<master>
<property name=title>One Survey: @survey_name;noquote@</property>
<property name="context">@context;noquote@</property>

<ul>
<li>Created by: <a href="<%= [acs_community_member_url -user_id $creation_user] %>">@creator_name@</a>
<li>Name: @survey_name@ <font size=-1>[ <a href="name-edit?survey_id=@survey_id@">edit</a> ]</font>
<li>Created: <%= [util_AnsiDatetoPrettyDate $creation_date] %>
<li>Status: @survey_status@ <font size=-1>@toggle_enabled_link;noquote@</font>
<li>Display Type: @display_type@ <font size=-1>@display_type_toggle;noquote@</font>
<li>Responses per user: @survey_response_limit@ <font size=-1>[ <a href="response-limit-toggle?survey_id=@survey_id@">@response_limit_toggle@</a> @response_editable_link;noquote@ ]</font>
<li>Description: @survey_description@ <font size=-1>[ <a href="description-edit?survey_id=@survey_id@">edit</a> ]</font>
<li>Type: @type@
<li>View responses:  <a href="respondents?survey_id=@survey_id@">by user</a> | <a href="responses?survey_id=@survey_id@">summary</a>
@survey_specific_html;noquote@
</ul>
<p>

@questions_summary;noquote@
