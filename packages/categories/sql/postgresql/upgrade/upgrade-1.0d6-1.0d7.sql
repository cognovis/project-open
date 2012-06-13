-- 
-- packages/categories/sql/postgresql/upgrade/upgrade-1.0d6-1.0d7.sql
-- 
-- @author Deds Castillo (deds@i-manila.com.ph)
-- @creation-date 2005-01-13
-- @arch-tag: a966a122-5391-45e3-8176-dc0956fc9450
-- @cvs-id $Id$
--

-----
--
-- drop trigger as we force update the synonyms and we do not want to end
-- up with cyclic problems
--
-----
drop trigger category_synonym__insert_cat_trans_trg on category_translations;
drop trigger category_synonym__update_cat_trans_trg on category_translations;

-----
--
-- fix entries destroyed by old procs
--
----
create function inline_0 ()
returns integer as '
declare
    v_name             category_translations.name%TYPE;
    v_synonym_cursor   RECORD;
begin
    FOR v_synonym_cursor IN
       select category_id,
              locale
       from category_synonyms
            where synonym_p = ''f''
    LOOP
       select name into v_name
       from category_translations
       where category_id = v_synonym_cursor.category_id
             and locale = v_synonym_cursor.locale;

       update category_synonyms
       set name = v_name
       where category_id = v_synonym_cursor.category_id
             and locale = v_synonym_cursor.locale;
    END LOOP;

    return 0;
end;
' language 'plpgsql';

select inline_0 ();
drop function inline_0 ();


-----
--
-- recreate functions that return the proper record
--
-----

create or replace function category_synonym__new_cat_trans_trg ()
returns trigger as '
-- trigger function for inserting category translation
declare
    v_synonym_id     integer;
begin
	-- create synonym
    v_synonym_id := category_synonym__new (NEW.name, NEW.locale, NEW.category_id, null);

	-- mark synonym as not editable for users
    update category_synonyms
    set synonym_p = ''f''
    where synonym_id = v_synonym_id;

    return new;
end;' language 'plpgsql';

create or replace function category_synonym__edit_cat_trans_trg ()
returns trigger as '
-- trigger function for updating a category translation
declare
    v_synonym_id    integer;
begin
	-- get synonym_id of updated category translation
    select synonym_id into v_synonym_id
    from   category_synonyms
    where  category_id = OLD.category_id
           and name = OLD.name
           and locale = OLD.locale
           and synonym_p = ''f'';

	-- update synonym
    PERFORM category_synonym__edit (v_synonym_id, NEW.name, NEW.locale);

    return new;
end;' language 'plpgsql';


-----
--
-- recreate triggers
--
-----
create trigger category_synonym__insert_cat_trans_trg 
after insert
on category_translations for each row
execute procedure category_synonym__new_cat_trans_trg();

create trigger category_synonym__update_cat_trans_trg 
before update
on category_translations for each row
execute procedure category_synonym__edit_cat_trans_trg();


-----
--
-- these function have embedded tabs which make pg or is is the driver(?) barf
-- fix them to have spaces
--
-----
create or replace function category__edit (
    integer,   -- category_id
    varchar,   -- locale
    varchar,   -- name
    varchar,   -- description
    timestamp with time zone, -- modifying_date
    integer,   -- modifying_user
    varchar    -- modifying_ip
)
returns integer as '
declare
    p_category_id       alias for $1;
    p_locale            alias for $2;
    p_name              alias for $3;
    p_description       alias for $4;
    p_modifying_date    alias for $5;
    p_modifying_user    alias for $6;
    p_modifying_ip      alias for $7;
begin
	-- change category name
    update category_translations
    set name = p_name,
       description = p_description
    where category_id = p_category_id
          and locale = p_locale;

    update acs_objects
    set last_modified = p_modifying_date,
	    modifying_user = p_modifying_user,
	    modifying_ip = p_modifying_ip
    where object_id = p_category_id;

    return 0;
end;
' language 'plpgsql';
