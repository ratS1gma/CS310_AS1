--task1

create or replace function calculate_order_total(p_order_id int)
returns numeric(10,2)
as $$
	select coalesce(sum(quantity*price), 0) from order_items where order_id = p_order_id;
$$ language sql;


--task2

create or replace procedure create_order(p_customer_id int)
as $$
begin
	if p_customer_id in (select customer_id from customers) then
		insert into orders(customer_id,order_date,total_amount) values
		(p_customer_id , LOCALTIMESTAMP , 0);

	else
		raise exception 'Неможливо створити order оскільки customer_id:% не існує',p_customer_id;
	end if;
end;
$$ language plpgsql;

-- task3

create  or replace procedure add_product_to_order(p_order_id int, p_product_id int, p_quantity int)
as $$
declare
	p_product_price numeric(10,2);
begin
	if not exists (select 1 from orders where order_id = p_order_id) then
		raise exception 'Неможлтво додати продукти до order_id:% оскільки його не існує',p_order_id;
	elseif not exists (select 1 from products where product_id = p_product_id) then
		raise exception 'Неможливо додати товар до order з product_id:% оскільки такого не існує',p_product_id;
	elseif p_quantity <= 0 then
		raise exception 'Неможливо додати в order товарів кількістю <=0';
	elseif p_quantity > (select stock_quantity from products where product_id=p_product_id) then
		raise exception 'Неможливо додати в order товарів більше ніж на складі';
	else
		select price into p_product_price from products where product_id = p_product_id;
		insert into order_items(order_id,product_id,quantity,price) values
		(p_order_id, p_product_id, p_quantity, p_product_price);

		update products
		set stock_quantity = stock_quantity - p_quantity
		where product_id = p_product_id;

	end if;
end;
$$ language plpgsql;

--task4

create or replace function update_order_total()
returns trigger
as $$
declare 
	p_order_id int;
begin
	if tg_op = 'DELETE' then
		p_order_id := old.order_id;
	else
		p_order_id := new.order_id;
	end if;
	
	update orders
	set total_amount = calculate_order_total(p_order_id)
	where order_id = p_order_id;

	if tg_op = 'DELETE' then
		return old;
	end if;
	return new;
end;
$$ language plpgsql;


create or replace trigger trg_order_itm after insert or update or delete on order_items 
for each row 
execute function update_order_total();


--task5
create or replace function insert_logs()
returns trigger
as $$
begin
	insert into order_log(order_id,customer_id,action,log_date) values
	(new.order_id,new.customer_id,'create',LOCALTIMESTAMP);

	return new;
end;
$$ language plpgsql;

create or replace trigger trg_order after insert on orders
for each row 
execute function insert_logs();

--task6

insert into customers(full_name,email,balance) values
('test test','test@test.com','1000');

insert into products(product_name,price,stock_quantity) values
('test_p',100,10);

call create_order(5);

call add_product_to_order(4,6,6);

select * from orders where  order_id = 4;

select * from order_items where order_id = 4;

select * from order_log where order_id = 4;
