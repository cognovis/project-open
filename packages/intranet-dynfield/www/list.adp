<master>
<property name="title">@title@</property>
<property name="context">@context@</property>



<p>
<if @return_url_label@ not nil and @return_url@ not nil>
<a href="@return_url@" class="button">@return_url_label@</a>
</if>
<a href="list-form-preview?list_id=@list_id@" class="button">#intranet-dynfield.Preview_Input_Form#</a>
</p>

<p><strong>#intranet-dynfield.Object_Type#</strong> <a href="object?object_type=@object_type@">@object_type@</a></p>
<p><strong>#intranet-dynfield.List_Name#</strong> @list_name@</p>
<p><strong>#intranet-dynfield.Pretty_Name#</strong> @list_pretty_name@</p>
<p><strong>#intranet-dynfield.List_ID#</strong> @list_id@</p>
<h3>#intranet-dynfield.Mapped_Attributes#</h3>

<listtemplate name="mapped_attributes"></listtemplate>


<h3>#intranet-dynfield.Unmapped_Attributes#</h3>

<listtemplate name="unmapped_attributes"></listtemplate>

<ul class="action-links">
  <li><a href="@create_attribute_url@">#intranet-dynfield.lt_Create_and_map_a_new_#</a></li>
</ul>

