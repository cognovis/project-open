ad_library {

	Widget procedures
	
    @creation-date 2010-06-28
    @author  (iuri.sampaio@gmail.com)
    @cvs-id 
}

namespace eval ::im {}
namespace eval ::im::dynfield {}
namespace eval ::im::dynfield::widgets {}

ad_proc -public -callback im_dynfield_widget_after_update -impl xotcl_dynfields_reload_class {
    {-widget_name}
} {
    # ------------------------------------------------------------------
    # Reload the class
    # ------------------------------------------------------------------
    set class [::im::dynfield::Class object_type_to_class $object_type]
    $class destroy
    ::im::dynfield::Class get_class_from_db -object_type $object_type
} 

