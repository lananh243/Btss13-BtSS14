USE ss14_second;

-- 2
drop procedure increasesalary;
DELIMITER //

create procedure increasesalary(
    in emp_id int,
    in new_salary decimal(10,2),
    in reason text
)
begin
    declare old_salary decimal(10,2);
    
    start transaction;

    select salary into old_salary from salaries where employee_id = emp_id;

    if old_salary is null then
        signal sqlstate '45000'
        set message_text = 'Nhân viên không tồn tại!';
        rollback;
    end if;

    insert into salary_history (employee_id, old_salary, new_salary, reason, change_date)
    values (emp_id, old_salary, new_salary, reason, now());

    update salaries 
    set salary = new_salary 
    where employee_id = emp_id;

    commit;
end;
// DELIMITER //
alter table salaries add column salary decimal(10,2) not null;

call increasesalary(5, 5000.00, 'Tăng lương định kỳ');

select * from salaries;
delete from salary_history;
select * from salary_history;

-- 4
drop procedure DeleteEmployee;

DELIMITER //
create procedure DeleteEmployee(emp_id int)
begin
	declare old_salary decimal(10,2);
    start transaction;
     select salary into old_salary from salaries where employee_id = emp_id;
	if (select count(employee_id) from employees where employee_id = emp_id) = 0
		then signal sqlstate '45000'
        set message_text = 'Nhân viên không tồn tại!';
        rollback;
	else
		insert into salary_history (employee_id, old_salary, new_salary, reason, change_date)
		values (emp_id, old_salary, NULL, 'Xóa nhân viên', now());

		delete from salaries
        where employee_id = emp_id;
        
        delete from employees
        where employee_id = emp_id;
		commit;
	end if;
end;
// DELIMITER //
-- 5
call DeleteEmployee(6);

select * from employees;