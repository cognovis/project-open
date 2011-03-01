-----
-- category links
-----

create table category_links (
	link_id			integer not null
				constraint category_links_pk primary key,
	from_category_id	integer not null
				constraint category_links_from_fk
				references categories on delete cascade,
	to_category_id		integer not null
				constraint category_links_to_fk
				references categories on delete cascade,
	constraint category_links_un
	unique (from_category_id, to_category_id)
);

create unique index category_links_rev_ix on category_links (to_category_id, from_category_id);

create sequence category_links_id_seq;

comment on table category_links is '
  Stores directed graph of linked categories. If category A
  and category B are linked, then any categorization on A
  will result in an additional categorization in B.
';
comment on column category_links.link_id is '
  Primary key.
';
comment on column category_links.from_category_id is '
  Category the link is coming from. Any categorization in this
  category will trigger a categorization in the other category.
';
comment on column category_links.to_category_id is '
  Category the link is coming to. Any categorization in the other
  category will trigger a categorization in this category.
';

\i ../category-link-package.sql
