<master src="../../master">
<property name="title">@page_title;noquote@</property>

<h2>@page_title@</h2>

<if @invalid_content_type_p@ eq t>
  <em>This is an invalid content type.</em><p>
</if>
<else>
  <if @template_count@ eq 0>
    <em>There are no templates in the clipboard.</em>
  </if>
  <else>
    <formtemplate id="register_templates"></formtemplate>
  </else>
</else>
<p>
