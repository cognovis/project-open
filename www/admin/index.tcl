#faq/www/admin/index.tcl

ad_page_contract {

    Admin for FAQs on this site

    @author Jennie Housman (jennie@ybos.net)
    @author Elizabeth Wirth (wirth@ybos.net)
    @creation-date 2000-10-24
   
} {
} -properties {
  context:onevalue
  package_id:onevalue
  user_id:onevalue
}

set package_id [ad_conn package_id]

permission::require_permission -object_id $package_id -privilege faq_admin_faq

set context {}

set user_id [ad_verify_and_get_user_id]

template::list::create \
    -name faqs \
    -elements {
        edit {
            link_url_col edit_url
            display_template {
                <img src="/resources/acs-subsite/Edit16.gif" border="0">
            }
            sub_class narrow
        }
        faq_name {
            label "Name"
            link_url_col manage_url
        }
        num_q_and_as {
            label "\# Q&A's"
            html { align right }
        }
        disabled_p {
            label "Enabled"
            display_template {
                <if @faqs.disabled_p@ false>
                  <a href="@faqs.disable_url@" title="Disable this FAQ"><img src="/resources/acs-subsite/checkboxchecked.gif" height="13" width="13" border="0" style="background-color: white;" alt="Disable"></a>
                </if>
                <else>
                  <a href="@faqs.enable_url@" title="Enable this FAQ"><img src="/resources/acs-subsite/checkbox.gif" height="13" width="13" border="0" style="background-color: white;" alt="Enable"></a>
                </else>
            }
            html { align center }
        }
        delete {
            link_url_col delete_url
            display_template {
                <img src="/resources/acs-subsite/Delete16.gif" border="0">
            }
            sub_class narrow
        }
    }


db_multirow -extend { edit_url manage_url delete_url disable_url enable_url } faqs faq_select {
    select faq_id, faq_name, disabled_p, 
    (select count(*) from faq_q_and_as where faq_id = f.faq_id) as num_q_and_as
      from acs_objects o, faqs f
      where object_id = faq_id
        and context_id = :package_id
    order by lower(faq_name), faq_name
} {
    set edit_url [export_vars -base faq-add-edit { faq_id }]
    set manage_url [export_vars -base one-faq { faq_id }]
    set delete_url [export_vars -base faq-delete { faq_id }]
    set disable_url [export_vars -base faq-disable { faq_id }]
    set enable_url [export_vars -base faq-enable { faq_id }]
}

ad_return_template
