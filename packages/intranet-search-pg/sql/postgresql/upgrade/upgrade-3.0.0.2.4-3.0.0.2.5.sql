-- upgrade-3.0.0.2.4-3.0.0.2.5.sql

SELECT acs_log__debug('/packages/intranet-search-pg/sql/postgresql/upgrade/upgrade-3.0.0.2.4-3.0.0.2.5.sql','');


-- Remove the existing triggers on "users"
--
drop trigger users_tsearch_tr on users;
drop function users_tsearch ();


-- Normalize text by replacing latin1 encoded accents and other 
-- "strange" characters by standard ASCII characters.
--
create or replace function norm_text_latin (varchar) 
returns varchar as '
declare
	p_str		alias for $1;
	v_str		varchar;
begin
	-- 240	160	A0	 	NO-BREAK SPACE
	-- 241	161	A1	?	INVERTED EXCLAMATION MARK
	-- 277	191	BF	?	INVERTED QUESTION MARK
	select translate(p_str, ''\240\241\277'', '' !?'')
	into v_str;

	-- 252	170	AA	?	FEMININE ORDINAL INDICATOR
	-- 272	186	BA	?	MASCULINE ORDINAL INDICATOR
	select translate(v_str, ''\252\272'', ''ao'')
	into v_str;

	-- 300	192	C0	?	LATIN CAPITAL LETTER A WITH GRAVE
	-- 301	193	C1	?	LATIN CAPITAL LETTER A WITH ACUTE
	-- 302	194	C2	?	LATIN CAPITAL LETTER A WITH CIRCUMFLEX
	-- 303	195	C3	?	LATIN CAPITAL LETTER A WITH TILDE
	-- 304	196	C4	?	LATIN CAPITAL LETTER A WITH DIAERESIS
	-- 305	197	C5	?	LATIN CAPITAL LETTER A WITH RING ABOVE
	select translate(v_str, ''\300\301\302\303\304\305'', ''AAAAAA'')
	into v_str;

	-- 310	200	C8	?	LATIN CAPITAL LETTER E WITH GRAVE
	-- 311	201	C9	?	LATIN CAPITAL LETTER E WITH ACUTE
	-- 312	202	CA	?	LATIN CAPITAL LETTER E WITH CIRCUMFLEX
	-- 313	203	CB	?	LATIN CAPITAL LETTER E WITH DIAERESIS
	select translate(v_str, ''\310\311\312\313'', ''EEEE'')
	into v_str;

	-- 314	204	CC	?	LATIN CAPITAL LETTER I WITH GRAVE
	-- 315	205	CD	?	LATIN CAPITAL LETTER I WITH ACUTE
	-- 316	206	CE	?	LATIN CAPITAL LETTER I WITH CIRCUMFLEX
	-- 317	207	CF	?	LATIN CAPITAL LETTER I WITH DIAERESIS
	select translate(v_str, ''\314\315\316\317'', ''IIII'')
	into v_str;

	-- 322	210	D2	?	LATIN CAPITAL LETTER O WITH GRAVE
	-- 323	211	D3	?	LATIN CAPITAL LETTER O WITH ACUTE
	-- 324	212	D4	?	LATIN CAPITAL LETTER O WITH CIRCUMFLEX
	-- 325	213	D5	?	LATIN CAPITAL LETTER O WITH TILDE
	-- 326	214	D6	?	LATIN CAPITAL LETTER O WITH DIAERESIS
	-- 330	216	D8	?	LATIN CAPITAL LETTER O WITH STROKE
	select translate(v_str, ''\322\323\324\325\326\330'', ''OOOOOO'')
	into v_str;

	-- 331	217	D9	?	LATIN CAPITAL LETTER U WITH GRAVE
	-- 332	218	DA	?	LATIN CAPITAL LETTER U WITH ACUTE
	-- 333	219	DB	?	LATIN CAPITAL LETTER U WITH CIRCUMFLEX
	-- 334	220	DC	?	LATIN CAPITAL LETTER U WITH DIAERESIS
	select translate(v_str, ''\331\332\333\334'', ''UUUU'')
	into v_str;

	-- 340	224	E0	?	LATIN SMALL LETTER A WITH GRAVE
	-- 341	225	E1	?	LATIN SMALL LETTER A WITH ACUTE
	-- 342	226	E2	?	LATIN SMALL LETTER A WITH CIRCUMFLEX
	-- 343	227	E3	?	LATIN SMALL LETTER A WITH TILDE
	-- 344	228	E4	?	LATIN SMALL LETTER A WITH DIAERESIS
	-- 345	229	E5	?	LATIN SMALL LETTER A WITH RING ABOVE
	select translate(v_str, ''\340\341\342\343\344\345'', ''aaaaaa'')
	into v_str;

	-- 350	232	E8	?	LATIN SMALL LETTER E WITH GRAVE
	-- 351	233	E9	?	LATIN SMALL LETTER E WITH ACUTE
	-- 352	234	EA	?	LATIN SMALL LETTER E WITH CIRCUMFLEX
	-- 353	235	EB	?	LATIN SMALL LETTER E WITH DIAERESIS
	select translate(v_str, ''\350\351\352\353'', ''eeee'')
	into v_str;

	-- 354	236	EC	?	LATIN SMALL LETTER I WITH GRAVE
	-- 355	237	ED	?	LATIN SMALL LETTER I WITH ACUTE
	-- 356	238	EE	?	LATIN SMALL LETTER I WITH CIRCUMFLEX
	-- 357	239	EF	?	LATIN SMALL LETTER I WITH DIAERESIS
	select translate(v_str, ''\354\355\356\357'', ''iiii'')
	into v_str;

	-- 362	242	F2	?	LATIN SMALL LETTER O WITH GRAVE
	-- 363	243	F3	?	LATIN SMALL LETTER O WITH ACUTE
	-- 364	244	F4	?	LATIN SMALL LETTER O WITH CIRCUMFLEX
	-- 365	245	F5	?	LATIN SMALL LETTER O WITH TILDE
	-- 366	246	F6	?	LATIN SMALL LETTER O WITH DIAERESIS
	-- 370	248	F8	?	LATIN SMALL LETTER O WITH STROKE
	select translate(v_str, ''\362\363\364\365\366\370'', ''oooooo'')
	into v_str;

	-- 307	199	C7	?	LATIN CAPITAL LETTER C WITH CEDILLA
	-- 361	241	F1	?	LATIN SMALL LETTER N WITH TILDE
	-- 347	231	E7	?	LATIN SMALL LETTER C WITH CEDILLA
	select translate(v_str, ''\307\361\347'', ''Cnc'')
	into v_str;

	-- 375	253	FD	?	LATIN SMALL LETTER Y WITH ACUTE
	-- 377	255	FF	?	LATIN SMALL LETTER Y WITH DIAERESIS
	select translate(v_str, ''\375\377'', ''yy'')
	into v_str;

	-- 371	249	F9	?	LATIN SMALL LETTER U WITH GRAVE
	-- 372	250	FA	?	LATIN SMALL LETTER U WITH ACUTE
	-- 373	251	FB	?	LATIN SMALL LETTER U WITH CIRCUMFLEX
	-- 374	252	FC	?	LATIN SMALL LETTER U WITH DIAERESIS
	select translate(v_str, ''\371\372\373\374'', ''UUUU'')
	into v_str;
	
	return v_str;
