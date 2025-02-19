CREATE DATABASE ss14_second;
USE ss14_second;
-- 1. Bảng departments (Phòng ban)
CREATE TABLE departments (
    department_id INT PRIMARY KEY AUTO_INCREMENT,
    department_name VARCHAR(255) NOT NULL
);

-- 2. Bảng employees (Nhân viên)
CREATE TABLE employees (
    employee_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    hire_date DATE NOT NULL,
    department_id INT NOT NULL,
    FOREIGN KEY (department_id) REFERENCES departments(department_id) ON DELETE CASCADE
);

-- 3. Bảng attendance (Chấm công)
CREATE TABLE attendance (
    attendance_id INT PRIMARY KEY AUTO_INCREMENT,
    employee_id INT NOT NULL,
    check_in_time DATETIME NOT NULL,
    check_out_time DATETIME,
    total_hours DECIMAL(5,2),
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id) ON DELETE CASCADE
);

-- 4. Bảng salaries (Bảng lương)
CREATE TABLE salaries (
    employee_id INT PRIMARY KEY,
    base_salary DECIMAL(10,2) NOT NULL,
    bonus DECIMAL(10,2) DEFAULT 0,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id) ON DELETE CASCADE
);

-- 5. Bảng salary_history (Lịch sử lương)
CREATE TABLE salary_history (
    history_id INT PRIMARY KEY AUTO_INCREMENT,
    employee_id INT NOT NULL,
    old_salary DECIMAL(10,2),
    new_salary DECIMAL(10,2),
    change_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reason TEXT,
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id) ON DELETE CASCADE
);

-- 2
drop trigger add_employee;
DELIMITER //
create trigger add_employee
before insert on employees
for each row
begin
	set NEW.email = concat(NEW.email, '@company.com');
end;
// DELIMITER //
drop trigger add_new_emp;
-- 3
DELIMITER //
create trigger add_new_emp
after insert on employees
for each row
begin
	if not exists (select 1 from salaries where employee_id = NEW.employee_id) then
		insert into salaries(employee_id, base_salary, bonus, last_updated)
		values(NEW.employee_id, 10000.00, 0.00, curdate());
    end if;
end;
// DELIMITER //
drop trigger salary_history;
-- 4
DELIMITER //
create trigger salary_history
after delete on attendance
for each row
begin 
	insert into salary_history(employee_id, old_salary, change_date)
    values(OLD.employee_id, (select base_salary from salaries where employee_id = OLD.employee_id limit 1), curdate());
end;
// DELIMITER //

-- 5
drop trigger automatically_updated;
DELIMITER //
create trigger automatically_updated
before update on attendance
for each row
begin
	if NEW.check_out_time is not null and NEW.check_in_time is not null then
        set NEW.total_hours = timestampadd(SECOND, NEW.check_in_time, NEW.check_out_time) / 3600;
    end if;
end;
// DELIMITER //

-- 6
INSERT INTO departments (department_name) VALUES 

('Phòng Nhân Sự'),

('Phòng Kỹ Thuật');

INSERT INTO employees (name, email, phone, hire_date, department_id)

VALUES ('Nguyễn Văn A', 'nguyenvana', '0987654321', '2024-02-17', 1);

SELECT * FROM employees;

-- 7
INSERT INTO employees (name, email, phone, hire_date, department_id)

VALUES ('Trần Thị B', 'tranthib@company.com', '0912345678', '2024-02-17', 2);

select * from salaries;

-- 8
INSERT INTO attendance (employee_id, check_in_time)

VALUES (5, '2024-02-17 08:00:00');

UPDATE attendance

SET check_out_time = '2024-02-17 17:00:00'

WHERE employee_id = 5;

select * from attendance;



