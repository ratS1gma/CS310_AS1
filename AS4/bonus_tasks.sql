--1. створення 3 users
create user lib_admin password 'admin_pass_123';
create user lib_staff password 'staff_pass_123';
create user lib_guest password 'guest_pass_123';

-- надання прав
grant all privileges on all tables in schema public to lib_admin;
grant select, insert, update on books, loans, readers, library_cards to lib_staff;
grant select on books, authors, book_authors to lib_guest;

--2. view показує всі книги, які ще не повернули
create or replace view active_debtors as
select 
    r.first_name || ' ' || r.last_name as reader_name,
    r.email,
    b.title as book_title,
    l.loan_date,
    current_date - l.loan_date as days_borrowed
from loans l
join readers r on l.reader_id = r.id
join books b on l.book_id = b.id
where l.is_returned = false;

--3. процедура для повернення книги
create or replace procedure return_book(p_loan_id uuid)
language plpgsql
as $$
begin
    update loans
    set is_returned = true, 
        return_date = current_date
    where id = p_loan_id and is_returned = false;
    
    if not found then
        raise notice 'loan record not found or book already returned.';
    end if;
end;
$$;

-- 4. тригер, який забороняє видаляти книгу, якщо вона зараз на руках у читача
create or replace function check_active_loans_before_delete()
returns trigger 
as $$
begin
    if exists (select 1 from loans where book_id = old.id and is_returned = false) then
        raise exception 'cannot delete book: it is currently borrowed by a reader.';
    end if;
    return old;
end;
$$ language plpgsql;

create trigger prevent_borrowed_book_deletion
before delete on books
for each row
execute function check_active_loans_before_delete();
