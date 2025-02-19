use b5ss13;

-- 2
create table bank (
	bank_id int primary key auto_increment,
    bank_name varchar(255) not null,
    status enum('ACTIVE', 'ERROR')
);

-- 3
INSERT INTO bank (bank_id, bank_name, status) VALUES 

(1,'VietinBank', 'ACTIVE'),   

(2,'Sacombank', 'ERROR'),    

(3, 'Agribank', 'ACTIVE'); 

-- 4
alter table company_funds
add bank_id int,
add constraint fk_banks
foreign key(bank_id) references bank(bank_id);

-- 5
UPDATE company_funds SET bank_id = 1 WHERE balance = 50000.00;

INSERT INTO company_funds (balance, bank_id) VALUES (45000.00,2);

alter table payroll add column bank_id int;
-- 6
DELIMITER //
create trigger CheckBankStatus
before insert on payroll
for each row
begin
	declare message_text varchar(200);
    declare bank_status varchar(20);
    select status into bank_status from bank where bank_id = NEW.bank_id;
	if bank_status = 'ACTIVE' then
		set message_text = "Ngân hàng đang hoạt động";
	elseif bank_status = 'ERROR' then
		signal sqlstate '45000';
        set message_text = "Ngân hàng gặp lỗi ko thể chèn dữ liệu vào bảng payroll";
	end if;
end;

// DELIMITER //

-- 7
drop procedure TransferSalary;
DELIMITER //
create procedure TransferSalary (p_emp_id int)
begin
	declare com_balance decimal;
    declare emp_salary int;
    declare bank_status varchar(20);
    start transaction;
    select balance into com_balance from company_funds limit 1;
    select salary into emp_salary from employees where emp_id = p_emp_id limit 1;
    select status into bank_status from bank limit 1;
    
    if emp_salary > com_balance then
        insert into transaction_log(log_message, log_time)
			values('Quỹ không đủ tiền để trả lương', curdate());
            rollback;
	else
		if (select count(emp_id) from employees where emp_id = p_emp_id) = 0 then
			insert into transaction_log(log_message, log_time)
			values('Mã nhân viên ko tồn tại', curdate());
            rollback;
	else
		if bank_status = 'ERROR' then
			signal sqlstate '45000';
			insert into transaction_log(log_message, log_time)
				values('Ngân hàng có trạng thái ERROR', curdate());
			rollback;
	else
		update company_funds
        set balance = balance - emp_salary;
        
        insert into payroll (emp_id, salary, pay_date)
        values (p_emp_id, emp_salary, curdate());
        
        
        if not exists (
        select * from INFORMATION_SCHEMA.COLUMNS 
        where table_name = 'employees' and COLUMN_NAME = 'last_pay_date'
		) then
        alter table employees add column last_pay_date date;
		end if;
        
        update employees 
        set last_pay_date = curdate()
        where emp_id = p_emp_id;
        commit;
            
	end if;
    end if;
    end if;
end;
// DELIMITER //

select * from employees;
select * from transaction_log;
select * from company_funds;
select * from bank;
call TransferSalary(4);