end;' language 'plpgsql';



-- Normalize text by replacing UTF-8 encoded accents and other
-- "strange" characters by standard ASCII characters.
--
create or replace function norm_text_utf8 (varchar)
returns varchar as '
declare
	p_str		alias for $1;
	p_str1		varchar;
	v_str		varchar;
	v_len		integer;
	v_asc		integer;
	v_char		varchar;
	v_i		integer;
	v_array		integer;
	v_found		integer;
	r		integer[77][3];
begin
	r := ''{
		{197,145,111},
		{197,177,117},
		{197,179,117},
		{196,159,103},	
		{196,155,101},	
		{195,135,99},	
		{195,188,117},	
		{195,169,101},	
		{195,162,97},	
		{195,164,97},	
		{195,160,97},	
		{195,165,97},	
		{195,167,99},	
		{195,170,101},	
		{195,171,101},	
		{195,168,101},	
		{195,175,105},	
		{195,174,105},	
		{195,172,105},	
		{195,132,97},	
		{195,133,97},	
		{195,137,101},	
		{195,180,111},	
		{195,182,111},	
		{195,178,111},	
		{195,187,117},	
		{195,185,117},	
		{195,191,121},	
		{195,150,111},	
		{195,156,117},	
		{197,165,116},	
		{197,159,115},	
		{197,175,117},	
		{197,174,117},	
		{195,161,97},	
		{195,173,105},	
		{195,179,111},
		{195,186,117},
		{195,177,110},	
		{195,145,110},	
		{196,140,99},	
		{196,141,99},	
		{197,153,114},	
		{197,152,114},	
		{197,160,115},	
		{197,161,115},	
		{195,189,121},	
		{197,189,122},	
		{197,190,122},	
		{196,177,105},	
		{195,152,111},	
		{206,177,97},	
		{195,159,115},	
		{206,147,103},	
		{207,128,112},	
		{196,131,97},	
		{207,131,115},	
		{206,179,103},	
		{196,176,105},	
		{197,163,116},	
		{206,180,100},	
		{195,184,111},	
		{196,133,97},	
		{196,153,101},	
		{196,134,99},	
		{196,135,99},	
		{197,129,108},	
		{197,130,108},	
		{197,131,110},	
		{197,132,110},	
		{195,147,111},	
		{197,154,115},	
		{197,155,115},	
		{197,185,122},	
		{197,186,122},	
		{197,187,122},	
		{197,188,122}	
	}'';

