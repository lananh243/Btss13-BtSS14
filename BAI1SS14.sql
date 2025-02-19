CREATE DATABASE ss14_first;
USE ss14_first;
-- 1. Bảng customers (Khách hàng)
CREATE TABLE customers (
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Bảng orders (Đơn hàng)
CREATE TABLE orders (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_amount DECIMAL(10,2) DEFAULT 0,
    status ENUM('Pending', 'Completed', 'Cancelled') DEFAULT 'Pending',
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE
);

-- 3. Bảng products (Sản phẩm)
CREATE TABLE products (
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Bảng order_items (Chi tiết đơn hàng)
CREATE TABLE order_items (
    order_item_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    price DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- 5. Bảng inventory (Kho hàng)
CREATE TABLE inventory (
    product_id INT PRIMARY KEY,
    stock_quantity INT NOT NULL CHECK (stock_quantity >= 0),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE
);

-- 6. Bảng payments (Thanh toán)
CREATE TABLE payments (
    payment_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT NOT NULL,
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    amount DECIMAL(10,2) NOT NULL,
    payment_method ENUM('Credit Card', 'PayPal', 'Bank Transfer', 'Cash') NOT NULL,
    status ENUM('Pending', 'Completed', 'Failed') DEFAULT 'Pending',
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE
);


-- 2
DELIMITER //
create trigger check_order 
before insert on order_items
for each row
begin
	declare stock_quantity int;
    select quantity into stock_quantity from products where product_id = NEW.product_id;
	if stock_quantity > NEW.quantity then
		signal sqlstate '45000'
			set message_text = "Không đủ hàng trong kho!";
	end if;
end;

// DELIMITER //

-- 3
DELIMITER //
create trigger Update_total_amount 
after insert on order_items
for each row
begin
	declare item_total decimal;
	set item_total = NEW.price * NEW.quantity;
	update orders
    set total_amount = total_amount + item_total
    where order_id = NEW.order_id;
end;

// DELIMITER //

-- 4
DELIMITER //
create trigger check_inventory_quantity
before update on order_items
for each row
begin
	declare stock_quantity int;
    select quantity into stock_quantity from products where product_id = NEW.product_id;
	if stock_quantity < NEW.quantity then
		signal sqlstate '45000'
			set message_text = "Không đủ hàng trong kho để cập nhật số lượng!";
	end if;
end;
// DELIMITER //

-- 5
DELIMITER //
create trigger update_total_money
after update on order_items 
for each row
begin
	declare item_total_new decimal;
    declare item_total_old decimal;
	set item_total_new = NEW.price * NEW.quantity;
    set item_total_old = OLD.price * OLD.quantity;
    
    update orders
    set total_amount = total_amount - item_total_old + item_total_new
    where order_id = NEW.order_id;
    
end;
// DELIMITER //

-- 6
DELIMITER //
create trigger delete_order
before delete on orders
for each row
begin
	if OLD.status = 'Completed' then
		signal sqlstate '45000'
			set message_text = "Không thể xóa đơn hàng đã thanh toán!";
    end if;
end;
// DELIMITER //

-- 7
DELIMITER //
create trigger refund_into_warehouse 
after delete on order_items
for each row
begin
	update products
    set quantity = quantity + OLD.quantity
    where product_id = OLD.quantity;
end;

// DELIMITER //

-- 8
drop trigger check_order;
drop trigger Update_total_amount;
drop trigger check_inventory_quantity;
drop trigger update_total_money;
drop trigger delete_order;
drop trigger refund_into_warehouse;