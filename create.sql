
-- MARK: - TABLES

CREATE TABLE blood_groups (
  group_id        NUMBER(2) CONSTRAINT blood_groups_pk PRIMARY KEY,
  description     VARCHAR2(30),
  name            VARCHAR2(3) NOT NULL
);

CREATE TABLE room_types (
  type_id         NUMBER(2) CONSTRAINT room_types_pk PRIMARY KEY,
  description     VARCHAR2(50),
  name            VARCHAR2(20) NOT NULL
);

CREATE TABLE patients (
  patient_id      NUMBER(6) CONSTRAINT patients_pk PRIMARY KEY,
  name       VARCHAR2(25),
  first_name      VARCHAR2(20),
  ssn             CHAR(13) UNIQUE,
  birth_date      DATE,
  address         VARCHAR2(50),
  phone           VARCHAR2(20) UNIQUE,
  email           VARCHAR2(30) UNIQUE,
  blood_group     NUMBER(2) REFERENCES blood_groups(group_id) NOT NULL,
  active          CHAR(1) DEFAULT 'Y' NOT NULL,
  inactive_date   DATE,
  CONSTRAINT ck_ssn CHECK (REGEXP_LIKE(ssn, '^[0-9]{13}$')),
  CONSTRAINT ck_patient_phone CHECK (phone IS NULL OR REGEXP_LIKE(phone, '^[0-9]{10}$')),
  CONSTRAINT ck_patient_email CHECK (email IS NULL OR REGEXP_LIKE(email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')),
  CONSTRAINT ck_patient_active CHECK (
    (active = 'Y' AND inactive_date IS NULL)
    OR (active = 'N' AND inactive_date IS NOT NULL)
  )
);

CREATE TABLE departments (
  department_id   NUMBER(4) CONSTRAINT departments_pk PRIMARY KEY,
  name            VARCHAR2(25) NOT NULL,
  phone           VARCHAR2(20) UNIQUE,
  email           VARCHAR2(30) UNIQUE,
  location        VARCHAR2(50),
  active          CHAR(1) DEFAULT 'Y' NOT NULL,
  inactive_date   DATE,
  CONSTRAINT contact_info_department CHECK (email IS NOT NULL OR phone IS NOT NULL),
  CONSTRAINT ck_department_active CHECK (
    (active = 'Y' AND inactive_date IS NULL)
    OR (active = 'N' AND inactive_date IS NOT NULL)
  ),
  CONSTRAINT ck_department_phone CHECK (phone IS NULL OR REGEXP_LIKE(phone, '^[0-9]{10}$')),
  CONSTRAINT ck_department_email CHECK (email IS NULL OR REGEXP_LIKE(email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'))
);

CREATE TABLE rooms (
  room_id         NUMBER(4) CONSTRAINT rooms_pk PRIMARY KEY,
  department_id   NUMBER(4) REFERENCES departments(department_id) NOT NULL,
  room_number     NUMBER(6) NOT NULL,
  bed_count       NUMBER(2) NOT NULL,
  type            NUMBER(2) REFERENCES room_types(type_id) NOT NULL,
  active          CHAR(1) DEFAULT 'Y' NOT NULL,
  inactive_date   DATE,
  CONSTRAINT unique_room UNIQUE (department_id, room_number),
  CONSTRAINT ck_bed_count CHECK (bed_count > 0 AND bed_count <= 10),
  CONSTRAINT ck_room_active CHECK (
    (active = 'Y' AND inactive_date IS NULL)
    OR (active = 'N' AND inactive_date IS NOT NULL)
  )
);

CREATE TABLE medicines (
  medicine_id     NUMBER(6) CONSTRAINT medicines_pk PRIMARY KEY,
  name            VARCHAR2(50) NOT NULL,
  form            VARCHAR2(20),
  standard_dose   VARCHAR2(20) NOT NULL,
  manufacturer    VARCHAR2(25)
);

CREATE TABLE employees (
  employee_id     NUMBER(6) CONSTRAINT employees_pk PRIMARY KEY,
  name       VARCHAR2(25) NOT NULL,
  first_name      VARCHAR2(20) NOT NULL,
  hire_date       DATE DEFAULT SYSDATE NOT NULL,
  birth_date      DATE NOT NULL,
  phone           VARCHAR2(20) UNIQUE,
  email           VARCHAR2(30) UNIQUE,
  salary          NUMBER(10,2),
  active          CHAR(1) DEFAULT 'Y' NOT NULL,
  inactive_date   DATE,
  CONSTRAINT contact_info_employee CHECK (email IS NOT NULL OR phone IS NOT NULL),
  CONSTRAINT ck_salary CHECK (salary > 0),
  CONSTRAINT ck_hire_age CHECK (MONTHS_BETWEEN(hire_date, birth_date) >= 216),
  CONSTRAINT ck_employee_phone CHECK (phone IS NULL OR REGEXP_LIKE(phone, '^[0-9]{10}$')),
  CONSTRAINT ck_employee_email CHECK (email IS NULL OR REGEXP_LIKE(email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')),
  CONSTRAINT ck_employee_active CHECK (
    (active = 'Y' AND inactive_date IS NULL)
    OR (active = 'N' AND inactive_date IS NOT NULL)
  )
);

CREATE TABLE doctors (
    employee_id      NUMBER(6) CONSTRAINT doctors_pk PRIMARY KEY,
    specialization    VARCHAR2(30) NOT NULL,
    license_code      VARCHAR2(10) NOT NULL UNIQUE,
    rank            VARCHAR2(20) NOT NULL,
    active           CHAR(1) DEFAULT 'Y' NOT NULL,
    inactive_date DATE,
    CONSTRAINT ck_doctor_rank CHECK (LOWER(rank) IN ('resident', 'specialist', 'senior')),
    CONSTRAINT ck_doctor_active CHECK (
        (active = 'Y' AND inactive_date IS NULL)
        OR (active = 'N' AND inactive_date IS NOT NULL)
    ),
    CONSTRAINT doctors_fk_employee 
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

CREATE TABLE nurses (
    employee_id      NUMBER(6) CONSTRAINT nurses_pk PRIMARY KEY,
    type             VARCHAR2(20) NOT NULL,
    room_id        NUMBER(4) REFERENCES rooms(room_id),
    active           CHAR(1) DEFAULT 'Y' NOT NULL,
    inactive_date DATE,
    CONSTRAINT ck_nurse_type CHECK (LOWER(type) IN ('generalist', 'medical', 'laboratory')),
    CONSTRAINT ck_nurse_active CHECK (
        (active = 'Y' AND inactive_date IS NULL)
        OR (active = 'N' AND inactive_date IS NOT NULL)
    ),
    CONSTRAINT nurses_fk_employee
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

CREATE TABLE admissions (
    admission_id    NUMBER(6) CONSTRAINT admissions_pk PRIMARY KEY,
    patient_id      NUMBER(6) NOT NULL,
    doctor_id        NUMBER(6) NOT NULL,
    room_id        NUMBER(4) NOT NULL,
    admission_date  DATE DEFAULT SYSDATE NOT NULL,
    discharge_date  DATE,
    diagnosis      VARCHAR2(100),
    discharge_status VARCHAR2(20),
    CONSTRAINT admissions_fk_patient
        FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    CONSTRAINT admissions_fk_doctor
        FOREIGN KEY (doctor_id) REFERENCES doctors(employee_id),
    CONSTRAINT admissions_fk_room
        FOREIGN KEY (room_id) REFERENCES rooms(room_id),
    CONSTRAINT admissions_ck_dates
        CHECK (discharge_date IS NULL OR discharge_date >= admission_date), 
    CONSTRAINT admissions_ck_discharge_status
        CHECK (discharge_status IS NULL OR LOWER(discharge_status) IN ('improved', 'recovered', 'deceased', 'transferred')),
    CONSTRAINT admissions_ck_date_status
        CHECK (
            (discharge_date IS NULL AND discharge_status IS NULL)
            OR (discharge_date IS NOT NULL AND discharge_status IS NOT NULL)
        )
);

CREATE TABLE admission_medicines (
    admission_id    NUMBER(6) NOT NULL,
    medicine_id   NUMBER(6) NOT NULL,
    dose            VARCHAR2(20) NOT NULL,
    frequency       VARCHAR2(20),
    administration_date   DATE NOT NULL,
    duration_days     NUMBER(3) NOT NULL,
    CONSTRAINT ck_admission_medicines_duration CHECK (duration_days > 0),
    CONSTRAINT admission_medicines_pk
        PRIMARY KEY (admission_id, medicine_id, administration_date),
    CONSTRAINT admission_medicines_fk_admissions
        FOREIGN KEY (admission_id) REFERENCES admissions(admission_id),
    CONSTRAINT admission_medicines_fk_medicine
        FOREIGN KEY (medicine_id) REFERENCES medicines(medicine_id)
);

-- MARK: - TRIGGERS

-- When an employee is deactivated, the corresponding doctors/nurses record is also deactivated
CREATE OR REPLACE TRIGGER trg_deactivate_employee
AFTER UPDATE OF active ON employees
FOR EACH ROW
WHEN (NEW.active = 'N')
BEGIN
  UPDATE doctors 
  SET active = 'N', inactive_date = :NEW.inactive_date
  WHERE employee_id = :NEW.employee_id AND active = 'Y';
  
  UPDATE nurses 
  SET active = 'N', inactive_date = :NEW.inactive_date
  WHERE employee_id = :NEW.employee_id AND active = 'Y';
END;
/

-- When an employee is reactivated, the corresponding doctors/nurses record is also reactivated
CREATE OR REPLACE TRIGGER trg_reactivate_employee
AFTER UPDATE OF active ON employees
FOR EACH ROW
WHEN (NEW.active = 'Y')
BEGIN
  UPDATE doctors
  SET active = 'Y', inactive_date = NULL
  WHERE employee_id = :NEW.employee_id AND active = 'N';

  UPDATE nurses
  SET active = 'Y', inactive_date = NULL
  WHERE employee_id = :NEW.employee_id AND active = 'N';
END;
/

-- When a department is deactivated, all of its rooms are deactivated
CREATE OR REPLACE TRIGGER trg_deactivate_department
AFTER UPDATE OF active ON departments
FOR EACH ROW
WHEN (NEW.active = 'N')
BEGIN
  UPDATE rooms 
  SET active = 'N', inactive_date = :NEW.inactive_date
  WHERE department_id = :NEW.department_id AND active = 'Y';
END;
/

-- When a room is deactivated, assigned nurses are also deactivated
CREATE OR REPLACE TRIGGER trg_deactivate_room
AFTER UPDATE OF active ON rooms
FOR EACH ROW
WHEN (NEW.active = 'N')
BEGIN
  UPDATE nurses
  SET active = 'N', inactive_date = :NEW.inactive_date
  WHERE room_id = :NEW.room_id AND active = 'Y';
END;
/

-- Protection: direct deletion is blocked (use UPDATE for soft delete)
CREATE OR REPLACE TRIGGER trg_block_delete_patients
BEFORE DELETE ON patients
FOR EACH ROW
BEGIN
  RAISE_APPLICATION_ERROR(-20050, 
    'Deletion is forbidden. Use UPDATE for soft delete. Patient ID: ' || :OLD.patient_id);
END;
/

CREATE OR REPLACE TRIGGER trg_block_delete_employees
BEFORE DELETE ON employees
FOR EACH ROW
BEGIN
  RAISE_APPLICATION_ERROR(-20051, 
    'Deletion is forbidden. Use UPDATE for soft delete. Employee ID: ' || :OLD.employee_id);
END;
/

CREATE OR REPLACE TRIGGER trg_block_delete_departments
BEFORE DELETE ON departments
FOR EACH ROW
BEGIN
  RAISE_APPLICATION_ERROR(-20052, 
    'Deletion is forbidden. Use UPDATE for soft delete. Department ID: ' || :OLD.department_id);
END;
/

CREATE OR REPLACE TRIGGER trg_block_delete_rooms
BEFORE DELETE ON rooms
FOR EACH ROW
BEGIN
  RAISE_APPLICATION_ERROR(-20053, 
    'Deletion is forbidden. Use UPDATE for soft delete. Room ID: ' || :OLD.room_id);
END;
/

CREATE OR REPLACE TRIGGER trg_block_delete_doctors
BEFORE DELETE ON doctors
FOR EACH ROW
BEGIN
  RAISE_APPLICATION_ERROR(-20054, 
    'Deletion is forbidden. Use UPDATE for soft delete. Doctor ID: ' || :OLD.employee_id);
END;
/

CREATE OR REPLACE TRIGGER trg_block_delete_nurses
BEFORE DELETE ON nurses
FOR EACH ROW
BEGIN
  RAISE_APPLICATION_ERROR(-20055, 
    'Deletion is forbidden. Use UPDATE for soft delete. Nurse ID: ' || :OLD.employee_id);
END;
/

-- Prevent activating a doctor when the employee is inactive
CREATE OR REPLACE TRIGGER trg_check_active_employee_doctor
BEFORE INSERT OR UPDATE ON doctors
FOR EACH ROW
DECLARE
  v_employee_active employees.active%TYPE;
BEGIN
  SELECT active INTO v_employee_active
  FROM employees
  WHERE employee_id = :NEW.employee_id;

  IF v_employee_active = 'N' AND :NEW.active = 'Y' THEN
    RAISE_APPLICATION_ERROR(-20032, 'Inactive employee. The doctor cannot be active.');
  END IF;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20033, 'Employee not found for doctor.');
END;
/

-- Prevent activating a nurse when the employee is inactive
CREATE OR REPLACE TRIGGER trg_check_active_employee_nurse
BEFORE INSERT OR UPDATE ON nurses
FOR EACH ROW
DECLARE
  v_employee_active employees.active%TYPE;
BEGIN
  SELECT active INTO v_employee_active
  FROM employees
  WHERE employee_id = :NEW.employee_id;

  IF v_employee_active = 'N' AND :NEW.active = 'Y' THEN
    RAISE_APPLICATION_ERROR(-20034, 'Inactive employee. The nurse cannot be active.');
  END IF;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20035, 'Employee not found for nurse.');
END;
/

-- Prevent creating admissions with inactive linked entities
CREATE OR REPLACE TRIGGER trg_check_active_admission_entities
BEFORE INSERT OR UPDATE OF patient_id, doctor_id, room_id ON admissions
FOR EACH ROW
DECLARE
  v_patient_active CHAR(1);
  v_doctor_active CHAR(1);
  v_room_active CHAR(1);
BEGIN
  BEGIN
    SELECT active INTO v_patient_active FROM patients WHERE patient_id = :NEW.patient_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20004, 'Patient not found.');
  END;
  
  BEGIN
    SELECT active INTO v_doctor_active FROM doctors WHERE employee_id = :NEW.doctor_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20005, 'Doctor not found.');
  END;
  
  BEGIN
    SELECT active INTO v_room_active FROM rooms WHERE room_id = :NEW.room_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20006, 'Room not found.');
  END;
  
  IF v_patient_active = 'N' THEN
    RAISE_APPLICATION_ERROR(-20001, 'Patient is inactive.');
  END IF;
  
  IF v_doctor_active = 'N' THEN
    RAISE_APPLICATION_ERROR(-20002, 'Doctor is inactive.');
  END IF;
  
  IF v_room_active = 'N' THEN
    RAISE_APPLICATION_ERROR(-20003, 'Room is inactive.');
  END IF;
END;
/

-- Validation: medicine administration is allowed only during admission
CREATE OR REPLACE TRIGGER trg_validate_administration
BEFORE INSERT OR UPDATE ON admission_medicines
FOR EACH ROW
DECLARE
  v_data_int DATE;
  v_data_ext DATE;
BEGIN
  SELECT admission_date, discharge_date 
  INTO v_data_int, v_data_ext
  FROM admissions WHERE admission_id = :NEW.admission_id;
  
  IF :NEW.administration_date < v_data_int THEN
    RAISE_APPLICATION_ERROR(-20010, 'Administration cannot be before admission.');
  END IF;
  
  IF v_data_ext IS NOT NULL AND :NEW.administration_date > v_data_ext THEN
    RAISE_APPLICATION_ERROR(-20011, 'Administration cannot be after discharge.');
  END IF;
  
  IF v_data_ext IS NOT NULL AND (:NEW.administration_date + :NEW.duration_days - 1) > v_data_ext THEN
    RAISE_APPLICATION_ERROR(-20012, 
      'Treatment exceeds the discharge date. Treatment end: ' || 
      TO_CHAR(:NEW.administration_date + :NEW.duration_days - 1, 'DD-MON-YYYY') ||
      ', Discharge: ' || TO_CHAR(v_data_ext, 'DD-MON-YYYY'));
  END IF;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20009, 'Admission not found for medicine administration.');
END;
/

-- Reverse validation: when discharge date changes, validate medicines
CREATE OR REPLACE TRIGGER trg_validate_discharge_medicines
BEFORE UPDATE OF discharge_date ON admissions
FOR EACH ROW
WHEN (NEW.discharge_date IS NOT NULL)
DECLARE
  v_invalid_medicines NUMBER;
  v_max_treatment_date DATE;
BEGIN
  SELECT COUNT(*), MAX(administration_date + duration_days - 1)
  INTO v_invalid_medicines, v_max_treatment_date
  FROM admission_medicines
  WHERE admission_id = :NEW.admission_id
    AND (administration_date + duration_days - 1) > :NEW.discharge_date;
  
  IF v_invalid_medicines > 0 THEN
    RAISE_APPLICATION_ERROR(-20013,
      'Cannot discharge: there are ' || v_invalid_medicines || 
      ' incomplete treatments. Latest completion: ' || 
      TO_CHAR(v_max_treatment_date, 'DD-MON-YYYY'));
  END IF;
END;
/

-- Validation: room capacity must not be exceeded
CREATE OR REPLACE TRIGGER trg_check_room_capacity
FOR INSERT OR UPDATE ON admissions
COMPOUND TRIGGER
  TYPE t_admission_rec IS RECORD (
    room_id admissions.room_id%TYPE,
    admission_date admissions.admission_date%TYPE
  );
  TYPE t_admission_tab IS TABLE OF t_admission_rec INDEX BY PLS_INTEGER;
  TYPE t_room_set IS TABLE OF BOOLEAN INDEX BY PLS_INTEGER;
  TYPE t_room_cap IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
  g_rows t_admission_tab;
  g_rooms t_room_set;
  g_capacity t_room_cap;
  g_idx PLS_INTEGER := 0;

  AFTER EACH ROW IS
  BEGIN
    g_idx := g_idx + 1;
    g_rows(g_idx).room_id := :NEW.room_id;
    g_rows(g_idx).admission_date := :NEW.admission_date;
    g_rooms(:NEW.room_id) := TRUE;
  END AFTER EACH ROW;

  AFTER STATEMENT IS
    v_active_admissions NUMBER;
    v_room_key PLS_INTEGER;
  BEGIN
    v_room_key := g_rooms.FIRST;
    WHILE v_room_key IS NOT NULL LOOP
      SELECT bed_count INTO g_capacity(v_room_key)
      FROM rooms
      WHERE room_id = v_room_key
      FOR UPDATE;
      
      v_room_key := g_rooms.NEXT(v_room_key);
    END LOOP;

    FOR i IN 1..g_idx LOOP
      SELECT COUNT(*) INTO v_active_admissions
      FROM admissions
      WHERE room_id = g_rows(i).room_id
        AND admission_date <= g_rows(i).admission_date
        AND (discharge_date IS NULL 
             OR discharge_date >= g_rows(i).admission_date);
      
      IF v_active_admissions > g_capacity(g_rows(i).room_id) THEN
        RAISE_APPLICATION_ERROR(-20020, 
          'Room ' || g_rows(i).room_id || ' is at maximum capacity (' || 
          g_capacity(g_rows(i).room_id) || ' beds). ' ||
          'Current occupancy: ' || v_active_admissions || ' patients.');
      END IF;
    END LOOP;
  END AFTER STATEMENT;
END trg_check_room_capacity;
/

-- MARK: - INSERTS

-- Blood groups
INSERT INTO blood_groups (group_id, description, name) VALUES (1, 'O negative', '0-');
INSERT INTO blood_groups (group_id, description, name) VALUES (2, 'O positive', '0+');
INSERT INTO blood_groups (group_id, description, name) VALUES (3, 'A negative', 'A-');
INSERT INTO blood_groups (group_id, description, name) VALUES (4, 'A positive', 'A+');
INSERT INTO blood_groups (group_id, description, name) VALUES (5, 'B positive', 'B+');
INSERT INTO blood_groups (group_id, description, name) VALUES (6, 'B negative', 'B-');
INSERT INTO blood_groups (group_id, description, name) VALUES (7, 'AB negative', 'AB-');
INSERT INTO blood_groups (group_id, description, name) VALUES (8, 'AB positive', 'AB+');

-- Room types
INSERT INTO room_types (type_id, description, name) VALUES (1, 'General room', 'General');
INSERT INTO room_types (type_id, description, name) VALUES (2, 'Intensive Care', 'ICU');
INSERT INTO room_types (type_id, description, name) VALUES (3, 'Maternity', 'Maternity');
INSERT INTO room_types (type_id, description, name) VALUES (4, 'Pediatrics', 'Pediatrics');
INSERT INTO room_types (type_id, description, name) VALUES (5, 'Surgery', 'Surgery');

-- Departments
INSERT INTO departments (department_id, name, phone, email, location) VALUES (10, 'Cardiology', '0210000001', 'cardiologie@spital.ro', 'Building A');
INSERT INTO departments (department_id, name, phone, email, location) VALUES (11, 'Surgery',   '0210000002', 'chirurgie@spital.ro',   'Building B');
INSERT INTO departments (department_id, name, phone, email, location) VALUES (12, 'Pediatrics',   '0210000003', 'pediatrie@spital.ro',   'Building C');
INSERT INTO departments (department_id, name, phone, email, location) VALUES (13, 'Neurology',  '0210000004', 'neurologie@spital.ro',  'Building D');
INSERT INTO departments (department_id, name, phone, email, location) VALUES (14, 'Oncology',   '0210000005', 'oncologie@spital.ro',   'Building E');

-- Rooms
INSERT INTO rooms (room_id, department_id, room_number, bed_count, type) VALUES (101, 10, 1, 6, 1);
INSERT INTO rooms (room_id, department_id, room_number, bed_count, type) VALUES (102, 11, 2, 4, 5);
INSERT INTO rooms (room_id, department_id, room_number, bed_count, type) VALUES (103, 12, 3, 8, 4);
INSERT INTO rooms (room_id, department_id, room_number, bed_count, type) VALUES (104, 13, 4, 5, 2);
INSERT INTO rooms (room_id, department_id, room_number, bed_count, type) VALUES (105, 14, 5, 7, 1);

-- Medicines
INSERT INTO medicines (medicine_id, name, form, standard_dose, manufacturer)
VALUES (1001, 'Paracetamol', 'tablets', '500 mg', 'PharmaX');
INSERT INTO medicines (medicine_id, name, form, standard_dose, manufacturer)
VALUES (1002, 'Ibuprofen', 'tablets', '200 mg', 'PharmaX');
INSERT INTO medicines (medicine_id, name, form, standard_dose, manufacturer)
VALUES (1003, 'Ceftriaxona', 'injectable', '1 g', 'MedLife');
INSERT INTO medicines (medicine_id, name, form, standard_dose, manufacturer)
VALUES (1004, 'Metoclopramid', 'injectable', '10 mg', 'BioMed');
INSERT INTO medicines (medicine_id, name, form, standard_dose, manufacturer)
VALUES (1005, 'Omeprazol', 'capsule', '20 mg', 'GastroPharm');

-- Employees
INSERT INTO employees (employee_id, name, first_name, hire_date, birth_date, phone, email, salary)
VALUES (2001, 'Popescu', 'Andrei', TO_DATE('2015-06-15','YYYY-MM-DD'), TO_DATE('1985-05-10','YYYY-MM-DD'), '0710000001', 'andrei.popescu@spital.ro', 12000);
INSERT INTO employees (employee_id, name, first_name, hire_date, birth_date, phone, email, salary)
VALUES (2002, 'Ionescu', 'Maria', TO_DATE('2016-03-20','YYYY-MM-DD'), TO_DATE('1988-02-12','YYYY-MM-DD'), '0710000002', 'maria.ionescu@spital.ro', 11500);
INSERT INTO employees (employee_id, name, first_name, hire_date, birth_date, phone, email, salary)
VALUES (2003, 'Georgescu', 'Mihai', TO_DATE('2018-09-01','YYYY-MM-DD'), TO_DATE('1990-11-08','YYYY-MM-DD'), '0710000003', 'mihai.georgescu@spital.ro', 11000);
INSERT INTO employees (employee_id, name, first_name, hire_date, birth_date, phone, email, salary)
VALUES (2004, 'Dumitrescu', 'Ioana', TO_DATE('2017-01-10','YYYY-MM-DD'), TO_DATE('1987-07-22','YYYY-MM-DD'), '0710000004', 'ioana.dumitrescu@spital.ro', 13000);
INSERT INTO employees (employee_id, name, first_name, hire_date, birth_date, phone, email, salary)
VALUES (2005, 'Radu', 'Victor', TO_DATE('2019-05-05','YYYY-MM-DD'), TO_DATE('1991-03-30','YYYY-MM-DD'), '0710000005', 'victor.radu@spital.ro', 10500);
INSERT INTO employees (employee_id, name, first_name, hire_date, birth_date, phone, email, salary)
VALUES (2006, 'Stan', 'Elena', TO_DATE('2020-02-14','YYYY-MM-DD'), TO_DATE('1992-12-01','YYYY-MM-DD'), '0710000006', 'elena.stan@spital.ro', 7000);
INSERT INTO employees (employee_id, name, first_name, hire_date, birth_date, phone, email, salary)
VALUES (2007, 'Marin', 'Daniel', TO_DATE('2021-08-23','YYYY-MM-DD'), TO_DATE('1993-04-17','YYYY-MM-DD'), '0710000007', 'daniel.marin@spital.ro', 7200);
INSERT INTO employees (employee_id, name, first_name, hire_date, birth_date, phone, email, salary)
VALUES (2008, 'Nistor', 'Alina', TO_DATE('2022-11-11','YYYY-MM-DD'), TO_DATE('1994-09-09','YYYY-MM-DD'), '0710000008', 'alina.nistor@spital.ro', 7100);
INSERT INTO employees (employee_id, name, first_name, hire_date, birth_date, phone, email, salary)
VALUES (2009, 'Barbu', 'Sorin', TO_DATE('2023-04-01','YYYY-MM-DD'), TO_DATE('1995-01-05','YYYY-MM-DD'), '0710000009', 'sorin.barbu@spital.ro', 6900);
INSERT INTO employees (employee_id, name, first_name, hire_date, birth_date, phone, email, salary)
VALUES (2010, 'Tudor', 'Cristina', TO_DATE('2016-10-30','YYYY-MM-DD'), TO_DATE('1989-08-20','YYYY-MM-DD'), '0710000010', 'cristina.tudor@spital.ro', 7300);

-- Doctors
INSERT INTO doctors (employee_id, specialization, license_code, rank)
VALUES (2001, 'Cardiology', 'PARA001', 'senior');
INSERT INTO doctors (employee_id, specialization, license_code, rank)
VALUES (2002, 'General surgery', 'PARA002', 'specialist');
INSERT INTO doctors (employee_id, specialization, license_code, rank)
VALUES (2003, 'Pediatrics', 'PARA003', 'resident');
INSERT INTO doctors (employee_id, specialization, license_code, rank)
VALUES (2004, 'Neurology', 'PARA004', 'specialist');
INSERT INTO doctors (employee_id, specialization, license_code, rank)
VALUES (2005, 'Oncology', 'PARA005', 'senior');

-- Nurses
INSERT INTO nurses (employee_id, type, room_id)
VALUES (2006, 'generalist', 101);
INSERT INTO nurses (employee_id, type, room_id)
VALUES (2007, 'medical', 102);
INSERT INTO nurses (employee_id, type, room_id)
VALUES (2008, 'laboratory', 103);
INSERT INTO nurses (employee_id, type, room_id)
VALUES (2009, 'generalist', 104);
INSERT INTO nurses (employee_id, type, room_id)
VALUES (2010, 'medical', 105);

-- Patients
INSERT INTO patients (patient_id, name, first_name, ssn, birth_date, address, phone, email, blood_group)
VALUES (3001, 'Iacob', 'Rares', '6000101012345', TO_DATE('2000-01-01','YYYY-MM-DD'), 'Str. Lalelelor 10', '0722000001', 'rares.iacob@example.com', 1);
INSERT INTO patients (patient_id, name, first_name, ssn, birth_date, address, phone, email, blood_group)
VALUES (3002, 'Matei', 'Ana', '6010202123456', TO_DATE('2001-02-02','YYYY-MM-DD'), 'Bd. Unirii 25', '0722000002', 'ana.matei@example.com', 2);
INSERT INTO patients (patient_id, name, first_name, ssn, birth_date, address, phone, email, blood_group)
VALUES (3003, 'Preda', 'Ioan', '9903031234567', TO_DATE('1999-03-03','YYYY-MM-DD'), 'Str. Independentei 7', '0722000003', 'ioan.preda@example.com', 3);
INSERT INTO patients (patient_id, name, first_name, ssn, birth_date, address, phone, email, blood_group)
VALUES (3004, 'Dinu', 'Elisa', '9804042345678', TO_DATE('1998-04-04','YYYY-MM-DD'), 'Calea Mosilor 12', '0722000004', 'elisa.dinu@example.com', 4);
INSERT INTO patients (patient_id, name, first_name, ssn, birth_date, address, phone, email, blood_group)
VALUES (3005, 'Enache', 'Paul', '9705053456789', TO_DATE('1997-05-05','YYYY-MM-DD'), 'Str. Florilor 3', '0722000005', 'paul.enache@example.com', 5);

-- Admissions
INSERT INTO admissions (admission_id, patient_id, doctor_id, room_id, admission_date, discharge_date, diagnosis, discharge_status)
VALUES (4001, 3001, 2001, 101, TO_DATE('2025-12-20','YYYY-MM-DD'), TO_DATE('2025-12-28','YYYY-MM-DD'), 'Pneumonia', 'recovered');
INSERT INTO admissions (admission_id, patient_id, doctor_id, room_id, admission_date, discharge_date, diagnosis, discharge_status)
VALUES (4002, 3002, 2002, 102, TO_DATE('2025-12-22','YYYY-MM-DD'), NULL, 'Acute appendicitis', NULL);
INSERT INTO admissions (admission_id, patient_id, doctor_id, room_id, admission_date, discharge_date, diagnosis, discharge_status)
VALUES (4003, 3003, 2003, 103, TO_DATE('2025-12-15','YYYY-MM-DD'), TO_DATE('2025-12-19','YYYY-MM-DD'), 'Bronchiolitis', 'improved');
INSERT INTO admissions (admission_id, patient_id, doctor_id, room_id, admission_date, discharge_date, diagnosis, discharge_status)
VALUES (4004, 3004, 2004, 104, TO_DATE('2025-12-10','YYYY-MM-DD'), TO_DATE('2025-12-20','YYYY-MM-DD'), 'Severe migraine', 'transferred');
INSERT INTO admissions (admission_id, patient_id, doctor_id, room_id, admission_date, discharge_date, diagnosis, discharge_status)
VALUES (4005, 3005, 2005, 105, TO_DATE('2025-12-05','YYYY-MM-DD'), NULL, 'Neoplasm', NULL);

-- Medicine administrations
-- 4001 (admission with discharge 20-28 dec)
INSERT INTO admission_medicines (admission_id, medicine_id, dose, frequency, administration_date, duration_days)
VALUES (4001, 1001, '500 mg', '3 times/day', TO_DATE('2025-12-21','YYYY-MM-DD'), 5);
INSERT INTO admission_medicines (admission_id, medicine_id, dose, frequency, administration_date, duration_days)
VALUES (4001, 1005, '20 mg', 'once/day', TO_DATE('2025-12-22','YYYY-MM-DD'), 7);

-- 4002 (active admission since 22 dec)
INSERT INTO admission_medicines (admission_id, medicine_id, dose, frequency, administration_date, duration_days)
VALUES (4002, 1002, '200 mg', '2 times/day', TO_DATE('2025-12-23','YYYY-MM-DD'), 3);
INSERT INTO admission_medicines (admission_id, medicine_id, dose, frequency, administration_date, duration_days)
VALUES (4002, 1004, '10 mg', 'as needed', TO_DATE('2025-12-24','YYYY-MM-DD'), 1);
INSERT INTO admission_medicines (admission_id, medicine_id, dose, frequency, administration_date, duration_days)
VALUES (4002, 1001, '500 mg', 'once/day', TO_DATE('2025-12-25','YYYY-MM-DD'), 2);

-- 4003 (15-19 dec)
INSERT INTO admission_medicines (admission_id, medicine_id, dose, frequency, administration_date, duration_days)
VALUES (4003, 1003, '1 g', 'once/day', TO_DATE('2025-12-16','YYYY-MM-DD'), 3);
INSERT INTO admission_medicines (admission_id, medicine_id, dose, frequency, administration_date, duration_days)
VALUES (4003, 1001, '500 mg', '2 times/day', TO_DATE('2025-12-17','YYYY-MM-DD'), 2);

-- 4004 (10-20 dec)
INSERT INTO admission_medicines (admission_id, medicine_id, dose, frequency, administration_date, duration_days)
VALUES (4004, 1004, '10 mg', '3 times/day', TO_DATE('2025-12-12','YYYY-MM-DD'), 2);
INSERT INTO admission_medicines (admission_id, medicine_id, dose, frequency, administration_date, duration_days)
VALUES (4004, 1005, '20 mg', 'once/day', TO_DATE('2025-12-13','YYYY-MM-DD'), 5);

-- 4005 (active admission since 5 dec)
INSERT INTO admission_medicines (admission_id, medicine_id, dose, frequency, administration_date, duration_days)
VALUES (4005, 1003, '1 g', 'once/day', TO_DATE('2025-12-06','YYYY-MM-DD'), 7);
INSERT INTO admission_medicines (admission_id, medicine_id, dose, frequency, administration_date, duration_days)
VALUES (4005, 1002, '200 mg', '2 times/day', TO_DATE('2025-12-07','YYYY-MM-DD'), 3);

COMMIT;
