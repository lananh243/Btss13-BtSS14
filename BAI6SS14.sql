USE ss14_second;

-- 2
DELIMITER //
create trigger check_phone_length 
before update on employees
for each row
begin
	if length(NEW.phone) <> 10 then
		signal sqlstate '45000'
        set message_text = 'Số điện thoại không đủ hoặc nhiều hơn 10 chữ số';
	end if;
end;
// DELIMITER //

-- 3
CREATE TABLE notifications (

    notification_id INT PRIMARY KEY AUTO_INCREMENT,

    employee_id INT NOT NULL,

    message TEXT NOT NULL,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

 FOREIGN KEY (employee_id) REFERENCES employees(employee_id) ON DELETE CASCADE

);

-- 4
DELIMITER //
create trigger add_employee_notification
after insert on employees
for each row
begin
	insert into notifications (message, created_at)
    values (concat('Chào mừng', '+', New.name));
end;
// DELIMITER //


-- 5

DELIMITER //
create procedure AddNewEmployeeWithPhone(
	emp_name varchar(255),
    emp_email varchar(255),
    emp_phone varchar(20),
    emp_hire_date date,
    emp_department_id int
)
begin
	declare exit handler for sqlexception
    begin
		rollback;
    end;
	start transaction;
	if emp_phone <> 10 then 
		signal sqlstate '45000'
			set message_text = 'Số điện thoại không đủ hoặc nhiều hơn 10 chữ số';
		rollback;
	else
		insert into employees(name, email, phone, hire_date, department)
        values(emp_name, emp_email, emp_phone, emp_hire_date, emp_department_id);
		commit;
	end if;
end;
// DELIMITER //