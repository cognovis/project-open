<master>
  <property name="title">@title@</property>
  <property name="header_stuff">@header_stuff@</property>
  <property name="context">@context@</property>
  <property name="focus">@focus@</property>

<hr />
<include src="footer" edit_link_p="@edit_link_p@" admin_p="@admin_p@" folder_id="@folder_id@" >
<hr />
  
<h1>@title@</h1>
  
@content;noquote@

<if @related_items:rowcount@ gt 0>
Pages that link to his page:
<ul>
<multiple name="related_items">
  <li><a href="@related_items.name@">@related_items.title@</a>
</multiple>
</ul>
</if>

<hr />
<include src="footer" edit_link_p="@edit_link_p@" admin_p="@admin_p@" folder_id="@folder_id@">
<hr />
