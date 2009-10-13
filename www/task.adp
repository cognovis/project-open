<master>
<property name=title>@task.task_name;noquote@</property>
<property name="context">@context;noquote@</property>

	<div class="component">
		<table width="100%">
		<tr>
		<td>
		<div class="component_header_rounded" >
			<div class="component_header">
				<div class="component_title">Task: @task.task_name@</div>
				      <div class="component_icons"></div>
				</div>
			</div>
		</td>
		</tr>
		<tr>
		<td>
			<div class="component_body">
				<table width="100%">
					<tr>
						<multiple name="panels">
						        <td valign="top">
	    							<include src="@panels.template_url;noquote@" &="task" &="task_attributes_to_set" &="task_assigned_users" &="task_roles_to_assign" &="export_form_vars" &="return_url">
			        			</td>
						</multiple>
					</tr>
				</table>
			 </div>	
		</td></tr>
		</table>
	</div>
<p>

<if @extreme_p@ eq 1> 

        <div class="component">
                <table width="100%">
                <tr>
                <td>
                <div class="component_header_rounded" >
                        <div class="component_header">
                                <div class="component_title">Admin actions:</div>
                                      <div class="component_icons"></div>
                                </div>
                        </div>
                </td>
                </tr>
                <tr>
                <td>
                        <div class="component_body">
				<table class="panel" width="100%">
					<tr><td>
						<ul class="admin_links">
						<multiple name="extreme_actions">
						    <li><a href="@extreme_actions.url@">@extreme_actions.title@</a></li>
						</multiple>
						</ul>
					</td></tr>
				</table>
                         </div>
                </td></tr>
                </table>
        </div>
</if>

<p>

<include src="journal" case_id="@case_id;noquote@">

</master>
