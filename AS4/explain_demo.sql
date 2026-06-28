drop index idx_loans_reader_id;
explain analyze select * from loans where reader_id = (select id from readers limit 1);

create index idx_loans_reader_id on loans(reader_id);
explain analyze select * from loans where reader_id = (select id from readers limit 1);
