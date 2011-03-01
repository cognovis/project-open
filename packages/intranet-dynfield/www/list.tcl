ad_page_contract {
    
    This page lets users manage ams lists

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-07-28
    @cvs-id $Id: list.tcl,v 1.4 2009/06/24 16:06:23 phast Exp $

} {
    {list_id ""}
    {list_name ""}
    {object_type ""}
    {description ""}
    groupby:optional
    orderby:optional
    {format "normal"}
    {status "normal"}
    {return_url ""}
    {return_url_label "[_ intranet-dynfield.lt_Return_to_Where_You_W]"}
}


set provided_return_url $return_url
set provided_return_url_label $return_url_label

if {$list_id == ""} {


    # Check that the list doesn't exist before
    if { ![ams::list::exists_p -object_type $object_type -list_name $list_name] } {

        # Create a new category for this list with the same name
        set object_type_category [db_string otypecat "select type_category_type from acs_object_types where object_type = :object_type" -default ""]
	if {"" == $object_type_category} { ad_return_complaint 1 "<b>Configuration Error</b>:<br>Object Type $object_type has an empty 'type_category_type' field." }
        db_string newcat "select im_category_new(nextval('im_categories_seq')::integer, :list_name, :object_type_category)"

        set exists_p [ams::list::exists_p -object_type $object_type -list_name $list_name]
        if {!$exists_p} {
	        ad_return_complaint 1 [lang::message::lookup "" intranet-dynfield.Unable_to_create_AMS_list "Unable to create AMS List"]
	        ad_script_abort
        }
    }

    set list_id [ams::list::get_list_id -object_type $object_type -list_name $list_name]
}

set list [::im::dynfield::List get_instance_from_db -id $list_id]
set this_url [$list url]
set object_type [$list object_type]

set create_attribute_url [export_vars -base "/intranet-dynfield/attribute-new" -url {object_type list_id {return_url $this_url} {action completely_new}}]


set title [$list pretty_name]
set list_pretty_name $title
set list_name [$list list_name]
set context [list [list lists Lists] $title]


list::create \
    -name mapped_attributes \
    -multirow mapped_attributes \
    -key attribute_id \
    -row_pretty_plural "[_ intranet-dynfield.Mapped_Attributes]" \
    -checkbox_name checkbox \
    -selected_format $format \
    -class "list" \
    -main_class "list" \
    -sub_class "narrow" \
    -pass_properties {
    } -actions {
    } -bulk_actions {
	"#intranet-dynfield.Answer_Required#" "list-attributes-required" "#intranet-dynfield.lt_Require_an_answer_fro#"
	"#intranet-dynfield.Answer_Optional#" "list-attributes-optional" "#intranet-dynfield.lt_An_answer_from_the_ch#"
	"#intranet-dynfield.Unmap#" "list-attributes-unmap" "#intranet-dynfield.lt_Unmap_check_attribute#"
	"#intranet-dynfield.Update_Ordering#" "list-order-update" "#intranet-dynfield.lt_Update_ordering_from_#"
    } -bulk_action_export_vars { 
        list_id
    } -elements {
        attribute_name {
            label "[_ intranet-dynfield.Attribute]"
            display_col attribute_name
        }
        pretty_name {
            label "[_ intranet-dynfield.Pretty_Name_1]"
	    display_template {
		<a href="@mapped_attributes.attribute_url@">@mapped_attributes.pretty_name@</a><if $object_type not eq @mapped_attributes.object_type@> (Parent Object Type: <a href="object?object_type=@mapped_attributes.object_type@">@mapped_attributes.object_type@</a>)</if>
	    }
        }
        widget {
            label "[_ intranet-dynfield.Widget_1]"
            display_col widget
            link_url_eval widgets
        }
        action {
            label "[_ intranet-dynfield.Action]"
            display_template {
                <a href="@mapped_attributes.unmap_url@" class="button">[_ intranet-dynfield.Unmap]</a>
                <a href="@mapped_attributes.text_url@" class="button">[_ intranet-dynfield.TextEdit]</a>
            }
        }
        answer {
            label "[_ intranet-dynfield.Required]"
            display_template {
                <if @mapped_attributes.required_p@>
                <a href="@mapped_attributes.optional_url@"><img src="/resources/acs-subsite/checkboxchecked.gif" title="[_ intranet-dynfield.Required]" border="0"></a>
                </if>
                <else>
                <a href="@mapped_attributes.required_url@"><img src="/resources/acs-subsite/checkbox.gif" title="[_ intranet-dynfield.Optional]" border="0"></a>
                </else>
            }
        }
        sort_order {
            label "[_ intranet-dynfield.Ordering]"
            display_template {
                <input name="sort_key.@mapped_attributes.attribute_id@" value="@mapped_attributes.sort_order_key@" size="4">
            }
        }
        widget_name {
            label "[_ intranet-dynfield.Widget_1]"
            display_col widget_name
            link_url_eval $widget_url
        }
    } -filters {
    } -groupby {
    } -orderby {
    } -formats {
        normal {
            label "[_ intranet-dynfield.Table]"
            layout table
            row {
                checkbox {}
		attribute_name {}
                pretty_name {}
                sort_order {}
                answer {}
                action {}
		widget_name {}
            }
        }
    }


