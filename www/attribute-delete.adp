<master>

<property name="title">@title@</property>
<property name="context">@context@</property>


#flexbase.Warning#!!!!!

@html_warning;no_quote@

<br/>
#flexbase.Do_you_want_continue#? <a href="?<%= [export_vars -url -override {{continue_p 1}} {return_url object_type continue_p attribute_ids}]%>"> #flexbase.Yes#</a>
								 <a href="@return_url;noquote@"> #flexbase.No#</a>