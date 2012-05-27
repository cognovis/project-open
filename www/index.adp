<if @show_template_p@>
<master>
<property name="title">@page_title@</property>
<property name="context_bar">@context_bar@</property>
<property name="sub_navbar">@wall_navbar_html;noquote@</property>
</if>

<script type="text/javascript">
Thumbs_up_pale = new Image();
Thumbs_up_pale.src = "@thumbs_up_pale_24_gif;noquote@";
Thumbs_up_pressed = new Image();
Thumbs_up_pressed.src = "@thumbs_up_pressed_24_gif;noquote@";

function thumbs_change (name, object) {
  window.document.images[name].src = object.src;
}
</script>

<if @show_template_p@>
<table>
<tr valign=top>
<td width="60%">
</if>

	<h1>@page_title@</h1>
        <p>#intranet-wall-management.Description_of_activities#</p>
	
	<form method=post action="/intranet-helpdesk/action">
	<%= [export_form_vars {return_url} ] %>

	
	<table class="list">
	
	    <tr class="list-header">
		<if @user_is_admin_p@>
		<th class="list-narrow" align=center>
			<input type=checkbox name="_dummy" onclick="acs_ListCheckAll('wall_list', this.checked)" title="Check/uncheck all rows">
		</th>
		</if>
		<th class="list-narrow">#intranet-wall-management.Votes#</th>
		<th class="list-narrow">#intranet-wall-management.Name#</th>
	    </tr>
	
	<multiple name=wall>
	    <if @wall.rownum@ odd><tr class="list-odd" valign=top></if> 
	    <else><tr class="list-even" valign=top></else>
	
		<if @user_is_admin_p@>
		<td class="list-narrow">
			<input type=checkbox name=tid value=@wall.wall_id@ id='ticket,@wall.wall_id@'>
		</td>
		</if>
	
		<td align=center>
			<div style="width: 50px; height: 35px;	border: solid 1px #ccc; -moz-border-radius: 5px; -webkit-border-radius: 5px; border-radius: 5px; text-align: center">
			<div style="color: #333; margin-bottom: -0.1em; letter-spacing: -1px; font-weight: bold; font-size: 200%">
			<if "" ne @wall.thumbs_up_count@>
			@wall.thumbs_up_count@
			</div>
			<if 1 eq @wall.thumbs_up_count@>#intranet-wall-management.Thumb#</if>
			<else>#intranet-wall-management.Thumbs#</else>
			</div>
			</if>
	
			<if "up" eq @wall.thumbs_direction@>
			<a href="@wall.thumbs_undo_url;noquote@" onmouseover="thumbs_change('thumbs_@wall.rownum@', Thumbs_up_pale)" onmouseout="thumbs_change('thumbs_@wall.rownum@', Thumbs_up_pressed)">
				<img src="@thumbs_up_pressed_24_gif;noquote@" name="thumbs_@wall.rownum@" title="#intranet-wall-management.Press_here_to_redraw_your_vote_for_this_wall#" border='0' style='margin-top:3px'></a><br>
			</if>
			<else>
			<a href="@wall.thumbs_up_url;noquote@" onmouseover="thumbs_change('thumbs_@wall.rownum@', Thumbs_up_pressed)" onmouseout="thumbs_change('thumbs_@wall.rownum@', Thumbs_up_pale)">
				<img src="@thumbs_up_pale_24_gif;noquote@" name="thumbs_@wall.rownum@" title="#intranet-wall-management.Press_here_to_vote_for_this_wall#" border='0' style='margin-top:3px'></a><br>
			</else>
	
		</td>
	
		<td class="list-narrow">
			<a href="@wall.wall_url;noquote@">@wall.project_name@</a>
			<br>
			@wall.wall_description;noquote@
			<br>
			#intranet-wall-management.From#: <a href="@wall.creator_url;noquote@">@wall.creator_name@</a>
			|
			<a href="@wall.wall_url;noquote@">
			@wall.comment_count@ 
			<if @wall.comment_count@ eq 1>#intranet-wall-management.Comment#</if>
			<else>#intranet-wall-management.Comments#</else></a>
			| 
			<if @wall.comment_count@>
			</if>
			#intranet-wall-management.Status#: @wall.ticket_status@
			|
			#intranet-wall-management.Type#: @wall.ticket_type@
			|
			<a href="@wall.comments_url;noquote@"
			><%= [im_gif comments [lang::message::lookup "" intranet-wall-management.Comment_on_wall "Comment on wall"]] 
			%></a>
			|
			<a href="@wall.dollar_url;noquote@"
			><%= [im_gif money_dollar [lang::message::lookup "" intranet-wall-management.Share_development_costs "Share development costs"]] 
			%></a>
	
		</td>
	    </tr>
	</multiple>


<if @ticket_bulk_actions_p@>
	<tfoot>
	<tr valign=top>
	  <td align=left colspan=3 valign=top>
		<%= [im_category_select \
			     -translate_p 1 \
			     -package_key "intranet-helpdesk" \
			     -plain_p 1 \
			     -include_empty_p 1 \
			     -include_empty_name "" \
			     "Intranet Ticket Action" \
			     action_id \
			]
		%>
		<input type=submit value='#intranet-helpdesk.Update_Tickets#'>
	  </td>
	</tr>
	</tfoot>
</if>

	</table>
	</form>


<if @show_template_p@>
</td>
<td align=left width="40%">
</if>

	<if @survey_count@></if>
	<else>
	<h1>#intranet-wall-management.Increase_the_Weight_of_your_Votes#</h1>
	#intranet-wall-management.You_havent_yet_filled_our_one_of_the_following_surveys#.<br>
	#intranet-wall-management.Filling_out_the_survey_will_increase_the_weight_of_your_votes#:<br>
	&nbsp;

	<ul>
	<li>Are you a potential ]po[ user?<br>
		Then please take the <a href="/simple-survey/one?return_url=&survey_id=438275">Potential User Feedback</a>
		<br>&nbsp;
	<li>Are you a productive ]po[ user?<br>
		Then please take the <a href="/simple-survey/one?return_url=&survey_id=438249">Productive User Feedback</a>
		<br>&nbsp;
	<li>Are you a ]po[ partner? <br>
		Then please take the <a href="/simple-survey/one?return_url=&survey_id=305439">Partner Survey</a>.
		<br>&nbsp;
	</ul>
	</else>

	<h1>Create a new Wall</h1>
	<p>
	#intranet-wall-management.Please_check_for_duplicate_wall#
	</p>
	<form action="/intranet-wall-management/wall-new" method=POST>
	<%= [export_form_vars return_url] %>
	<table width="100%">
	<tr class=rowodd>
	<td>#intranet-wall-management.Title#:</td>
	<td><input type=text size=40 name=wall_title value="#intranet-wall-management.Catchy_phrase_for_your_wall#"></td>
	</tr>
	<tr class=roweven>
	<td>#intranet-wall-management.Description#:</td>
	<td><textarea name=wall_description cols=30 rows=3>#intranet-wall-management.One_or_two_paragraphs_to_describe_your_wall#</textarea></td>
	</tr>
	<tr class=rowodd>
	<td>#intranet-wall-management.Submit#:</td>
	<td><input type=submit></td>
	</tr>
	</table>
	</form>


<if @show_template_p@>
</td>
</tr>
</table>
</if>



