<master src="../lib/master">
<property name="title">@page_title;noquote@</property>
<property name="context">@context;noquote@</property>

<formtemplate id="patch"></formtemplate>

<p>
<if @button_form_export_vars@ not nil>
  <blockquote>
    <form method="GET" action="patch">
      @button_form_export_vars;noquote@
      <multiple name="button">
        <input type="submit" name="@button.name@" value="     @button.label@     ">
      </multiple>
    </form>
  </blockquote>
</if>
</p>

<if @mode@ eq "view" and @deleted_p@ eq 0>
<center>
<p>
<a href="patch?patch_number=@patch_number@&download=1">Download patch content</a>
</p>
</center>
<p>
<table border=0" cellspacing="0" cellpadding="2" bgcolor="lightgrey" width="100%">
  <tr>
    <td>
      <pre><%= [template::util::quote_html "$patch(content)"] %></pre>
    </td>
  </tr>
</table>
</p>
<center>
<p>
<a href="patch?patch_number=@patch_number@&download=1">Download patch content</a>
</p>
</center>
</if>







