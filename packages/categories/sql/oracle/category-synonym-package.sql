--
-- The Categories Package
-- Extension for category synonyms
--
-- @author Bernd Schmeil (bernd@thebernd.de)
-- @author Timo Hentschel (timo@timohentschel.de)
-- @creation-date 2004-01-08
--

CREATE or REPLACE PACKAGE category_synonym AS
    FUNCTION new (
        name		    in category_synonyms.name%TYPE,
        locale		    in category_synonyms.locale%TYPE,
        category_id	    in categories.category_id%TYPE,
        synonym_id	    in category_synonyms.synonym_id%TYPE	default null
    ) RETURN integer;

    PROCEDURE del (
	synonym_id	    in category_synonyms.synonym_id%TYPE 
    );

    FUNCTION edit (
        synonym_id	    in category_synonyms.synonym_id%TYPE,
        name		    in category_synonyms.name%TYPE,
        locale		    in category_synonyms.locale%TYPE
    ) RETURN integer;

    FUNCTION search (
        search_text	    in category_search.search_text%TYPE,
        locale		    in category_search.locale%TYPE
    ) RETURN integer;

    FUNCTION get_similarity (
        len1		integer,
	len2		integer,
	matches		integer
    ) RETURN integer;
END;
/
show errors

CREATE OR REPLACE PACKAGE BODY category_synonym AS

    FUNCTION convert_string (
        string		in category_search.search_text%TYPE
    ) RETURN varchar;

    PROCEDURE reindex (
        synonym_id	    in category_synonyms.synonym_id%TYPE,
        name		    in category_synonyms.name%TYPE,
        locale		    in category_synonyms.locale%TYPE
    );

    FUNCTION new (
        name		    in category_synonyms.name%TYPE,
        locale		    in category_synonyms.locale%TYPE,
        category_id	    in categories.category_id%TYPE,
        synonym_id	    in category_synonyms.synonym_id%TYPE	default null
    ) RETURN integer
    IS
	v_synonym_id	integer;
    BEGIN
	-- get new synonym_id
	if (new.synonym_id is null) then
		select category_synonyms_id_seq.nextval into v_synonym_id from dual;
	else 
		v_synonym_id := new.synonym_id;
	end if;

	-- insert synonym data
	insert into category_synonyms (synonym_id, category_id, locale, name, synonym_p)
	values (v_synonym_id, new.category_id, new.locale, new.name, 't');

	-- insert in synonym index and search results
	category_synonym.reindex (v_synonym_id, new.name, new.locale);

	return v_synonym_id;
    END new;


    PROCEDURE del (
	synonym_id	    in category_synonyms.synonym_id%TYPE 
    ) IS
    BEGIN
	-- delete search results
	delete	from category_search_results
	where	synonym_id = del.synonym_id;

	-- delete synonym index
	delete	from category_synonym_index
	where	synonym_id = del.synonym_id;

	-- delete synonym
	delete	from category_synonyms
	where	synonym_id = del.synonym_id;
    END del;

	
    FUNCTION edit (
        synonym_id	    in category_synonyms.synonym_id%TYPE,
        name		    in category_synonyms.name%TYPE,
        locale		    in category_synonyms.locale%TYPE
    ) RETURN integer IS
    BEGIN
	-- update synonym data
	update	category_synonyms
	set	name = edit.name,
		locale = edit.locale
	where	synonym_id = edit.synonym_id;

	-- update synonym index and search results
	category_synonym.reindex (edit.synonym_id, edit.name, edit.locale);

	return edit.synonym_id;
    END edit;


    FUNCTION search (
        search_text	    in category_search.search_text%TYPE,
        locale		    in category_search.locale%TYPE
    ) RETURN integer
    IS
	v_search_text	varchar(200);
	v_query_id	integer;
	v_len		integer;
	v_i		integer;
    BEGIN
	-- check if search text already exists
	select	query_id into v_query_id
	from	category_search
	where	search_text = search.search_text
	and 	locale = search.locale;

	-- simply update old search data if already exists
	if (v_query_id is not null) then
		update	category_search
		set	queried_count = queried_count + 1,
			last_queried = sysdate
		where	query_id = v_query_id;
		return v_query_id;
	end if;

	-- get new search query id
	select category_search_id_seq.nextval into v_query_id from dual;

	-- convert string to uppercase and substitute special chars
	v_search_text := category_synonym.convert_string (search.search_text);

	-- insert search data
	insert into category_search (query_id, search_text, locale, queried_count, last_queried)
	values (v_query_id, search.search_text, search.locale, 1, sysdate);

	-- build search index
	v_len := length (v_search_text) - 2;
	v_i := 1;
	while (v_i <= v_len) loop
		insert into category_search_index 
		values (v_query_id, substr (v_search_text, v_i , 3));
		v_i := v_i + 1;
	end loop;

	-- build search result
	insert into category_search_results
	select	v_query_id, s.synonym_id, 
		category_synonym.get_similarity (v_len, length (s.name) - 2, count(*))
	from	category_search_index si, 
		category_synonym_index i,
		category_synonyms s
	where	si.query_id = v_query_id
	and	si.trigram = i.trigram
	and	s.synonym_id = i.synonym_id
	and	s.locale = search.locale
	group by s.synonym_id, s.name;

	return v_query_id;
    END search;


    FUNCTION get_similarity (
        len1		integer,
	len2		integer,
	matches		integer
    ) RETURN integer IS
    BEGIN
	return (matches * 200 / (len1 + len2));
    END get_similarity;


