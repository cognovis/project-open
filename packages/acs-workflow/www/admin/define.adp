<master>
<property name="title">#acs-workflow.lt_workflowpretty_nameno#</property>
<property name="context">@context;noquote@</property>




<form action="workflow">
<input type="hidden" name="workflow_key" value="@workflow_key@">
<table width="100%">
<tr>
<td align='left'>
<h1>@wf_name@</h1>
</td>
<td align='right'>
<input type=submit value="Back" >
</td></tr>
</table>
</form>

<table width="100%">
<tr>
<td>
    #acs-workflow.Edit# 
    <multiple name="edit_links">
        (<a href="@edit_links.url@">@edit_links.title@</a>)
    </multiple>
</td>

<td align=right>
    #acs-workflow.Display_#
    <multiple name="format_links">
        <if @format_links.rownum@ ne 1>|</if>
        <if @format_links.selected_p@ eq 1>
            <b>@format_links.title@</b>
        </if>
        <else>
            <a href="@format_links.url@">@format_links.title@</a>
        </else>
    </multiple> ]
</td>
</tr>
</table>

<p>

<if @transition_key@ not nil>
    <include src="define-transition-info" &="workflow" transition_key="@transition_key;noquote@" format="@format;noquote@" mode="@mode;noquote@" return_url="@return_url;noquote@" modifiable_p="@modifiable_p;noquote@">
    <p>
</if>
<if @place_key@ not nil>
    <include src="define-place-info" &="workflow" place_key="@place_key;noquote@" format="@format;noquote@" mode="@mode;noquote@" return_url="@return_url;noquote@" modifiable_p="@modifiable_p;noquote@">
    <p>
</if>

<if @instructions@ not nil>
    <center><font color=red><b>@instructions@</b></font> (<a href="@cancel_url@">#acs-workflow.cancel#</a>)</center><p>
</if>



<center>

<include src="workflow-display" &="workflow" workflow_key="@workflow_key;noquote@" format="@format;noquote@" mode="@mode;noquote@" transition_key="@transition_key;noquote@" place_key="@place_key;noquote@" &="header_stuff" return_url="@return_url;noquote@" modifiable_p="@modifiable_p;noquote@">

<property name="header_stuff">@header_stuff;noquote@</property>

</center>


<p>

</master>

