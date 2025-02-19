use Bai4ss13;

-- 2
create table student_status(
	student_id int primary key,
    foreign key(student_id) references students(student_id),
    status enum('ACTIVE', 'GRADUATED', 'SUSPENDED')
);
-- 3
INSERT INTO student_status (student_id, status) VALUES

(1, 'ACTIVE'), -- Nguyễn Văn An có thể đăng ký

(2, 'GRADUATED');

-- 4

drop procedure Register_course_student;
DELIMITER //
create procedure Register_course_student (
	p_student_name varchar(50),
    p_course_name varchar(100)
)
begin
declare enrollment_count int;
declare check_status varchar(50);
declare c_available_seats int;
declare s_student_id int;
declare c_course_id int;
start transaction;
select count(enrollment_id) into enrollment_count from enrollments;
select status into check_status from student_status limit 1;
select available_seats, course_id into c_available_seats, c_course_id  from courses c where c.course_name = p_course_name;
select student_id into s_student_id from students s where s.student_name = p_student_name;
	if s_student_id is null then
		insert into enrollments_history (student_id, course_id, action, timestamp, warning)
		values(s_student_id, c_course_id, NULL, curdate(), 'FAILED: Student does not exist');
        rollback;
	elseif c_course_id is null then
		insert into enrollments_history (student_id, course_id, action, timestamp, warning)
		values(s_student_id, c_course_id, NULL, curdate(), 'FAILED: Course does not exist');
        rollback;
	else
	if enrollment_count > 0 then
		insert into enrollments_history (student_id, course_id, action, timestamp, warning)
		values(s_student_id, c_course_id, NULL, curdate(), 'FAILED: Already enrolled');
        rollback;
	else
    if check_status = 'GRADUATED' or check_status = 'SUSPENDED' then
		signal sqlstate '45000';
        insert into enrollments_history (student_id, course_id, action, timestamp, warning)
		values(s_student_id, c_course_id, NULL, curdate(), 'FAILED: Student not eligible');
        rollback;
	else
    if c_available_seats <= 0 then
		insert into enrollments_history (student_id, course_id, action, timestamp, warning)
		values(s_student_id, c_course_id, NULL, curdate(), 'FAILED: No available seats');
        rollback;
	else
        insert into enrollments (student_id, course_id)
        values(s_student_id, c_course_id);
        
        update courses
        set available_seats = available_seats - 1
        where course_id = c_course_id;

        
        insert into enrollments_history (student_id, course_id, action, timestamp, warning)
		values(s_student_id, c_course_id, NULL, curdate(), 'REGISTERED');
        commit;
	end if;
    end if;
    end if;
    end if;
end;
// DELIMITER //

-- 5
call Register_course_student('Nguyễn Văn An', 'Lập trình C');

-- 6
select * from enrollments;
select * from courses;
select * from enrollments_history;
select * from students;
