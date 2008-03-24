-- upgrade-3.4.0.1.0-3.4.0.2.0.sql



update im_dynfield_layout set page_url = 'default' where page_url = '';
update im_dynfield_layout_pages set page_url = 'default' where page_url = '';


create or replace function im_dynfield_attribute__new_only_dynfield (
        integer, varchar, timestamptz, integer, varchar, integer,
        integer, varchar, char(1), char(1)
) returns integer as '
DECLARE
        p_attribute_id          alias for $1;
        p_object_type           alias for $2;
        p_creation_date         alias for $3;
        p_creation_user         alias for $4;
        p_creation_ip           alias for $5;
        p_context_id            alias for $6;

        p_acs_attribute_id      alias for $7;
        p_widget_name           alias for $8;
        p_deprecated_p          alias for $9;
        p_already_existed_p     alias for $10;

        v_attribute_id          integer;
BEGIN
        v_attribute_id := acs_object__new (
                p_attribute_id,
                p_object_type,
                p_creation_date,
                p_creation_user,
                p_creation_ip,
                p_context_id
        );

        insert into im_dynfield_attributes (
                attribute_id, acs_attribute_id, widget_name,
                deprecated_p, already_existed_p
        ) values (
                v_attribute_id, p_acs_attribute_id, p_widget_name,
                p_deprecated_p, p_already_existed_p
        );
        return v_attribute_id;
end;' language 'plpgsql';


alter table im_dynfield_attributes
add column also_hard_coded_p	char(1) default 'f'
				constraint im_dynfield_attributes_also_hard_coded_ch
				check (also_hard_coded_p in ('t','f'))
;



-- Make acs_attribute unique, so that no two dynfield_attributes can reference the same acs_attrib.
alter table im_dynfield_attributes add constraint
im_dynfield_attributes_acs_attribute_un UNIQUE (acs_attribute_id);