--		{197,145,111},
--		{197,177,117},
--		{197,179,117},
--		{196,159,103},	-- LATIN SMALL LETTER G WITH BREVE
--		{196,155,101},	-- LATIN SMALL LETTER E WITH CARON
--		{195,135,99},	-- LATIN CAPITAL LETTER C WITH CEDILLA
--		{195,188,117},	-- LATIN SMALL LETTER U WITH DIAERESIS
--		{195,169,101},	-- LATIN SMALL LETTER E WITH ACUTE
--		{195,162,97},	-- LATIN SMALL LETTER A WITH CIRCUMFLEX
--		{195,164,97},	-- LATIN SMALL LETTER A WITH DIAERESIS
--		{195,160,97},	-- LATIN SMALL LETTER A WITH GRAVE
--		{195,165,97},	-- LATIN SMALL LETTER A WITH RING ABOVE
--		{195,167,99},	-- LATIN SMALL LETTER C WITH CEDILLA
--		{195,170,101},	-- LATIN SMALL LETTER E WITH CIRCUMFLEX
--		{195,171,101},	-- LATIN SMALL LETTER E WITH DIAERESIS
--		{195,168,101},	-- LATIN SMALL LETTER E WITH GRAVE
--		{195,175,105},	-- LATIN SMALL LETTER I WITH DIAERESIS
--		{195,174,105},	-- LATIN SMALL LETTER I WITH CIRCUMFLEX
--		{195,172,105},	-- LATIN SMALL LETTER I WITH GRAVE
--		{195,132,97},	-- LATIN CAPITAL LETTER A WITH DIAERESIS
--		{195,133,97},	-- LATIN CAPITAL LETTER A WITH RING ABOVE
--		{195,137,101},	-- LATIN CAPITAL LETTER E WITH ACUTE
--		{195,180,111},	-- LATIN SMALL LETTER O WITH CIRCUMFLEX
--		{195,182,111},	-- LATIN SMALL LETTER O WITH DIAERESIS
--		{195,178,111},	-- LATIN SMALL LETTER O WITH GRAVE
--		{195,187,117},	-- LATIN SMALL LETTER U WITH CIRCUMFLEX
--		{195,185,117},	-- LATIN SMALL LETTER U WITH GRAVE
--		{195,191,121},	-- LATIN SMALL LETTER Y WITH DIAERESIS
--		{195,150,111},	-- LATIN CAPITAL LETTER O WITH DIAERESIS
--		{195,156,117},	-- LATIN CAPITAL LETTER U WITH DIAERESIS
--		{197,165,116},	-- LATIN SMALL LETTER T WITH CARON
--		{197,159,115},	-- LATIN SMALL LETTER S WITH CEDILLA
--		{197,175,117},	-- LATIN SMALL LETTER U WITH RING ABOVE
--		{197,174,117},	-- LATIN CAPITAL LETTER U WITH RING ABOVE
--		{195,161,97},	-- LATIN SMALL LETTER A WITH ACUTE
--		{195,173,105},	-- LATIN SMALL LETTER I WITH ACUTE
--		{195,179,111},	-- LATIN SMALL LETTER O WITH ACUTE
--		{195,186,117},	-- LATIN SMALL LETTER U WITH ACUTE
--		{195,177,110},	-- LATIN SMALL LETTER N WITH TILDE
--		{195,145,110},	-- LATIN CAPITAL LETTER N WITH TILDE
--		{196,140,99},	-- LATIN CAPITAL LETTER C WITH CARON
--		{196,141,99},	-- LATIN SMALL LETTER C WITH CARON
--		{197,153,114},	-- LATIN SMALL LETTER R WITH CARON
--		{197,152,114},	-- LATIN CAPITAL LETTER R WITH CARON
--		{197,160,115},	-- LATIN CAPITAL LETTER S WITH CARON
--		{197,161,115},	-- LATIN SMALL LETTER S WITH CARON
--		{195,189,121},	-- LATIN SMALL LETTER Y WITH ACUTE
--		{197,189,122},	-- LATIN CAPITAL LETTER Z WITH CARON
--		{197,190,122},	-- LATIN SMALL LETTER Z WITH CARON
--		{196,177,105},	-- LATIN SMALL LETTER DOTLESS I
--		{195,152,111},	-- LATIN CAPITAL LETTER O WITH STROKE
--		{206,177,97},	-- GREEK SMALL LETTER ALPHA
--		{195,159,115},	-- LATIN SMALL LETTER SHARP S
--		{206,147,103},	-- GREEK CAPITAL LETTER GAMMA
--		{207,128,112},	-- GREEK SMALL LETTER PI
--		{196,131,97},	-- LATIN SMALL LETTER A WITH BREVE
--		{207,131,115},	-- GREEK SMALL LETTER SIGMA
--		{206,179,103},	-- GREEK SMALL LETTER GAMMA
--		{196,176,105},	-- LATIN CAPITAL LETTER I WITH DOT ABOVE
--		{197,163,116},	-- LATIN SMALL LETTER T WITH CEDILLA
--		{206,180,100},	-- GREEK SMALL LETTER DELTA
--		{195,184,111},	-- LATIN SMALL LETTER O WITH STROKE
--		{196,133,97},	-- LATIN SMALL LETTER A WITH OGONEK
--		{196,153,101},	-- LATIN SMALL LETTER E WITH OGONEK
--		{196,134,99},	-- LATIN CAPITAL LETTER C WITH ACUTE
--		{196,135,99},	-- LATIN SMALL LETTER C WITH ACUTE
--		{197,129,108},	-- LATIN CAPITAL LETTER L WITH STROKE
--		{197,130,108},	-- LATIN SMALL LETTER L WITH STROKE
--		{197,131,110},	-- LATIN CAPITAL LETTER N WITH ACUTE
--		{197,132,110},	-- LATIN SMALL LETTER N WITH ACUTE
--		{195,147,111},	-- LATIN CAPITAL LETTER O WITH ACUTE
--		{197,154,115},	-- LATIN CAPITAL LETTER S WITH ACUTE
--		{197,155,115},	-- LATIN SMALL LETTER S WITH ACUTE
--		{197,185,122},	-- LATIN CAPITAL LETTER Z WITH ACUTE
--		{197,186,122},	-- LATIN SMALL LETTER Z WITH ACUTE
--		{197,187,122},	-- LATIN CAPITAL LETTER Z WITH DOT ABOVE
--		{197,188,122}	-- LATIN SMALL LETTER Z WITH DOT ABOVE


	v_str := '''';
        p_str1 := coalesce(p_str, '''');
        v_len := char_length(p_str1);
	FOR v_i IN 1..v_len LOOP
	    v_char := substr(p_str1, v_i, 1);
	    v_asc := ascii(v_char);
	    v_found := 0;
	    FOR v_array IN 1..77 LOOP
		IF v_asc = r[v_array][1] THEN
		    -- found the first character
		    IF ascii(substr(p_str1, v_i+1, 1)) = r[v_array][2] THEN
			-- got the Unicode char!
			v_str := v_str || chr(r[v_array][3]);
			v_i := v_i + 1;
			v_found := 1;
		    END IF;
		END IF;
	    END LOOP;
	    IF v_found = 0 THEN
		-- Not found - so its just a normal charcter: add it
		v_str := v_str || v_char;
	    END IF;
	END LOOP;

	return v_str;
