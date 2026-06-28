
### Task1 (`calculate_order_total`)
Реалізовано скалярну SQL-функцію. Для підрахунку загальної суми використовується агрегатна функція `SUM(quantity * price)`. Щоб уникнути повернення значення `NULL` для замовлень, у яких ще немає доданих товарів, застосовано обгортку `COALESCE(..., 0)`.

### Task2 (`create_order`)
Процедура (PL/pgSQL) для створення нового запису в таблиці `orders`. Перед виконанням операції `INSERT` проводиться валідація наявності клієнта в таблиці `customers` за допомогою конструкції `IF EXISTS (SELECT 1 ...)`. У разі спроби створення замовлення для неіснуючого клієнта виконання зупиняється викликом `RAISE EXCEPTION`. Час створення генерується автоматично через `LOCALTIMESTAMP`.

### Task3 (`add_product_to_order`)
Процедура містить послідовну валідацію вхідних даних через ланцюг умов `IF / ELSIF`:
* Перевіряється існування `order_id` та `product_id` за допомогою `NOT EXISTS`.
* Блокуються запити з від'ємною або нульовою кількістю товару (`p_quantity <= 0`).
* Перевіряється наявність достатньої кількості товару на складі (`stock_quantity`).
Після успішної валідації актуальна ціна товару зберігається у локальну змінну через `SELECT INTO`. Далі виконується вставка запису в таблицю `order_items` та відповідне зменшення залишку в таблиці `products` (через операцію `UPDATE`).

### Task4(`update_order_total`)
Тригер прив'язаний до подій `AFTER INSERT OR UPDATE OR DELETE` на таблиці `order_items`. 
Для уникнення помилок при видаленні рядків реалізовано перевірку типу операції через системну змінну `TG_OP`. 
* Якщо виконується `DELETE`, ідентифікатор замовлення вилучається зі змінної `OLD`.
* Для подій `INSERT` та `UPDATE` використовується змінна `NEW`.
Після отримання ідентифікатора виконується виклик функції `calculate_order_total` для оновлення поля `total_amount` у таблиці `orders`. Тригер коректно повертає `OLD` або `NEW` залежно від контексту виклику.

### Task5 (`insert_logs`)
Тригер рівня рядка, що реагує на подію `AFTER INSERT` у таблиці `orders`. Процедура отримує значення `NEW.order_id` та `NEW.customer_id` і формує новий запис в аудиторській таблиці `order_log` з міткою дії `'create'`.

---

## Bonus task3
```text
Hash Join  (cost=27.09..41.32 rows=7 width=274) (actual time=0.016..0.018 rows=2.00 loops=1)
  Hash Cond: (p.product_id = oi.product_id)
  Buffers: shared hit=2 dirtied=2
  ->  Seq Scan on products p  (cost=0.00..13.00 rows=300 width=222) (actual time=0.006..0.006 rows=5.00 loops=1)
        Buffers: shared hit=1 dirtied=1
  ->  Hash  (cost=27.00..27.00 rows=7 width=28) (actual time=0.006..0.006 rows=2.00 loops=1)
        Buckets: 1024  Batches: 1  Memory Usage: 9kB
        Buffers: shared hit=1 dirtied=1
        ->  Seq Scan on order_items oi  (cost=0.00..27.00 rows=7 width=28) (actual time=0.004..0.004 rows=2.00 loops=1)
              Filter: (order_id = 1)
              Rows Removed by Filter: 3
              Buffers: shared hit=1 dirtied=1
Planning Time: 0.127 ms
Execution Time: 0.039 ms
```
**Висновок аналізу:** СУБД PostgreSQL використала алгоритм `Hash Join`. Спочатку виконується послідовне сканування (`Seq Scan`) таблиці `order_items` із накладанням фільтра за `order_id = 1`. З отриманих результатів у пам'яті генерується хеш-таблиця (`Hash`). Після цього виконується послідовне сканування таблиці `products`, рядки якої перевіряються на збіг ключів у хеш-таблиці. Індексне сканування (`Index Scan`) не було задіяне планувальником, оскільки витрати на звернення до індексу для малого обсягу даних перевищують витрати на послідовне сканування.