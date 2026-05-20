CREATE DATABASE QLDT_DB;
USE QLDR_DB;

CREATE TABLE Students (
    StudentID INT PRIMARY KEY,
    Name VARCHAR(100),
    Age INT,
    Status VARCHAR(50),
    TotalCredits INT
);

CREATE TABLE Courses (
    CourseID INT PRIMARY KEY,
    CourseName VARCHAR(100),
    MaxStudents INT,
    CurrentStudents INT
);

CREATE TABLE Enrollments (
    EnrollmentID INT PRIMARY KEY,
    StudentID INT,
    CourseID INT,
    Grade FLOAT
);

CREATE TABLE Student_Logs (
    LogID INT PRIMARY KEY AUTO_INCREMENT,
    StudentID INT,
    ActionType VARCHAR(50),
    ActionDate DATETIME
);

CREATE TABLE Grade_History (
    HistoryID INT PRIMARY KEY AUTO_INCREMENT,
    EnrollmentID INT,
    OldGrade FLOAT,
    NewGrade FLOAT,
    ChangeDate DATETIME
);

CREATE TABLE Deleted_Students (
    StudentID INT PRIMARY KEY,
    Name VARCHAR(100),
    Age INT,
    Status VARCHAR(50),
    TotalCredits INT
);

INSERT INTO Students (StudentID, Name, Age, Status, TotalCredits) VALUES
(1, 'Nguyen Van A', 20, 'Studying', 45),
(2, 'Tran Thi B', 21, 'Studying', 115),
(3, 'Le Van C', 22, 'Studying', 125),
(4, 'Phan Thi D', 19, 'Studying', 15);

INSERT INTO Courses (CourseID, CourseName, MaxStudents, CurrentStudents) VALUES
(101, 'Co so du lieu', 40, 2),
(102, 'Lap trinh Web', 30, 0),
(103, 'Cau truc du lieu', 2, 2);

INSERT INTO Enrollments (EnrollmentID, StudentID, CourseID, Grade) VALUES
(1001, 1, 101, 8.5),
(1002, 2, 101, 7.0),
(1003, 3, 103, 9.0),
(1004, 1, 103, 6.5);


-- câu 1 

DELIMITER $$            
CREATE TRIGGER trg_after_student_insert
AFTER INSERT ON Students        
FOR EACH ROW                  
BEGIN
    INSERT INTO Student_Logs (StudentID, ActionType, ActionDate)
    VALUES (NEW.StudentID, 'INSERT', NOW());
END$$
DELIMITER ;  

-- CÂU 2 

DELIMITER $$

CREATE TRIGGER trg_before_student_insert_uppercase
BEFORE INSERT ON Students     
FOR EACH ROW
BEGIN
    SET NEW.Name = UPPER(NEW.Name);
END$$

DELIMITER ;

-- câu 3 

DELIMITER $$            
CREATE TRIGGER trg_before_student_insert
BEFORE INSERT ON Students        
FOR EACH ROW                  
BEGIN
	IF NEW.Age < 18 THEN        
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Sinh viên phải từ 18 tuổi trở lên';
END IF;
END$$
DELIMITER ;

-- CÂU 4 

CREATE TABLE Grade_History (
    HistoryID INT PRIMARY KEY AUTO_INCREMENT,
    EnrollmentID INT NOT NULL,
    OldGrade DECIMAL(4,2), 
    NewGrade DECIMAL(4,2), 
    ChangeDate DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_history_enrollment FOREIGN KEY (EnrollmentID)
        REFERENCES Enrollments (EnrollmentID)
        ON DELETE CASCADE ON UPDATE CASCADE
);


DELIMITER $$
 
CREATE TRIGGER trg_after_grade_update
AFTER UPDATE ON Enrollments
FOR EACH ROW
BEGIN
    IF (OLD.Grade <> NEW.Grade
        OR (OLD.Grade IS NULL AND NEW.Grade IS NOT NULL)
        OR (OLD.Grade IS NOT NULL AND NEW.Grade IS NULL)) THEN
			INSERT INTO Grade_History (EnrollmentID, OldGrade, NewGrade, ChangeDate)
			VALUES (NEW.EnrollmentID, OLD.Grade, NEW.Grade, NOW());
    END IF;
END$$
DELIMITER ;

-- câu 5

CREATE TABLE Deleted_Students (
    StudentID INT NOT NULL,
    Name VARCHAR(100) NOT NULL,
    Age INT NOT NULL,
    Status ENUM('Active', 'Inactive', 'Graduated', 'Suspended') NOT NULL,
    TotalCredits INT NOT NULL,
    DeletedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

DELIMITER $$
CREATE TRIGGER trg_before_student_delete_backup
BEFORE DELETE ON Students
FOR EACH ROW
BEGIN
    INSERT INTO Deleted_Students (StudentID, Name, Age, Status, TotalCredits, DeletedAt)
    VALUES (OLD.StudentID, OLD.Name, OLD.Age, OLD.Status, OLD.TotalCredits, NOW());
END$$
DELIMITER ;

-- câu 6

DELIMITER $$
 
CREATE TRIGGER trg_after_enrollment_insert_sync
AFTER INSERT ON Enrollments
FOR EACH ROW
BEGIN
    UPDATE Courses
    SET CurrentStudents = CurrentStudents + 1
    WHERE CourseID = NEW.CourseID;
END$$
 
DELIMITER ;

-- CÂU 7

DELIMITER $$
 
CREATE TRIGGER trg_after_enrollment_delete_sync
AFTER DELETE ON Enrollments
FOR EACH ROW
BEGIN
    UPDATE Courses
    SET CurrentStudents = CurrentStudents - 1
    WHERE CourseID = OLD.CourseID
      AND CurrentStudents > 0; -- để không bị âm
END$$
 
DELIMITER ;

-- câu 8

DELIMITER $$

CREATE TRIGGER trg_before_enrollment_insert_check_capacity
BEFORE INSERT ON Enrollments
FOR EACH ROW
BEGIN
    IF (SELECT CurrentStudents FROM Courses WHERE CourseID = NEW.CourseID) 
       >= 
       (SELECT MaxStudents FROM Courses WHERE CourseID = NEW.CourseID) THEN 
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Môn học đã đủ số lượng sinh viên tối đa';

    END IF;
END$$
DELIMITER ;


-- câu 9 

DELIMITER $$

CREATE TRIGGER trg_before_student_update_check_graduated
BEFORE UPDATE ON Students
FOR EACH ROW
BEGIN
    IF NEW.Status = 'Graduated' AND NEW.TotalCredits < 120 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Sinh viên chưa đủ tín chỉ để tốt nghiệp';
    END IF;
END$$

DELIMITER ;

-- câu 10

DELIMITER $$

CREATE TRIGGER trg_before_course_delete_cascade
BEFORE DELETE ON Courses
FOR EACH ROW
BEGIN
    DELETE FROM Enrollments WHERE CourseID = OLD.CourseID;
END$$

DELIMITER ;

-- câu 11

DELIMITER $$

CREATE TRIGGER trg_before_enrollment_insert_check_max_courses
BEFORE INSERT ON Enrollments
FOR EACH ROW
BEGIN
    IF (SELECT COUNT(*) FROM Enrollments 
        WHERE StudentID = NEW.StudentID AND Grade IS NULL) >= 5 THEN

        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Sinh viên không được học quá 5 môn cùng lúc';

    END IF;
END$$

DELIMITER ;
 

