<master>


@histogram_html;noquote@


<!--
<table align="left" cellpadding="3" cellspacing="1" >
<tr><td>
<div style='position:relative;top:0px;height:180px;width:500px;float:left;'>

<SCRIPT Language=JavaScript src=/resources/diagram/diagram/diagram.js></SCRIPT>
<SCRIPT Language="JavaScript">
document.open();
var D=new Diagram();
D.SetFrame(100, 40, 480, 150);
D.SetBorder(Date.UTC(2005,11,21,23,06,10), Date.UTC(2005,11,21,23,06,59), 0, 9);

D.SetText("Time","Count", "Monitoring - Dummy");
D.XScale=2;
D.YScale=1;
D.Font="color:#000000;font-family:Verdana;font-weight:normal;font-size:7pt;line-height:7pt;";
D.Draw("", "#c0c0c0", false);
var x=0, y=0;
var x1=D.ScreenX(Date.UTC(2005,11,21,23,06,11));
var y2=D.ScreenY(2);
var x2=D.ScreenX(Date.UTC(2005,11,21,23,06,11));
var y3=D.ScreenY(0);
var x3=D.ScreenX(Date.UTC(2005,11,21,23,06,10));
var y1=D.ScreenY(0);
  
x=D.ScreenX(Date.UTC(2005,11,21,23,06,11));
y=D.ScreenY(2);
new Dot(x, y, 7, '3', '#ff5533','');
x=D.ScreenX(Date.UTC(2005,11,21,23,06,11));
y=D.ScreenY(1);
new Line(x2, y2, x, y,'#aaee33',1, '');
x2=x;
y2=y;
x=D.ScreenX(Date.UTC(2005,11,21,23,06,10));
y=D.ScreenY(2);
new Box(x-4, y, x+4,D.ScreenY(0), '#c0c0c0', '', '', 1, '#000000');
      
x=D.ScreenX(Date.UTC(2005,11,21,23,06,12));
y=D.ScreenY(2);
new Dot(x, y, 7, '3', '#ff5533','');
x=D.ScreenX(Date.UTC(2005,11,21,23,06,12));
y=D.ScreenY(0);
new Line(x2, y2, x, y,'#aaee33',1, '');
x2=x;
y2=y;
x=D.ScreenX(Date.UTC(2005,11,21,23,06,13));
y=D.ScreenY(3);
new Box(x-4, y, x+4,D.ScreenY(0), '#c0c0c0', '', '', 1, '#000000');
      
x=D.ScreenX(Date.UTC(2005,11,21,23,06,13));
y=D.ScreenY(3);
new Dot(x, y, 7, '3', '#ff5533','');
x=D.ScreenX(Date.UTC(2005,11,21,23,06,13));
y=D.ScreenY(2);
new Line(x2, y2, x, y,'#aaee33',1, '');
x2=x;
y2=y;
x=D.ScreenX(Date.UTC(2005,11,21,23,06,16));
y=D.ScreenY(8);
new Box(x-4, y, x+4,D.ScreenY(0), '#c0c0c0', '', '', 1, '#000000');
      
x=D.ScreenX(Date.UTC(2005,11,21,23,06,14));
y=D.ScreenY(2);
new Dot(x, y, 7, '3', '#ff5533','');
x=D.ScreenX(Date.UTC(2005,11,21,23,06,14));
y=D.ScreenY(3);
new Line(x2, y2, x, y,'#aaee33',1, '');
x2=x;
y2=y;
x=D.ScreenX(Date.UTC(2005,11,21,23,06,19));
y=D.ScreenY(8);
new Box(x-4, y, x+4,D.ScreenY(0), '#c0c0c0', '', '', 1, '#000000');
      
x=D.ScreenX(Date.UTC(2005,11,21,23,06,15));
y=D.ScreenY(3);
new Dot(x, y, 7, '3', '#ff5533','');
x=D.ScreenX(Date.UTC(2005,11,21,23,06,15));
y=D.ScreenY(7);
new Line(x2, y2, x, y,'#aaee33',1, '');
x2=x;
y2=y;
x=D.ScreenX(Date.UTC(2005,11,21,23,06,21));
y=D.ScreenY(6);
new Box(x-4, y, x+4,D.ScreenY(0), '#c0c0c0', '', '', 1, '#000000');
      
