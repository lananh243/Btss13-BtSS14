USE ss14_first;

-- 2
DELIMITER //
create trigger check_value
before insert on payments
for each row
begin
	declare od_total_amount decimal;
    select total_amount into od_total_amount from orders where order_id = NEW.order_id;
    
    if NEW.amount < od_total_amount then
		signal sqlstate '45000'
        set message_text = 'Số tiền thanh toán không khớp với tổng đơn hàng!';
	end if;
end;
// DELIMITER //

-- 3
CREATE TABLE order_logs (

    log_id INT PRIMARY KEY AUTO_INCREMENT,

    order_id INT NOT NULL,

    old_status ENUM('Pending', 'Completed', 'Cancelled'),

    new_status ENUM('Pending', 'Completed', 'Cancelled'),

    log_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE

);

-- 4
DELIMITER //
create trigger after_update_order_status
after update on orders
for each row
begin
    if OLD.status <> NEW.status then
		insert into order_logs(order_id, old_status, new_status, log_date)
        values(NEW.order_id, OLD.status, NEW.status, now());
	end if;
end;
// DELIMITER //

-- 5
DELIMITER //

create procedure sp_update_order_status_with_payment(
    p_order_id int,
    p_new_status varchar(20),
    p_payment_date datetime,
    p_amount decimal(10, 2),
    p_payment_method varchar(50)
)
begin
    declare current_status varchar(20);
    
    START TRANSACTION;

    select status into current_status
    from orders
    where order_id = p_order_id;

    if current_status = p_new_status then
        rollback;
        signal sqlstate '45000' set message_text = 'Đơn hàng đã có trạng thái này!';
    end if;

    if p_new_status = 'Completed' then
        insert into payments (order_id, payment_date, amount, payment_method, status)
        values (p_order_id, p_payment_date, p_amount, p_payment_method, 'Completed');
    end if;

    update orders
    set status = p_new_status
    where order_id = p_order_id;

    commit;

end ;
// DELIMITER //

-- 6
INSERT INTO customers (name, email, phone, address) VALUES 
('Nguyễn Văn A', 'vana@example.com', '0123456789', '123 Đường A'),
('Trần Thị B', 'thib@example.com', '0987654321', '456 Đường B'),
('Lê Văn C', 'vanc@example.com', '0912345678', '789 Đường C');

INSERT INTO orders (customer_id, total_amount, status) VALUES (1, 150.00, 'Pending');
INSERT INTO payments (order_id, amount, payment_method, status) 
VALUES 
(4, 150.00, 'Credit Card', 'Completed');

select * from orders;

call sp_update_order_status_with_payment(4, 'Completed', NOW(), 150.00, 'Credit Card');

-- 7
select * from order_logs;

-- 8
drop trigger check_value;
drop trigger after_update_order_status;
drop procedure sp_update_order_status_with_payment;