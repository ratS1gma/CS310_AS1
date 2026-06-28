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
