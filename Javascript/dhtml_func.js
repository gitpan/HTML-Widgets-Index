// <!--
left=150;
tableBorder=0;
tablePadding=1;
tableSpacing=1;
tableWidth=150;
tableBGColor="white";
tableBorderColor="blue";
cellBGColor="D7DFDD";
overBGColor="C0D8C8";
outBGColor="D7DFDD";
cellAlign="left";
cellWidth="150";
itemFontFace="Arial Narrow";
itemFontSize="1";
itemFontColor="white";
itemClass="dmenu";
titleBGColor="113D66";
titleHeight="10";
titleAlign="center";
titleValign="center";
titleWidth="100%";
titleFontFace="verdana";
titleFontSize="2";
titleFontColor="white";
espera=1000;



NS6 = (document.getElementById && !document.all)? true:false;
NS = (document.layers)? true:false;
IE = (document.all)? true:false;
var actual = null;
var timer = null;
var inMenu =0;

function creaMenu(nombre) {

	if (IE || NS6) {document.write('<DIV ID="'+nombre+'" style="visibility:hidden;Position : Absolute ;Left :'+left+' ;Top : 0 ;width:200px" >')}
	if (NS) {document.write('<layer name="'+nombre+'" visibility="hide" left="'+left+'" top="0" left="'+left+'" >')}

	document.write('<table border="'+tableBorder+'" cellpadding="'+tablePadding+'" cellspacing="'+tableSpacing+'" bgcolor="'+tableBGColor+'" bordercolor="'+tableBorderColor+'">')
	
}

function afegirTitol(text) {

	document.write('<tr><td bgcolor="'+titleBGColor+'" HEIGHT="'+titleHeight+'" ALIGN="'+titleAlign+'" VALIGN="'+titleValign+'" WIDTH="'+titleWidth+'">')
	document.write('<font face="'+titleFontFace+'" Size="'+titleFontSize+'" COLOR="'+titleFontColor+'"><b>'+text+'</b></font></td></tr>')
}

function afegirItem(text, link) {

	document.write('<TR><TD BGCOLOR="'+cellBGColor+'" onmouseover="bgColor=\''+overBGColor+'\';onMenu();" onmouseout="bgColor=\''+outBGColor+'\';outMenu();" WIDTH="'+cellWidth+'" align="'+cellAlign+'">')
	document.write('<ilayer><LAYER onmouseover="bgColor=\''+overBGColor+'\';onMenu();" onmouseout="bgColor=\''+outBGColor+'\';outMenu();" WIDTH="'+cellWidth+'" ALIGN="'+cellAlign+'">')
	document.write('<DIV><FONT face="'+itemFontFace+'" Size="'+itemFontSize+'">')
	document.write('<A HREF="'+link+'" CLASS="'+itemClass+'">'+text+'</a></font></DIV></layer></ilayer></TD></TR>')
}

function fiMenu() {

	document.write('</table>')
	if (IE || NS6) {document.write('</DIV>')}
	if (NS) {document.write('</LAYER>')}
}

function mostraMenu(nombre, ev) {
	
	if ((timer != null) && (actual != null)) {
		clearTimeout(timer)
		ocultaMenu(actual)
	}
  
	if (IE) {
		eval(nombre+'.style.top=(event.clientY+document.body.scrollTop)-10');
		eval(nombre+'.style.visibility="visible"');
		}
	if (NS) {
		eval('document.'+nombre+'.top=(ev.pageY)-15');
		eval('document.'+nombre+'.visibility="show"');
		}
	if (NS6){
		eval('document.getElementById("'+nombre+'").style.top=(ev.pageY)-15');
		eval('document.getElementById("'+nombre+'").style.visibility="visible"');
		}

	
	actual = nombre;	

}

function ocultaMenu(nombre) {
	
	if (IE) {
		eval(nombre+'.style.visibility="hidden"');
		}
	if (NS) {
		eval('document.'+nombre+'.visibility="hide"');
		}
	if (NS6) {
		eval('document.getElementById("'+nombre+'").style.visibility="hidden"');
		}
}	

function temps() {
	
	timer = setTimeout("oculta()", espera)
}

function oculta() {
  
  if(inMenu == 0) {
    ocultaMenu(actual)
  }
}

function onMenu() {

  clearTimeout(timer)
  inMenu = 1

}

function outMenu()
{
  inMenu = 0
  timer = setTimeout("ocultaMenu(actual)", espera)
}


// -->
