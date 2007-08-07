-- upgrade-3.2.11.0.0-3.2.12.0.0.sql


alter table im_categories add sort_order integer;
alter table im_categories alter column sort_order set default 0;
update im_categories set sort_order = category_id;




-- ------------------------------------------------------------------
-- Special dereferencing function for green-yellow-red traffic light
-- ------------------------------------------------------------------


-- Return a suitable GIF for traffic light status display
create or replace function im_traffic_light_from_id(integer)
returns varchar as '
DECLARE
        p_status_id	alias for $1;

	v_category	varchar;
	v_gif		varchar;
BEGIN
	select	c.category, c.aux_string1
	into	v_category, v_gif
	from	im_categories c
	where	category_id = p_status_id;

	-- Take the GIF specified in the category
	IF v_gif is null OR v_gif = '''' THEN 
		-- No GIF specified - take the default one...
		v_gif := ''/intranet/images/navbar_default/bb_''||lower(v_category)|| ''.gif'';
	END IF;

	return ''<img src="'' || v_gif || ''" border=0 title="" alt="">'';
END;' language 'plpgsql';


