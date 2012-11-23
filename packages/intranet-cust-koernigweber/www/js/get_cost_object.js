function ltrim(str, chars) {
	chars = chars || "\\s";
	return str.replace(new RegExp("^[" + chars + "]+", "g"), "");
}

function update_cost_object() {
    var xmlHttp1;
    // get value from first request 
    try {
	// Firefox, Opera 8.0+, Safari
	xmlHttp1=new XMLHttpRequest();
    }
    catch (e) {
	// Internet Explorer
	try {
	    xmlHttp1=new ActiveXObject("Msxml2.XMLHTTP");
	}
	catch (e) {
	    try {
		xmlHttp1=new ActiveXObject("Microsoft.XMLHTTP");
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
		newOpt.value = $.trim(newOpt.value);	
		oForm.cost_object_category_id.options[oForm.cost_object_category_id.options.length] = newOpt;
		// alert(newOpt.value);
		
	    }
	}
    }

    // get the company_id from the customer's drop-down
    var oForm = document.getElementById('project-ae');
    var company_id = oForm.elements["company_id"].options[oForm.elements["company_id"].selectedIndex].value;
    xmlHttp1.open("GET","/intranet-cust-koernigweber/set_cost_object_drop_down?company_id="+company_id ,true);
    xmlHttp1.send(null);


    // //
    // Set drop-down to current value as stored in DB - only for existing projects 
    // // 

    // Find project_id
    var oForm = document.getElementById('project-ae');
    if (oForm.elements["object_id"] == null) {
	    var project_id = oForm.elements["project_id"].value;
    } else {
	    var project_id = oForm.elements["object_id"].value;
    }

    if ( oForm.elements["object_id"] != null ) {
	var url_str = "/intranet-rest/im_project/" + project_id + "?format=xml"; 
	$.ajax({
		url: url_str,
		// dataType: ($.browser.msie) ? "xml" : "text/xml",
		dataType: "xml",
		success: function(xml){
			  $(xml).find("im_project").each(function() {
	   			  var v_cost_object_category_id = $(this).find('cost_object_category_id').text();
				  var s = document.getElementById('project-ae').elements["cost_object_category_id"];
				  for ( var i = 0; i <  s.options.length; i++ ) {
					if ( s.options[i].value == v_cost_object_category_id ) {
				            s.options[i].selected = true;
				            return;
        				}
				  }					
  			  }); 
		}	
	});
    }
}

jQuery().ready(function(){
	var oForm = document.getElementById('project-ae');
	var company_id = oForm.elements["company_id"].options[oForm.elements["company_id"].selectedIndex].value;
	if ( company_id != null && company_id != "" ) {
	        update_cost_object();
	}

	// Listener: If company_id is changing update cost_object_category_id accordingly
	$('#company_id').change(update_cost_object);
});