-----
-- helper procs and functions
-----

    FUNCTION convert_string (
        string		in category_search.search_text%TYPE
    ) RETURN varchar
    IS
        v_index_string	varchar(200);
    BEGIN
	-- convert string to uppercase and substitute special chars
        -- TODO: complete
        v_index_string := upper (
                        replace (
                        replace (
                        replace (
                        replace (
                        replace (
                        replace (
			replace (convert_string.string, 'ä', 'AE'), 
					 'Ä', 'AE'),
					 'ö', 'OE'),
					 'Ö', 'OE'),
					 'ü', 'UE'),
					 'Ü', 'UE'),
					 'ß', 'SS'));
					  
	return (' ' || v_index_string || ' ');
    END convert_string;


    PROCEDURE reindex (
        synonym_id	    in category_synonyms.synonym_id%TYPE,
        name		    in category_synonyms.name%TYPE,
        locale		    in category_synonyms.locale%TYPE
    ) IS
	v_name		varchar(200);
	v_len		integer;
	v_i		integer;
    BEGIN
	-- delete old search results for this synonym
	delete	from category_search_results
	where	synonym_id = reindex.synonym_id;

	-- delete old synonym index for this synonym
	delete	from category_synonym_index
	where	synonym_id = reindex.synonym_id;

	-- convert string to uppercase and substitute special chars
	v_name := category_synonym.convert_string (reindex.name);

	-- rebuild synonym index
	v_len := length (v_name) - 2;
	v_i := 1;
	while (v_i <= v_len) loop
		insert into category_synonym_index
		values (reindex.synonym_id, substr (v_name, v_i , 3));
		v_i := v_i + 1;
	end loop;

	-- rebuild search results
	insert into category_search_results
	select	s.query_id, reindex.synonym_id, 
		category_synonym.get_similarity (v_len, length (s.search_text) - 2, count(*))
	from	category_search_index si, 
		category_synonym_index i,
		category_search s
	where	i.synonym_id = reindex.synonym_id
	and	si.trigram = i.trigram
	and	si.query_id = s.query_id
	and	s.locale = reindex.locale
	group by s.query_id, s.search_text;
    END reindex;

END category_synonym;
/
show errors

-----
-- triggers for category synonyms
-----

create or replace trigger ins_synonym_on_ins_transl_trg
after insert on category_translations for each row
declare
	v_synonym_id	integer;
begin
	-- create synonym
	v_synonym_id := category_synonym.new (:new.name, :new.locale, :new.category_id, null);

	-- mark synonym as not editable for users
	update category_synonyms
	set synonym_p = 'f'
	where synonym_id = v_synonym_id;
end;
/
show errors

create or replace trigger upd_synonym_on_upd_transl_trg
before update on category_translations for each row
declare
	v_synonym_id	integer;
begin
	-- get synonym_id of updated category translation
	select	synonym_id into v_synonym_id
	from	category_synonyms
	where	category_id = :old.category_id
	and	name = :old.name
	and	locale = :old.locale
	and	synonym_p = 'f';

	-- update synonym
	v_synonym_id := category_synonym.edit (v_synonym_id, :new.name, :new.locale);
end;
/
show errors
