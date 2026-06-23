--Не оптимізовний робить однокові запити 2 раза через вкладений запит пілся having

explain analyze
select
	concat(c.name , ' ' , c.surname) as full_name,
    count(o.order_id) as total_orders
from opt_clients c
join opt_orders o on c.id = o.client_id
join opt_products p on o.product_id = p.product_id
where c.status = 'active' and p.product_category = 'Category1'
group by c.id
having count(o.order_id) > (
    select avg(order_count)
    from (
        select count(o2.order_id) as order_count
        from opt_clients c2
        join opt_orders o2 on c2.id = o2.client_id
        join opt_products p2 on o2.product_id = p2.product_id
        where c2.status = 'active' and p2.product_category = 'Category1'
        group by c2.id
    ) 
)
order by total_orders desc


-- Індекси

create index if not exists idx_clients_s_in_all on opt_clients(status) include (id, name, surname);
create index if not exists idx_product_cat on opt_products(product_category) include (product_id);
create index if not exists idx_orders_ids on opt_orders(client_id, product_id);


-- Оптимізовний
 
set enable_seqscan = off; -- тепер тільки по індексам

explain analyze
with clientOrders as (
    select
		concat(c.name , ' ' , c.surname) as full_name,
        count(o.order_id) as total_orders
    from opt_clients c
    join opt_orders o on c.id = o.client_id
    join opt_products p on o.product_id = p.product_id
    where c.status = 'active' and p.product_category = 'Category1'
    group by c.id
),
 avgQtyOrders as (
    select avg(total_orders) as avg_orders
    from clientOrders
)
select
	full_name,
    total_orders
from clientOrders
where total_orders > (select avg_orders from avgQtyOrders)
order by total_orders desc;

set enable_seqscan = on;