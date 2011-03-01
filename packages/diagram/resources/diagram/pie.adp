<SCRIPT Language="JavaScript">
function MouseOver(i) { P[i].MoveTo("","",10); }
function MouseOut(i)  { P[i].MoveTo("","",0); }
</SCRIPT>
<% set index 0 %>
<div style='position:relative;top:@diagram_properties.top@px;height:@diagram_properties.height@px;width:@diagram_properties.width@px;float:left;'>
<SCRIPT Language="JavaScript">
P = new Array();
document.open();
var y0=0;var sum=@diagram_properties.sum@;var i=0;
_BFont="font-family:Verdana;font-weight:bold;font-size:7pt;line-height:7pt;color:#000000;"
<noparse>
  <multiple name="@diagram_properties.multirow@">
</noparse>
<multiple name="elements">
<% set col [expr "$elements(rownum) % 2"]; %>
<if @col@ ne 0>
var x='<diagramelement name="@elements.name@"/>';
</if><else>
v=<diagramelement name="@elements.name@"/>;
i=i+1;
var y=y0 + v;
var q1 = y0/sum;
var q2 = y/sum;
if (q2 <= 0) {q2=1;}

var r = Math.round(Math.random()*255);
var g = Math.round(Math.random()*255);
var b = Math.round(Math.random()*255);
var color = 'rgb('+r+','+g+','+b+')';

var left = @diagram_properties.left@+@diagram_properties.width@/2;
var top = @diagram_properties.top@+@diagram_properties.height@/2;
var radius = @diagram_properties.width@/2;
var v1 = q1*360;
var v2 = q2*360;
P[i]=new Pie(left,top,0,radius,v1,v2,color);

var left = left + radius+25;
var top =  top-@diagram_properties.height@/3+i*15;
var bottom = top +15;

new Bar(left,top,left+60,bottom,color,x,"#FF0000","","void(0)","MouseOver("+i+")","MouseOut("+i+")");
y0=y0+<diagramelement name="@elements.name@"/>;
</else>
</multiple>
<noparse>
      </multiple>
</noparse>
document.close();
</SCRIPT>
</div>

