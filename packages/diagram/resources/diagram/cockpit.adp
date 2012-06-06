<noparse>
  <multiple name="@diagram_properties.multirow@">
</noparse>
<multiple name="elements">
<% set col [expr "$elements(rownum) % 2"]; %>
<if @col@ ne 0>
<SCRIPT Language="JavaScript">
document.open();
v='<diagramelement name="@elements.name@"/>';
document.close();
</SCRIPT>
</if><else>
<div style='position:relative;top:0px;height:@diagram_properties.height@px;width:@diagram_properties.width@px;float:left;'>
<SCRIPT Language="JavaScript">
document.open();
var D=new Diagram();
D.SetFrame(10, 10,@diagram_properties.right@, @diagram_properties.bottom@);
D.SetBorder(-1, 1, -1, 1);
D.SetText('','','@elements.label@');
D.XScale=0;
D.YScale=0;
D.Draw('/resources/diagram/diagram/cockpit.png','',false);
sla='<diagramelement name="@elements.name@"/>';
a = Math.round((v - sla)/sla*100);
d = a*0.3;if (d < -15 || d > 15) {d=NaN;}
x=Math.sin((12+d)*2*Math.PI/12);
y=Math.cos((12+d)*2*Math.PI/12);
new Arrow(D.ScreenX(0), D.ScreenY(0), D.ScreenX(x/1.4),D.ScreenY(y/1.4),'@elements.color@', '@elements.size@');
new Bar(@diagram_properties.width@/2-10,@diagram_properties.height@/2-10,10,@diagram_properties.bottom@,'',a,'@elements.color@');
document.close();
</SCRIPT>
</div>
</else>
</multiple>
<noparse>
      </multiple>
</noparse>