end;' language 'plpgsql';


create or replace function norm_text (varchar)
returns varchar as '
declare
        p_str           alias for $1;
        v_str           varchar;
begin
        select translate(p_str, ''@.-'', ''   '')
        into v_str;
	
        return norm_text_utf8(v_str);
--        return norm_text_latin(norm_text_utf8(v_str));
end;' language 'plpgsql';



create or replace function im_search_update (integer, varchar, integer, varchar)
returns integer as '
declare
	p_object_id	alias for $1;
	p_object_type	alias for $2;
	p_biz_object_id	alias for $3;
	p_text		alias for $4;

	v_object_type_id	integer;
	v_exists_p		integer;
begin
	select	object_type_id
	into	v_object_type_id
	from	im_search_object_types
	where	object_type = p_object_type;

	select	count(*)
	into	v_exists_p
	from	im_search_objects
	where	object_id = p_object_id
		and object_type_id = v_object_type_id;

	if v_exists_p = 1 then
		update im_search_objects set
			object_type_id	= v_object_type_id,
			biz_object_id	= p_biz_object_id,
			fti		= to_tsvector(''default'', norm_text(p_text))
		where
			object_id	= p_object_id;
	else 
		insert into im_search_objects (
			object_id,
			object_type_id,
			biz_object_id,
			fti
		) values (
			p_object_id,
			v_object_type_id,
			p_biz_object_id,
			to_tsvector(''default'', p_text)
		);
	end if;

	return 0;
end;' language 'plpgsql';


-----------------------------------------------------------
-- person

insert into im_search_object_types values (1,'user');

create or replace function persons_tsearch () 
returns trigger as '
declare
	v_string	varchar;
begin
	select	coalesce(email, '''') || '' '' ||
		coalesce(url, '''') || '' '' ||
		coalesce(first_names, '''') || '' '' ||
		coalesce(last_name, '''') || '' '' ||
		coalesce(username, '''') || '' '' ||
		coalesce(screen_name, '''') || '' '' ||
		coalesce(username, '''')
	into	v_string
	from	cc_users
	where	user_id = new.person_id;

	perform im_search_update(new.person_id, ''user'', new.person_id, v_string);
	return new;
end;' language 'plpgsql';

-- Frank Bergmann: 050709
-- DONT add a trigger to "users": Users is being
-- updated frequently when users are accessing the
-- system etc., leading to serious slowdown of the
-- machine.

CREATE TRIGGER persons_tsearch_tr 
BEFORE INSERT or UPDATE
ON persons
FOR EACH ROW 
EXECUTE PROCEDURE persons_tsearch();


-----------------------------------------------------------
-- Index the existing business objects

update persons
set first_names=first_names;
