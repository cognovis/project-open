<master src="../../intranet-core/www/master">
<property name="title">@page_title@</property>
<property name="context">@context;noquote@</property>
<property name="main_navbar_label">projects</property>
<property name="focus">@focus;noquote@</property>
<property name="sub_navbar">@sub_navbar;noquote@</property>


<if @message@ not nil>
  <div class="general-message">@message@</div>
</if>

<% set return_url [im_url_with_query] %>

<table width="100%">
  <tr valign="top">
    <td width="50%">
      <%= [im_component_bay left] %>
    </td>

    <td width="50%">
      <%= [im_component_bay right] %>
    </td>

  </tr>
  <tr>
    <td colspan=2>
      <%= [im_component_bay bottom] %>
    </td>
  </tr>
</table>

<script type="text/javascript">
        var html_tag = document.getElementsByName('name')[0];
        html_tag.setAttribute('onBlur','set_project_nr();');
function set_project_nr() {
        // var tmp = document.getElementsByName('name')[0].value.replace(' ','_');
        var tmp = replaceSpaces(document.getElementsByName('name')[0].value);
        document.getElementsByName('short_name')[0].value = removeSpaces(tmp.replace(/[^a-zA-Z 0-9 _ ]+/g,'')).substring(0,29);
}
function removeSpaces(string) {
 return string.split(' ').join('');
}
function replaceSpaces(string) {
 return string.split(' ').join('_');
}
</script>