x=D.ScreenX(Date.UTC(2005,11,21,23,06,16));
y=D.ScreenY(3);
new Dot(x, y, 7, '3', '#ff5533','');
x=D.ScreenX(Date.UTC(2005,11,21,23,06,16));
y=D.ScreenY(3);
new Line(x2, y2, x, y,'#aaee33',1, '');
x2=x;
y2=y;
x=D.ScreenX(Date.UTC(2005,11,21,23,06,23));
y=D.ScreenY(0);
new Box(x-4, y, x+4,D.ScreenY(0), '#c0c0c0', '', '', 1, '#000000');
      
x=D.ScreenX(Date.UTC(2005,11,21,23,06,17));
y=D.ScreenY(4);
new Dot(x, y, 7, '3', '#ff5533','');
x=D.ScreenX(Date.UTC(2005,11,21,23,06,17));
y=D.ScreenY(6);
new Line(x2, y2, x, y,'#aaee33',1, '');
x2=x;
y2=y;
x=D.ScreenX(Date.UTC(2005,11,21,23,06,26));
y=D.ScreenY(8);
new Box(x-4, y, x+4,D.ScreenY(0), '#c0c0c0', '', '', 1, '#000000');
      
x=D.ScreenX(Date.UTC(2005,11,21,23,06,18));
y=D.ScreenY(4);
new Dot(x, y, 7, '3', '#ff5533','');
x=D.ScreenX(Date.UTC(2005,11,21,23,06,18));
y=D.ScreenY(1);
new Line(x2, y2, x, y,'#aaee33',1, '');
x2=x;
y2=y;
x=D.ScreenX(Date.UTC(2005,11,21,23,06,29));
y=D.ScreenY(8);
new Box(x-4, y, x+4,D.ScreenY(0), '#c0c0c0', '', '', 1, '#000000');
      
x=D.ScreenX(Date.UTC(2005,11,21,23,06,19));
y=D.ScreenY(4);
new Dot(x, y, 7, '3', '#ff5533','');
x=D.ScreenX(Date.UTC(2005,11,21,23,06,20));
y=D.ScreenY(6);
new Line(x2, y2, x, y,'#aaee33',1, '');
x2=x;
y2=y;
x=D.ScreenX(Date.UTC(2005,11,21,23,06,31));
y=D.ScreenY(3);
new Box(x-4, y, x+4,D.ScreenY(0), '#c0c0c0', '', '', 1, '#000000');
      
x=D.ScreenX(Date.UTC(2005,11,21,23,06,20));
y=D.ScreenY(5);
new Dot(x, y, 7, '3', '#ff5533','');
x=D.ScreenX(Date.UTC(2005,11,21,23,06,22));
y=D.ScreenY(8);
new Line(x2, y2, x, y,'#aaee33',1, '');
x2=x;
y2=y;
x=D.ScreenX(Date.UTC(2005,11,21,23,06,33));
y=D.ScreenY(6);
new Box(x-4, y, x+4,D.ScreenY(0), '#c0c0c0', '', '', 1, '#000000');
      
x=D.ScreenX(Date.UTC(2005,11,21,23,06,21));
y=D.ScreenY(5);
new Dot(x, y, 7, '3', '#ff5533','');
x=D.ScreenX(Date.UTC(2005,11,21,23,06,23));
y=D.ScreenY(5);
new Line(x2, y2, x, y,'#aaee33',1, '');
x2=x;
y2=y;
x=D.ScreenX(Date.UTC(2005,11,21,23,06,36));
y=D.ScreenY(7);
new Box(x-4, y, x+4,D.ScreenY(0), '#c0c0c0', '', '', 1, '#000000');
      
x=D.ScreenX(Date.UTC(2005,11,21,23,06,22));
y=D.ScreenY(5);
new Dot(x, y, 7, '3', '#ff5533','');
x=D.ScreenX(Date.UTC(2005,11,21,23,06,25));
y=D.ScreenY(0);
new Line(x2, y2, x, y,'#aaee33',1, '');
x2=x;
y2=y;
x=D.ScreenX(Date.UTC(2005,11,21,23,06,39));
y=D.ScreenY(0);
new Box(x-4, y, x+4,D.ScreenY(0), '#c0c0c0', '', '', 1, '#000000');
      
x=D.ScreenX(Date.UTC(2005,11,21,23,06,23));
y=D.ScreenY(4);
new Dot(x, y, 7, '3', '#ff5533','');
x=D.ScreenX(Date.UTC(2005,11,21,23,06,26));
y=D.ScreenY(6);
new Line(x2, y2, x, y,'#aaee33',1, '');
x2=x;
y2=y;
x=D.ScreenX(Date.UTC(2005,11,21,23,06,41));
y=D.ScreenY(4);
new Box(x-4, y, x+4,D.ScreenY(0), '#c0c0c0', '', '', 1, '#000000');
      
