-- 1. readers
create table readers (
    id uuid primary key default gen_random_uuid(),
    first_name varchar(100) not null,
    last_name varchar(100) not null,
    email varchar(150) unique not null,
    phone varchar(20)
);

-- 2. library cards ,  зв'язок 1:1 з readers
create table library_cards (
    id uuid primary key default gen_random_uuid(),
    reader_id uuid unique not null references readers(id) on delete cascade,
    card_number varchar(20) unique not null,
    issue_date date not null default current_date
);

-- 3. books
create table books (
    id uuid primary key default gen_random_uuid(),
    title varchar(255) not null,
    isbn varchar(20) unique not null,
    published_year int check (published_year > 0 and published_year <= extract(year from current_date)),
    total_copies int check (total_copies >= 0) default 1
);

-- 4. authors
create table authors (
    id uuid primary key default gen_random_uuid(),
    first_name varchar(100) not null,
    last_name varchar(100) not null
);

-- 5. join table для зв'язку many:many
create table book_authors (
    book_id uuid references books(id) on delete cascade,
    author_id uuid references authors(id) on delete cascade,
    primary key (book_id, author_id)
);

-- 6. loans зв'язок 1:many від readers до books
create table loans (
    id uuid primary key default gen_random_uuid(),
    book_id uuid not null references books(id) on delete restrict,
    reader_id uuid not null references readers(id) on delete cascade,
    loan_date date not null default current_date,
    return_date date,
    is_returned boolean default false,
    check (return_date is null or return_date >= loan_date)
);

-- indexes
create index idx_loans_book_id on loans(book_id);
create index idx_loans_reader_id on loans(reader_id);
create index idx_books_title on books(title);