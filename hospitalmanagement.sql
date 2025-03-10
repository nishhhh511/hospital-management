# hospital-management
-- Step 1: Creating Tables
CREATE TABLE Patient (
    Patient_ID INT PRIMARY KEY,
    Name VARCHAR(255),
    Date_of_Birth DATE CHECK (Date_of_Birth <= CURDATE()),
    Contact_Info VARCHAR(255),
    Insurance_Provider VARCHAR(255)
);

CREATE TABLE Doctor (
    Doctor_ID INT PRIMARY KEY,
    Name VARCHAR(255),
    Specialization VARCHAR(255) NOT NULL
);

CREATE TABLE Appointment (
    Appointment_ID INT PRIMARY KEY,
    Patient_ID INT,
    Doctor_ID INT,
    Date DATE,
    Time TIME,
    Reason VARCHAR(255),
    FOREIGN KEY (Patient_ID) REFERENCES Patient(Patient_ID),
    FOREIGN KEY (Doctor_ID) REFERENCES Doctor(Doctor_ID),
    CONSTRAINT unique_patient_date UNIQUE (Patient_ID, Date)
);

CREATE TABLE Medical_Record (
    Record_ID INT PRIMARY KEY,
    Patient_ID INT,
    Allergies VARCHAR(255),
    Diagnoses VARCHAR(255),
    Treatment_Plans VARCHAR(255),
    Nurse_ID INT,
    FOREIGN KEY (Patient_ID) REFERENCES Patient(Patient_ID)
);

CREATE TABLE Room (
    Room_Number INT PRIMARY KEY,
    Room_Type VARCHAR(255) CHECK (Room_Type IN ('Private', 'Semi-private', 'General Ward')),
    Patient_ID INT,
    FOREIGN KEY (Patient_ID) REFERENCES Patient(Patient_ID)
);

CREATE TABLE Payment (
    Payment_ID INT PRIMARY KEY,
    Patient_ID INT,
    Amount DECIMAL(10,2),
    Payment_Method VARCHAR(255),
    Date DATE,
    FOREIGN KEY (Patient_ID) REFERENCES Patient(Patient_ID)
);

-- Step 2: Inserting Sample Data
INSERT INTO Patient (Patient_ID, Name, Date_of_Birth, Contact_Info, Insurance_Provider) VALUES
(1, 'John Doe', '1985-05-15', '555-1234', 'Blue Cross'),
(2, 'Jane Smith', '1990-11-22', '555-5678', 'Aetna');

INSERT INTO Doctor (Doctor_ID, Name, Specialization) VALUES
(1, 'Dr. Alice Green', 'Cardiology'),
(2, 'Dr. Bob Brown', 'Pediatrics');

INSERT INTO Appointment (Appointment_ID, Patient_ID, Doctor_ID, Date, Time, Reason) VALUES
(1, 1, 1, '2023-06-15', '10:00:00', 'Chest pain'),
(2, 2, 2, '2023-06-16', '14:30:00', 'Well-child visit');

INSERT INTO Medical_Record (Record_ID, Patient_ID, Allergies, Diagnoses, Treatment_Plans, Nurse_ID) VALUES
(1, 1, 'Penicillin', 'Hypertension', 'Medication, Diet', NULL),
(2, 2, 'None', 'Healthy', 'Routine Checkup', NULL);

INSERT INTO Room (Room_Number, Room_Type, Patient_ID) VALUES
(101, 'Private', 1),
(102, 'Semi-private', 2);

INSERT INTO Payment (Payment_ID, Patient_ID, Amount, Payment_Method, Date) VALUES
(1, 1, 500.00, 'Credit card', '2023-06-15'),
(2, 2, 75.00, 'Insurance', '2023-06-16');

-- Step 3: Retrieving Data (Queries)
SELECT * FROM Patient;

SELECT A.Appointment_ID, P.Name AS Patient, D.Name AS Doctor, A.Date, A.Time, A.Reason
FROM Appointment A
JOIN Patient P ON A.Patient_ID = P.Patient_ID
JOIN Doctor D ON A.Doctor_ID = D.Doctor_ID;

-- Step 4: Creating Views
CREATE VIEW PatientAppointments AS
SELECT P.Name AS Patient, D.Name AS Doctor, A.Date, A.Time, A.Reason
FROM Appointment A
JOIN Patient P ON A.Patient_ID = P.Patient_ID
JOIN Doctor D ON A.Doctor_ID = D.Doctor_ID;

CREATE VIEW PaymentSummary AS
SELECT Patient_ID, SUM(Amount) AS Total_Payment
FROM Payment
GROUP BY Patient_ID;

-- Step 5: Creating Triggers
DELIMITER //
CREATE TRIGGER prevent_duplicate_appointments
BEFORE INSERT ON Appointment
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM Appointment WHERE Patient_ID = NEW.Patient_ID AND Date = NEW.Date) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Duplicate appointment not allowed';
    END IF;
END;
//
DELIMITER ;

-- Step 6: Creating Cursor for Treatment Plans Update
DELIMITER //
CREATE PROCEDURE UpdateTreatmentPlans()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE rec_ID INT;
    DECLARE diag VARCHAR(255);
    
    DECLARE cur CURSOR FOR SELECT Record_ID, Diagnoses FROM Medical_Record;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    OPEN cur;

    read_loop: LOOP
        FETCH cur INTO rec_ID, diag;
        IF done THEN
            LEAVE read_loop;
        END IF;

        UPDATE Medical_Record 
        SET Treatment_Plans = CASE 
            WHEN diag = 'Diabetes' THEN 'Diet, Exercise'
            WHEN diag = 'Hypertension' THEN 'Medication, Diet'
            ELSE 'General checkup'
        END
        WHERE Record_ID = rec_ID;
    END LOOP;

    CLOSE cur;
END;
//
DELIMITER ;