x=D.ScreenX(Date.UTC(2005,11,21,23,06,24));
y=D.ScreenY(5);
new Dot(x, y, 7, '3', '#ff5533','');
x=D.ScreenX(Date.UTC(2005,11,21,23,06,27));
y=D.ScreenY(7);
new Line(x2, y2, x, y,'#aaee33',1, '');
x2=x;
y2=y;
x=D.ScreenX(Date.UTC(2005,11,21,23,06,43));
y=D.ScreenY(6);
new Box(x-4, y, x+4,D.ScreenY(0), '#c0c0c0', '', '', 1, '#000000');
      
x=D.ScreenX(Date.UTC(2005,11,21,23,06,25));
y=D.ScreenY(5);
new Dot(x, y, 7, '3', '#ff5533','');
x=D.ScreenX(Date.UTC(2005,11,21,23,06,28));
y=D.ScreenY(0);
new Line(x2, y2, x, y,'#aaee33',1, '');
x2=x;
y2=y;
x=D.ScreenX(Date.UTC(2005,11,21,23,06,46));
y=D.ScreenY(6);
new Box(x-4, y, x+4,D.ScreenY(0), '#c0c0c0', '', '', 1, '#000000');
      
x=D.ScreenX(Date.UTC(2005,11,21,23,06,26));
y=D.ScreenY(6);
new Dot(x, y, 7, '3', '#ff5533','');
x=D.ScreenX(Date.UTC(2005,11,21,23,06,29));
y=D.ScreenY(4);
new Line(x2, y2, x, y,'#aaee33',1, '');
x2=x;
y2=y;
x=D.ScreenX(Date.UTC(2005,11,21,23,06,49));
y=D.ScreenY(9);
new Box(x-4, y, x+4,D.ScreenY(0), '#c0c0c0', '', '', 1, '#000000');
      
x=D.ScreenX(Date.UTC(2005,11,21,23,06,27));
y=D.ScreenY(6);
new Dot(x, y, 7, '3', '#ff5533','');
x=D.ScreenX(Date.UTC(2005,11,21,23,06,30));
y=D.ScreenY(3);
new Line(x2, y2, x, y,'#aaee33',1, '');
x2=x;
y2=y;
x=D.ScreenX(Date.UTC(2005,11,21,23,06,51));
y=D.ScreenY(5);
new Box(x-4, y, x+4,D.ScreenY(0), '#c0c0c0', '', '', 1, '#000000');
      
x=D.ScreenX(Date.UTC(2005,11,21,23,06,28));
y=D.ScreenY(7);
new Dot(x, y, 7, '3', '#ff5533','');
x=D.ScreenX(Date.UTC(2005,11,21,23,06,31));
y=D.ScreenY(2);
new Line(x2, y2, x, y,'#aaee33',1, '');
x2=x;
y2=y;
x=D.ScreenX(Date.UTC(2005,11,21,23,06,53));
y=D.ScreenY(6);
new Box(x-4, y, x+4,D.ScreenY(0), '#c0c0c0', '', '', 1, '#000000');
      
x=D.ScreenX(Date.UTC(2005,11,21,23,06,29));
y=D.ScreenY(7);
new Dot(x, y, 7, '3', '#ff5533','');
x=D.ScreenX(Date.UTC(2005,11,21,23,06,32));
y=D.ScreenY(7);
new Line(x2, y2, x, y,'#aaee33',1, '');
x2=x;
y2=y;
x=D.ScreenX(Date.UTC(2005,11,21,23,06,56));
y=D.ScreenY(2);
new Box(x-4, y, x+4,D.ScreenY(0), '#c0c0c0', '', '', 1, '#000000');
      
x=D.ScreenX(Date.UTC(2005,11,21,23,06,30));
y=D.ScreenY(5);
new Dot(x, y, 7, '3', '#ff5533','');
x=D.ScreenX(Date.UTC(2005,11,21,23,06,33));
y=D.ScreenY(6);
new Line(x2, y2, x, y,'#aaee33',1, '');
x2=x;
y2=y;
x=D.ScreenX(Date.UTC(2005,11,21,23,06,59));
y=D.ScreenY(9);
new Box(x-4, y, x+4,D.ScreenY(0), '#c0c0c0', '', '', 1, '#000000');
      
document.close();
</SCRIPT>
</div>
</td>
<td valign="top">
Legend
    <div style="color: #ff5533;font-size:7pt;">Objects</div>
    <div style="color: #aaee33;font-size:7pt;">Memory</div>
    <div style="color: #c0c0c0;font-size:7pt;">Disc Usage</div>
</td></tr>
</table>

-->


