<table align="left" cellpadding="3" cellspacing="1" >
<tr><td>
<div style='position:relative;top:0px;height:@diagram_properties.height@px;width:@diagram_properties.width@px;float:left;'>
<SCRIPT Language="JavaScript">
document.open();
var D=new Diagram();
D.SetFrame(@diagram_properties.left@, @diagram_properties.top@, @diagram_properties.right@, @diagram_properties.bottom@);
D.SetBorder(@diagram_properties.borders@);
D.SetText("@diagram_properties.x_label@","@diagram_properties.y_label@", "@diagram_properties.title@");
@diagram_properties.scales@
D.Font="color:#000000;font-family:Verdana;font-weight:normal;font-size:7pt;line-height:7pt;";
D.Draw("", "@diagram_properties.color@", false);
var x=0, y=0;
@diagram_properties.minima@
<noparse>
  <multiple name="@diagram_properties.multirow@">
</noparse>
<multiple name="elements">
<% set col [expr "$elements(rownum) % 2"] %>
<% set index [expr "int(ceil($elements(rownum)/2))"];%>
<if @col@ eq 1>
x=D.ScreenX(<if @diagram_properties.x_scale@ eq 1><diagramelement name="@elements.name@"/></if><else>Date.UTC(<diagramelement name="@elements.name@"/>)</else>);
</if>
<else>
y=D.ScreenY(<if @diagram_properties.y_scale@ eq 1><diagramelement name="@elements.name@"/></if><else>Date.UTC(<diagramelement name="@elements.name@"/>)</else>);
</else>
<if @col@ eq 0>
<if @elements.type@ eq 1>new Dot(x, y, @elements.size@, '@elements.dot_type@', '@elements.color@','');</if>
<if @elements.type@ eq 2>new Bar(x-@elements.size@, y, x+@elements.size@,@diagram_properties.y0@, '@elements.color@', '', '', '');</if>
<if @elements.type@ eq 3>new Box(x-@elements.size@, y, x+@elements.size@,@diagram_properties.y0@, '@elements.color@', '@elements.image;noquote@', '', 1, '#000000');</if>
<if @elements.type@ eq 4>
new Line(x@index@, y@index@, x, y,'@elements.color@',@elements.size@, '');
x@index@=x;
y@index@=y;
</if>
</if>
</multiple>
<noparse>
      </multiple>
</noparse>
document.close();
</SCRIPT>
</div>
</td>
<td valign="top">
#diagram.Legend#
<multiple name="elements">
<% set col [expr "$elements(rownum) % 2"] %>
<% set index [expr "int(ceil($elements(rownum)/2))"];%>
<if @col@ eq 1>
    <div style="color: @elements.color@;font-size:7pt;">@elements.label;noquote@</div>
</if>
</multiple>
</td></tr>
</table>


