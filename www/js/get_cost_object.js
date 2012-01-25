function ltrim(str, chars) {
	chars = chars || "\\s";
	return str.replace(new RegExp("^[" + chars + "]+", "g"), "");
}

function update_cost_object() {
    var xmlHttp1;
    var xmlHttp2;
    try {
	// Firefox, Opera 8.0+, Safari
	xmlHttp1=new XMLHttpRequest();
	xmlHttp2=new XMLHttpRequest();
    }
    catch (e) {
	// Internet Explorer
	try {
	    xmlHttp1=new ActiveXObject("Msxml2.XMLHTTP");
	    xmlHttp2=new ActiveXObject("Msxml2.XMLHTTP");
	}
	catch (e) {
	    try {
		xmlHttp1=new ActiveXObject("Microsoft.XMLHTTP");
		xmlHttp2=new ActiveXObject("Microsoft.XMLHTTP");
	    }
	    catch (e) {
		alert("Your browser does not support AJAX!");
		return false;
	    }
	}
    }

    xmlHttp1.onreadystatechange = function() {
	var oForm = document.getElementById('project-ae');
	if(xmlHttp1.readyState==4) {
	    // empty options
	    for (i = oForm.cost_object_category_id.options.length-1; i >= 0; i--) { 
		oForm.cost_object_category_id.remove(i); 
	    }

	    // loop through the komma separated list
	    var res1 = xmlHttp1.responseText;
	    var opts1 = res1.split("|");
	    for (i=0; i < opts1.length; i = i+2) {
		var newOpt = new Option(opts1[i+1], opts1[i], false, true);
		oForm.cost_object_category_id.options[oForm.cost_object_category_id.options.length] = newOpt;
	    }
	}
    }

    xmlHttp2.onreadystatechange = function() {
        var oForm = document.getElementById('project-ae');
	if(xmlHttp2.readyState==4) {
	    // empty options
	    for (i = oForm.cost_object_category_id.options.length-1; i >= 0; i--) { 
		oForm.cost_object_category_id.remove(i); 
	    }
	    // loop through the komma separated list
	    var res2 = xmlHttp2.responseText;
	    var opts2 = res2.split("|");
	    // alert(opts2);	    
	    for (i=0; i < opts2.length; i = i+2) {
		//alert (opts2[i]);
		var newOpt = new Option(opts2[i+1], ltrim(opts2[i]), false, true);
		oForm.cost_object_category_id.options[oForm.cost_object_category_id.options.length] = newOpt;
	    }
	}
    }

    // get the company_id from the customer's drop-down
    var oForm = document.getElementById('project-ae');
    var company_id = oForm.elements["company_id"].options[oForm.elements["company_id"].selectedIndex].value;
    xmlHttp1.open("GET","/intranet-cust-koernigweber/set_cost_object_drop_down?company_id="+company_id ,true);
    xmlHttp1.send(null);
    xmlHttp2.open("GET","/intranet-cust-koernigweber/set_cost_object_drop_down?company_id="+company_id ,true);
    xmlHttp2.send(null);
}


jQuery().ready(function(){
        var oForm = document.getElementById('project-ae');
	var project_id = oForm.elements["object_id"].value;
	var company_id = oForm.elements["company_id"].options[oForm.elements["company_id"].selectedIndex].value;
	if ( company_id != null && company_id != "" ) {
	        update_cost_object();
		var url_str = "/intranet-rest/im_project/" + project_id + "?format=xml"; 
		$.ajax({
			url: url_str,
			dataType: ($.browser.msie) ? "xml" : "text/xml",
			success: function(xml){
				  $(xml).find("cost_object_category_id").each(function() {
				          var oForm = document.getElementById('project-ae');
					  oForm.elements["cost_object_category_id"].value = $(this)[0].innerHTML;
  				  });
	  		}
		});
	}
	$('#company_id').change(update_cost_object);
});