--
-- The Categories Package
-- Extension for linking categories
--
-- @author Timo Hentschel (timo@timohentschel.de)
-- @creation-date 2004-02-04
--

CREATE or REPLACE PACKAGE category_link AS
    FUNCTION new (
        from_category_id    in categories.category_id%TYPE,
        to_category_id	    in categories.category_id%TYPE
    ) RETURN integer;

    PROCEDURE del ( 
	link_id		    in category_links.link_id%TYPE 
    );
END;
/
show errors

CREATE OR REPLACE PACKAGE BODY category_link AS

    FUNCTION new (
        from_category_id    in categories.category_id%TYPE,
        to_category_id	    in categories.category_id%TYPE
    ) RETURN integer
    IS
        v_link_id	integer; 
    BEGIN
	select category_links_id_seq.nextval into v_link_id from dual;

	insert into category_links (link_id, from_category_id, to_category_id)
	values (v_link_id, new.from_category_id, new.to_category_id);

	return v_link_id;
    END new;


    PROCEDURE del ( 
	link_id		    in category_links.link_id%TYPE 
    ) IS
    BEGIN
	delete from category_links
	where link_id = del.link_id;
    END del;

END category_link;
/
show errors
