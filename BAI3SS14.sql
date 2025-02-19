USE ss14_first;

-- 2
DELIMITER //

create procedure sp_create_order(
    p_customer_id int,
    p_product_id int,
    p_quantity int
)
begin
    declare in_stock_quantity int;
    declare new_order_id int;
    declare product_price decimal(10,2);

    start transaction;

    select stock_quantity into in_stock_quantity 
    from inventory 
    where product_id = p_product_id; 

    if in_stock_quantity is null then
        signal sqlstate '45000' 
        set message_text = 'Sản phẩm không tồn tại trong kho!';
        rollback;
    end if;

    if in_stock_quantity < p_quantity then
        signal sqlstate '45000'
        set message_text = 'Không đủ hàng trong kho!';
        rollback;
    end if;

    select price into product_price 
    from products 
    where product_id = p_product_id;

    insert into orders (customer_id, order_date, total_amount, status)
    values (p_customer_id, NOW(), 0, 'Pending');

    set new_order_id = LAST_INSERT_ID();

    insert into order_items (order_id, product_id, quantity, price)
    values (new_order_id, p_product_id, p_quantity, product_price);

    update inventory
    set stock_quantity = stock_quantity - p_quantity
    where product_id = p_product_id;

    commit;
end;
// DELIMITER //

-- 4

DELIMITER //

create procedure sp_cancel_order(in p_order_id int)
begin
    declare order_status varchar(50);
    declare product_id int;
    declare order_quantity int;
    declare done int default 0;

    declare cur cursor for 
        select product_id, quantity from order_items where order_id = p_order_id;

    declare continue handler for not found set done = 1;

    start transaction;

    select status into order_status from orders where order_id = p_order_id for update;

    if order_status is null then
        signal sqlstate '45000'
        set message_text = 'đơn hàng không tồn tại!';
        rollback;
    end if;

    if order_status <> 'pending' then
        signal sqlstate '45000'
        set message_text = 'chỉ có thể hủy đơn hàng ở trạng thái pending!';
        rollback;
    end if;

    open cur;

    read_loop: loop
        fetch cur into product_id, order_quantity;
        if done then
            leave read_loop;
        end if;
 
        update inventory
        set stock_quantity = stock_quantity + order_quantity
        where product_id = product_id;
    end loop;

    close cur;
    
    delete from order_items where order_id = p_order_id;

    update orders
    set status = 'cancelled'
    where order_id = p_order_id;

    commit;
end;
// DELIMITER //

-- 6
set autocommit = 0;
drop procedure sp_create_order;
drop procedure sp_cancel_order;