template::multirow create mapped_attributes attribute_id attribute_name pretty_name sort_order_key \
    required_p section_heading attribute_url unmap_url text_url \
    required_url optional_url object_type widget_name widget_url
   
if {$return_url == ""} {
    set return_url [ad_return_url]
}

foreach mapped_dynfield_id [::im::dynfield::Attribute dynfield_attributes -list_ids $list_id] {
    set element [::im::dynfield::Element get_instance_from_db -id [lindex $mapped_dynfield_id 0] -list_id [lindex $mapped_dynfield_id 1]]
    $element instvar attribute_name pretty_name sort_order required_p section_heading widget_name 
    
    set attribute_id [lindex $mapped_dynfield_id 0]
    
    set sort_order_key $sort_order
   
    set attribute_url [export_vars -base "/intranet-dynfield/attribute-new" -url {attribute_id list_id return_url}]

    set unmap_url [export_vars -base "list-attributes" -url {list_id attribute_id return_url return_url_label {command "unmap"}}]
    set text_url [export_vars -base "list-text" -url {list_id attribute_id return_url return_url_label}]
    set required_url [export_vars -base "list-attributes" -url {list_id attribute_id return_url return_url_label {command "required"}}]
    set optional_url [export_vars -base "list-attributes" -url {list_id attribute_id return_url return_url_label {command "optional"}}]
    if {[exists_and_not_null widget_name]} {
        set widget_url [::im::dynfield::Widget widget_url -widget_name $widget_name]
	} else {
	    set widget_url ""
	}  
    template::multirow append mapped_attributes $attribute_id $attribute_name $pretty_name \
        $sort_order_key $required_p $section_heading $attribute_url $unmap_url $text_url \
        $required_url $optional_url $object_type $widget_name $widget_url
}

template::multirow sort mapped_attributes sort_order_key pretty_name object_type

list::create \
    -name unmapped_attributes \
    -multirow unmapped_attributes \
    -key attribute_id \
    -row_pretty_plural "[_ intranet-dynfield.Unmapped_Attributes]" \
    -checkbox_name checkbox_unmap \
    -selected_format "normal" \
    -class "list" \
    -main_class "list" \
    -sub_class "narrow" \
    -pass_properties {
     } -bulk_actions {
	 "#intranet-dynfield.Map#" "list-attributes" "#intranet-dynfield.lt_Map_check_attribute#"
     } -bulk_action_export_vars { 
	 list_id
	 return_url
	 return_url_label
	 {command "map"}
     } -actions {
     } -elements {
        attribute_name {
            label "[_ intranet-dynfield.Attribute]"
            display_col attribute_name
        }
        pretty_name {
            label "[_ intranet-dynfield.Pretty_Name_1]"
            display_col pretty_name
            link_url_eval $attribute_url
        }
        widget {
            label "[_ intranet-dynfield.Widget_1]"
            display_col widget
            link_url_eval $widget_url
        }
        object_type {
            label "[_ intranet-dynfield.Object_Type]"
        }
        action {
            label "[_ intranet-dynfield.Action]"
            display_template {
                <if @unmapped_attributes.widget@ nil>
		<a href="@unmapped_attributes.attribute_add_url@" class="button">[_ intranet-dynfield.Define_Widget]</a>
		</if>
		<else>
                <a href="@unmapped_attributes.map_url@" class="button">[_ intranet-dynfield.Map]</a>
		</else>
            }
        }
    } -filters {
    } -groupby {
    } -orderby {
    } -formats {
        normal {
            label "[_ intranet-dynfield.Table]"
            layout table
            row {
		checkbox_unmap {}
                pretty_name {}
                widget {}
		object_type {}
                action {}
            }
        }
    }
#                checkbox {}


# This query will override the ad_page_contract value entry_id

db_multirow -extend { attribute_url attribute_add_url map_url widget_url } -unclobber unmapped_attributes get_unmapped_attributes " " {
    set attribute_add_url [export_vars -base "attribute-add" -url {object_type attribute_name {return_url $this_url}}]
    set attribute_url [export_vars -base "/intranet-dynfield/attribute-new" -url {attribute_id}]
    set widget_url [::im::dynfield::Widget widget_url -widget_name $widget]
    set map_url [export_vars -base "list-attributes" -url {list_id attribute_id return_url return_url_label {command "map"}}]
}

template::multirow sort unmapped_attributes pretty_name object_type

set return_url $provided_return_url
set return_url_label $provided_return_url_label


ad_return_template
