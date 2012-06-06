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
<td width="100%">
</if>

	<h1>@page_title@</h1>
        <p>#intranet-wall.Description_of_activities#</p>
	
	<form method=post action="/intranet-helpdesk/action">
	<%= [export_form_vars {return_url} ] %>

	
	<table class="list">
	
	    <tr class="list-header">
		<th class="list-narrow">#intranet-wall.User#</th>
		<th class="list-narrow">#intranet-wall.Object#</th>
		<th class="list-narrow">#intranet-wall.Name#</th>
	    </tr>
	
	<multiple name=wall>
		<if @wall.rownum@ odd><tr class="list-odd" valign=top></if> 
		<else><tr class="list-even" valign=top></else>
	
		<td align=center>
			<%= [im_portrait_html $user_id] %>
		</td>
	
		<td align=left>
			<a href=@container_object_url@>@container_object_type_l10n@ @container_object_name@</a> /<br>
			<a href=@specific_object_url@>@specific_object_type_l10n@ @specific_object_name@</a>
		</td>

		<td class="list-narrow">
			@wall.message@
		</td>
	    </tr>
	</multiple>


	</table>
	</form>

<if @show_template_p@>
</td>
</tr>
</table>
</if>



