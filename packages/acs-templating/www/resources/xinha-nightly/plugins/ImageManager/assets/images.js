/* This compressed file is part of Xinha. For uncompressed sources, forum, and bug reports, go to xinha.org */
/* This file is part of version 0.96beta2 released Fri, 20 Mar 2009 11:01:14 +0100 */
function i18n(a){return Xinha._lc(a,"ImageManager")}function changeDir(a){showMessage("Loading");location.href=_backend_url+"__function=images&dir="+encodeURIComponent(a)}function newFolder(a,b){location.href=_backend_url+"__function=images&dir="+encodeURIComponent(a)+"&newDir="+encodeURIComponent(b)}function updateDir(d){var c=window.top.document.getElementById("dirPath");if(c){for(var b=0;b<c.length;b++){var a=c.options[b].text;if(a==d){c.selectedIndex=b;showMessage("Loading");break}}}}function selectImage(c,f,d,b){var a=window.top.document;var e=a.getElementById("f_url");e.value=c;var e=a.getElementById("f_width");e.value=d;var e=a.getElementById("f_width");e.value=d;var e=a.getElementById("f_height");e.value=b;var e=a.getElementById("f_alt");e.value=f;var e=a.getElementById("orginal_width");e.value=d;var e=a.getElementById("orginal_height");e.value=b;a.getElementById("f_preview").src=window.parent._backend_url+"__function=thumbs&img="+c;update_selected()}var _current_selected=null;function update_selected(){var a=window.top.document;if(_current_selected){_current_selected.className=_current_selected.className.replace(/(^| )active( |$)/,"$1$2");_current_selected=null}var d=a.getElementById("f_url").value;var e=a.getElementById("dirPath");var f=e.options[e.selectedIndex].text;var b=new RegExp("^("+f.replace(/([\/\^$*+?.()|{}[\]])/g,"\\$1")+")([^/]*)$");if(b.test(d)){var c=document.getElementById("holder_"+asc2hex(RegExp.$2));if(c){_current_selected=c;c.className+=" active"}}}function asc2hex(c){var d="";for(var a=0;a<c.length;a++){var b=(c.charCodeAt(a)).toString(16);if(b.length==1){b="0"+b}d+=b}return d}function showMessage(b){var a=window.top.document;var d=a.getElementById("message");var c=a.getElementById("messages");if(d&&c){if(d.firstChild){d.removeChild(d.firstChild)}d.appendChild(a.createTextNode(i18n(b)));c.style.display="block"}}function addEvent(d,c,a){if(d.addEventListener){d.addEventListener(c,a,true);return true}else{if(d.attachEvent){var b=d.attachEvent("on"+c,a);return b}else{return false}}}function confirmDeleteFile(a){if(confirm(i18n("Delete file?"))){return true}return false}function confirmDeleteDir(a,b){if(b>0){alert(i18n("Please delete all files/folders inside the folder you wish to delete first."));return}if(confirm(i18n("Delete folder?"))){return true}return false}addEvent(window,"load",init);Xinha=window.parent.Xinha;