<master src="master">
<property name="title">@title@</property>
<property name="context">@context@</property>
<property name="left_navbar">@left_navbar_html;noquote@</property>

<%= [im_box_header "DynField Base Information"] %>
<formtemplate id="attribute_form"></formtemplate>
<%= [im_box_footer] %>
<br>&nbsp;<br>


<if @form_mode@ eq "display">

<%= [im_box_header "DynField Permissions"] %>
<p>
These permissions define which user profiles have the right to:
<ul>
<li>read (<a href=''>r</a>=No read permission, <b><a href=''>R</a></b>=Read permission) and
<li>write (<a href=''>w</a>=No write permission, <b><a href=''>W</a></b>=Write permission)
</ul>
<br>
the DynField.
<p>
Please click on the 'r', 'R', 'w' or 'W' letters to toggle read/write permissions
</p>
<br>
@perm_html;noquote@
<%= [im_box_footer] %>
<br>&nbsp;<br>


<%= [im_box_header "DynField Object Mapping"] %>
<p>
This mapping defines whether a DynField will 'appear' in a specific object type.<br>
</p>
@map_html;noquote@
<%= [im_box_footer] %>
<br>&nbsp;<br>

</if>



