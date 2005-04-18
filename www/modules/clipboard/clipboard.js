function searchArray(a, re) {

  for (i in a) {
    if (a[i].search(re) != -1) {
      return i;
    }
  }

  return -1;
}  

function appendArray(a, s) {

  a[a.length] = s;
}

function spliceArray(a, i) {

  c = new Array();

  for (var j = 0; j < a.length; j++) {
    if (j != i) {
      c[c.length] = a[j];
    }
  }

  return c;
}

function joinArray(a, d) {

  if (a.length == 0) return "";

  var s = "";

  for (var i = 0; i < a.length; i++) {

    if (a[i] == "") continue;

    if (s != "") {
      s += d;
    }
    s += a[i];    
  }

  return s;
}

// Maintain clipboard state in the form of a cookie
// mnt:id,id,id|mnt:id,id,id|mnt:id,id,id.
// This function toggles the
// mark on an item (if the item is currently marked, it is unmarked;
// if the item is not currently marked, it is marked.
function mark(root_url, mnt, id, floatclipboard_p) {

  markx(root_url, mnt, id, 
	root_url + 'resources/Bookmarked24', 
	root_url + 'resources/Bookmarks24',
	floatclipboard_p);
}

function markx(root_url, mnt, id, checked, unchecked, floatclipboard_p) {

  var marks = getCookie("content_marks");
  var str = "";
  var ck = "";
  
  // info for each mount point is delimited by "|"
  mountList = marks.split("|");

  // search for the specified mount point
  mountIndex = searchArray(mountList, "^" + mnt + ":");

  if (mountIndex == -1) {

    // no marks currently defined for mount point, so just append
    appendArray(mountList, mnt + ":" + id);
    is_add = true;

  } else {

    // one or more marks already defined for mount point
    // info for each mount point is in form "name:id,id,id..."        
    mountInfo = mountList[mountIndex].split(":");

    mountPoint = mountInfo[0];
    markList = mountInfo[1].split(",");
    idIndex = searchArray(markList, id);
   
    if (idIndex == -1) {
      appendArray(markList, id);
      is_add = true;
    } else {
      markList = spliceArray(markList, idIndex);
      is_add = false;
    }

    if (markList.length > 0) {
      mountList[mountIndex] = mnt + ":" + joinArray(markList, ",");
    } else {
      mountList = spliceArray(mountList, mountIndex);
    }
  }

  str = joinArray(mountList, "|");
  setCookie("content_marks", joinArray(mountList, "|"));

  if (document.images["mark" + id]) {
    if (is_add) {    
      document.images["mark" + id].src =  checked
    } else {
      document.images["mark" + id].src =  unchecked
    }
  }

  if (floatclipboard_p) {
    // this last call open or refresh the floating clipboard
    var clipboardWin=window.open(root_url + 'modules/clipboard/index?id=' + mnt + '&mount_point=clipboard','clipboardFrame', 'toolbar=no,dependent=yes,innerWidth=500,innerHeight=300,scrollbars=yes');

  }

}


function set_marks(mnt, checked) {

  var marks = getCookie("content_marks");
  
  // info for each mount point is delimited by "|"
  mountList = marks.split("|");

  // search for the specified mount point
  mountIndex = searchArray(mountList, "^" + mnt + ":");

  // return if no marks currently defined for mount point
  if (mountIndex == -1) { return; }

  // one or more marks defined for mount point
  // info for each mount point is in form "name:id,id,id..."        
  mountInfo = mountList[mountIndex].split(":");

  mountPoint = mountInfo[0];
  markList = mountInfo[1].split(",");
  if (markList.length == 0) { return; }
  
  // look through the marks defined for this mount point and
  // check for matching icons
  for (i in markList) {

    id = markList[i];
    if (document.images["mark" + id]) {
      document.images["mark" + id].src =  checked
    }
  }
}

function setCookie(name, value, expire) {
   var today = new Date()
   var exp = new Date()
   exp.setTime(today.getTime() + 60*60*24*365)
   var ck = name + "=" + escape(value) + "; path=/" + ((expire == null) ? "" : ("; expires=" + expire.toGMTString()));
   document.cookie = ck
}

function getCookie(Name) {

   var search = Name + "="

   if (document.cookie.length > 0) { // if there are any cookies
	  offset = document.cookie.indexOf(search) 
	  if (offset != -1) { // if cookie exists 
	     offset += search.length 
	     // set index of beginning of value
	     end = document.cookie.indexOf(";", offset) 
	     // set index of end of cookie value
	     if (end == -1) 
		end = document.cookie.length
	     return unescape(document.cookie.substring(offset, end))
	  } 
   }
   return "";
}

