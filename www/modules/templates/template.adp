<master src="../../master">
<property name="title">Content Template</property>

<table border=0 width="95%">
<tr>

<td align=left><b>
  <multiple name=context>
    <a href="../sitemap/index?id=@context.context_id@">
      <img src="../../resources/folder.gif" border=0>
    </a>
    <a href="../sitemap/index?id=@context.context_id@">@context.title@</a>
    <if @context.rownum@ lt @context:rowcount@> : </if>
  </multiple>
</b></td>
<td align=right><b><tt>@path@</tt></b></td>
</table>


<p>

<if @items:rowcount@ eq 0>
  <i>This template is not registered to any content items.</i><p>
</if>
<else>

  <table bgcolor=#6699CC cellspacing=0 cellpadding=4 border=0 width="95%">
  <tr>
    <th align=left>Registered Content Items</th>
  </tr>
  <tr><td>

  <table border=0 cellspacing=0 width="100%">
  <tr bgcolor="#99ccff">
    <th>Title</th>
    <th>Context</th>
    <th>&nbsp</th>
  </tr>

  <multiple name="items">
  <if @items.rownum@ odd><tr bgcolor="#ffffff"></if>
  <else><tr bgcolor="#eeeeee"></else>
    <td>@items.title@</td>
    <td>@items.use_context@</td>
    <td>
      <a href="../items/template-unregister?template_id=@template_id@&context=@items.use_context@&item_id=@items.item_id@">Unregister</a>
    </td>
  </tr>

  </multiple>
  </table>
  </td></tr>
  </table>

</else>

<p>


<if @types:rowcount@ eq 0>
  <i>This template is not registered to any content types.</i><p>
</if>
<else>

  <table bgcolor=#6699CC cellspacing=0 cellpadding=4 border=0 width="95%">
  <tr>
    <th align=left>Registered Content Types</th>
  </tr>
  <tr><td>

  <table border=0 cellspacing=0 width="100%">
  <tr bgcolor="#99ccff">
    <th>Content Type</th>
    <th>Context</th>
    <th>&nbsp</th>
  </tr>

  <multiple name="types">
  <if @types.rownum@ odd><tr bgcolor="#ffffff"></if>
  <else><tr bgcolor="#eeeeee"></else>
    <td>@types.pretty_name@</td>
    <td>@types.use_context@</td>
    <td>
      <a href="unregister-template?template_id=@template_id@&context=@types.use_context@&content_type=@types.content_type@">Unregister</a>
    </td>
  </tr>

  </multiple>
  </table>

  </td></tr>
  </table>
</else>

<p>
<a href="../templates/rename?item_id=@template_id@">Rename this template</a><br>
<a href="../templates/template-delete?template_id=@template_id@" onClick="return window.confirm('Are you sure you want to delete this template?');">Delete this template</a>
