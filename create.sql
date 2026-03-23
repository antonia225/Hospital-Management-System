-- MARK: - TABLES

CREATE TABLE grupe_sange (
    id_grupa        NUMBER(2) CONSTRAINT gr_sange_pk PRIMARY KEY,
    descriere       VARCHAR2(30),
    denumire        VARCHAR2(3) NOT NULL
);

CREATE TABLE tipuri (
    id_tip          NUMBER(2) CONSTRAINT tipuri_pk PRIMARY KEY,
    descriere       VARCHAR2(50),
    denumire        VARCHAR2(20) NOT NULL
);

CREATE TABLE pacienti (
    id_pacient      NUMBER(6) CONSTRAINT pacienti_pk PRIMARY KEY,
    nume            VARCHAR2(25),
    prenume         VARCHAR2(20),
    cnp             CHAR(13) UNIQUE,
    data_nasterii   DATE,
    adresa          VARCHAR2(50),
    telefon         VARCHAR2(20) UNIQUE,
    email           VARCHAR2(30) UNIQUE,
    grupa_sange     NUMBER(2) REFERENCES grupe_sange(id_grupa) NOT NULL,
    activ           CHAR(1) DEFAULT 'Y' NOT NULL,
    data_inactivare DATE,
    CONSTRAINT ck_cnp CHECK (REGEXP_LIKE(cnp, '^[0-9]{13}$')),
    CONSTRAINT ck_p_tel CHECK (telefon IS NULL OR REGEXP_LIKE(telefon, '^[0-9]{10}$')),
    CONSTRAINT ck_p_email CHECK (email IS NULL OR REGEXP_LIKE(email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')),
    CONSTRAINT ck_p_activ CHECK (
        (activ = 'Y' AND data_inactivare IS NULL)
        OR (activ = 'N' AND data_inactivare IS NOT NULL)
    )
);

CREATE TABLE sectii (
    id_sectie       NUMBER(4) CONSTRAINT sectii_pk PRIMARY KEY,
    denumire        VARCHAR2(25) NOT NULL,
    telefon         VARCHAR2(20) UNIQUE,
    email           VARCHAR2(30) UNIQUE,
    locatie         VARCHAR2(50),
    activ           CHAR(1) DEFAULT 'Y' NOT NULL,
    data_inactivare DATE,
    CONSTRAINT date_contact_sectie CHECK (email IS NOT NULL OR telefon IS NOT NULL),
    CONSTRAINT ck_sectie_activ CHECK (
        (activ = 'Y' AND data_inactivare IS NULL)
        OR (activ = 'N' AND data_inactivare IS NOT NULL)
    ),
    CONSTRAINT ck_s_tel CHECK (telefon IS NULL OR REGEXP_LIKE(telefon, '^[0-9]{10}$')),
    CONSTRAINT ck_s_email CHECK (email IS NULL OR REGEXP_LIKE(email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'))
);

CREATE TABLE saloane (
    id_salon        NUMBER(4) CONSTRAINT saloane_pk PRIMARY KEY,
    id_sectie       NUMBER(4) REFERENCES sectii(id_sectie) NOT NULL,
    nr_salon        NUMBER(6) NOT NULL,
    nr_paturi       NUMBER(2) NOT NULL,
    tip             NUMBER(2) REFERENCES tipuri(id_tip) NOT NULL,
    activ           CHAR(1) DEFAULT 'Y' NOT NULL,
    data_inactivare DATE,
    CONSTRAINT salon_unic UNIQUE (id_sectie, nr_salon),
    CONSTRAINT ck_nr_paturi CHECK (nr_paturi > 0 AND nr_paturi <= 10),
    CONSTRAINT ck_salon_activ CHECK (
        (activ = 'Y' AND data_inactivare IS NULL)
        OR (activ = 'N' AND data_inactivare IS NOT NULL)
    )
);

CREATE TABLE medicamente (
    id_medicament   NUMBER(6) CONSTRAINT medicamente_pk PRIMARY KEY,
    denumire        VARCHAR2(50) NOT NULL,
    forma_med       VARCHAR2(20),
    doza_standard   VARCHAR2(20) NOT NULL,
    producator      VARCHAR2(25)
);

CREATE TABLE angajati (
    id_angajat      NUMBER(6) CONSTRAINT angajati_pk PRIMARY KEY,
    nume            VARCHAR2(25) NOT NULL,
    prenume         VARCHAR2(20) NOT NULL,
    data_angajare   DATE DEFAULT SYSDATE NOT NULL,
    data_nastere    DATE NOT NULL,
    telefon         VARCHAR2(20) UNIQUE,
    email           VARCHAR2(30) UNIQUE,
    salariu         NUMBER(10,2),
    activ           CHAR(1) DEFAULT 'Y' NOT NULL,
    data_inactivare DATE,
    CONSTRAINT date_contact CHECK (email IS NOT NULL OR telefon IS NOT NULL),
    CONSTRAINT ck_salariu CHECK (salariu > 0),
    CONSTRAINT ck_varsta_angajare CHECK (MONTHS_BETWEEN(data_angajare, data_nastere) >= 216),
    CONSTRAINT ck_a_tel CHECK (telefon IS NULL OR REGEXP_LIKE(telefon, '^[0-9]{10}$')),
    CONSTRAINT ck_a_email CHECK (email IS NULL OR REGEXP_LIKE(email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')),
    CONSTRAINT ck_a_activ CHECK (
        (activ = 'Y' AND data_inactivare IS NULL)
        OR (activ = 'N' AND data_inactivare IS NOT NULL)
    )
);

CREATE TABLE medici (
    id_angajat      NUMBER(6) CONSTRAINT medici_pk PRIMARY KEY,
    specializare    VARCHAR2(30) NOT NULL,
    cod_parafa      VARCHAR2(10) NOT NULL UNIQUE,
    grad            VARCHAR2(20) NOT NULL,
    activ           CHAR(1) DEFAULT 'Y' NOT NULL,
    data_inactivare DATE,
    CONSTRAINT ck_grad_medic CHECK (LOWER(grad) IN ('rezident', 'specialist', 'primar')),
    CONSTRAINT ck_medic_activ CHECK (
        (activ = 'Y' AND data_inactivare IS NULL)
        OR (activ = 'N' AND data_inactivare IS NOT NULL)
    ),
    CONSTRAINT medici_fk_angajat 
    FOREIGN KEY (id_angajat) REFERENCES angajati(id_angajat)
);

CREATE TABLE asistenti (
    id_angajat      NUMBER(6) CONSTRAINT asistenti_pk PRIMARY KEY,
    tip             VARCHAR2(20) NOT NULL,
    id_salon        NUMBER(4) REFERENCES saloane(id_salon),
    activ           CHAR(1) DEFAULT 'Y' NOT NULL,
    data_inactivare DATE,
    CONSTRAINT ck_tip_asistent CHECK (LOWER(tip) IN ('generalist', 'medical', 'laborator')),
    CONSTRAINT ck_asistent_activ CHECK (
        (activ = 'Y' AND data_inactivare IS NULL)
        OR (activ = 'N' AND data_inactivare IS NOT NULL)
    ),
    CONSTRAINT asistenti_fk_angajat
    FOREIGN KEY (id_angajat) REFERENCES angajati(id_angajat)
);

CREATE TABLE internari (
    id_internare    NUMBER(6) CONSTRAINT internari_pk PRIMARY KEY,
    id_pacient      NUMBER(6) NOT NULL,
    id_medic        NUMBER(6) NOT NULL,
    id_salon        NUMBER(4) NOT NULL,
    data_internare  DATE DEFAULT SYSDATE NOT NULL,
    data_externare  DATE,
    diagnostic      VARCHAR2(100),
    stare_externare VARCHAR2(20),
    CONSTRAINT internari_fk_pacient
        FOREIGN KEY (id_pacient) REFERENCES pacienti(id_pacient),
    CONSTRAINT internari_fk_medic
        FOREIGN KEY (id_medic) REFERENCES medici(id_angajat),
    CONSTRAINT internari_fk_salon
        FOREIGN KEY (id_salon) REFERENCES saloane(id_salon),
    CONSTRAINT internari_ck_dates
        CHECK (data_externare IS NULL OR data_externare >= data_internare), 
    CONSTRAINT internari_ck_s_externare
        CHECK (stare_externare IS NULL OR LOWER(stare_externare) IN ('ameliorat', 'vindecat', 'decedat', 'transferat')),
    CONSTRAINT internari_ck_s_ext_d_ext
        CHECK (
            (data_externare IS NULL AND stare_externare IS NULL)
            OR (data_externare IS NOT NULL AND stare_externare IS NOT NULL)
        )
);

CREATE TABLE internari_medicamente (
    id_internare    NUMBER(6) NOT NULL,
    id_medicament   NUMBER(6) NOT NULL,
    doza            VARCHAR2(20) NOT NULL,
    frecventa       VARCHAR2(20),
    data_administrare   DATE NOT NULL,
    durata_zile     NUMBER(3) NOT NULL,
    CONSTRAINT ck_internari_medicamente_durata_zile CHECK (durata_zile > 0),
    CONSTRAINT internari_medicamente_pk
        PRIMARY KEY (id_internare, id_medicament, data_administrare),
    CONSTRAINT internari_medicamente_fk_internari
        FOREIGN KEY (id_internare) REFERENCES internari(id_internare),
    CONSTRAINT internari_medicamente_fk_medicament
        FOREIGN KEY (id_medicament) REFERENCES medicamente(id_medicament)
);

-- MARK: - TRIGGERS

-- Cand se inactiveaza un angajat, se inactiveaza automat si inregistrarea din medici/asistenti
CREATE OR REPLACE TRIGGER trg_inactiv_angajat
AFTER UPDATE OF activ ON angajati
FOR EACH ROW
WHEN (NEW.activ = 'N')
BEGIN
  UPDATE medici 
  SET activ = 'N', data_inactivare = :NEW.data_inactivare
  WHERE id_angajat = :NEW.id_angajat AND activ = 'Y';
  
  UPDATE asistenti 
  SET activ = 'N', data_inactivare = :NEW.data_inactivare
  WHERE id_angajat = :NEW.id_angajat AND activ = 'Y';
END;
/

-- Cand se reactiveaza un angajat, se reactiveaza automat si inregistrarea din medici/asistenti
CREATE OR REPLACE TRIGGER trg_reactiv_angajat
AFTER UPDATE OF activ ON angajati
FOR EACH ROW
WHEN (NEW.activ = 'Y')
BEGIN
  UPDATE medici
  SET activ = 'Y', data_inactivare = NULL
  WHERE id_angajat = :NEW.id_angajat AND activ = 'N';

  UPDATE asistenti
  SET activ = 'Y', data_inactivare = NULL
  WHERE id_angajat = :NEW.id_angajat AND activ = 'N';
END;
/

-- Cand se inactiveaza o sectie, se inactiveaza saloanele acesteia
CREATE OR REPLACE TRIGGER trg_inactiv_sectie
AFTER UPDATE OF activ ON sectii
FOR EACH ROW
WHEN (NEW.activ = 'N')
BEGIN
  UPDATE saloane 
  SET activ = 'N', data_inactivare = :NEW.data_inactivare
  WHERE id_sectie = :NEW.id_sectie AND activ = 'Y';
END;
/

-- Cand se inactiveaza un salon, se inactiveaza asistentii alocati acestuia
CREATE OR REPLACE TRIGGER trg_inactiv_salon
AFTER UPDATE OF activ ON saloane
FOR EACH ROW
WHEN (NEW.activ = 'N')
BEGIN
  UPDATE asistenti
  SET activ = 'N', data_inactivare = :NEW.data_inactivare
  WHERE id_salon = :NEW.id_salon AND activ = 'Y';
END;
/

-- Protectie: Interzice ștergerea directă (soft delete se face prin UPDATE)
CREATE OR REPLACE TRIGGER trg_block_delete_pacienti
BEFORE DELETE ON pacienti
FOR EACH ROW
BEGIN
  RAISE_APPLICATION_ERROR(-20050, 
    'Stergerea este interzisa. Foloseste UPDATE pentru soft delete. ID pacient: ' || :OLD.id_pacient);
END;
/

CREATE OR REPLACE TRIGGER trg_block_delete_angajati
BEFORE DELETE ON angajati
FOR EACH ROW
BEGIN
  RAISE_APPLICATION_ERROR(-20051, 
    'Stergerea este interzisa. Foloseste UPDATE pentru soft delete. ID angajat: ' || :OLD.id_angajat);
END;
/

CREATE OR REPLACE TRIGGER trg_block_delete_sectii
BEFORE DELETE ON sectii
FOR EACH ROW
BEGIN
  RAISE_APPLICATION_ERROR(-20052, 
    'Stergerea este interzisa. Foloseste UPDATE pentru soft delete. ID sectie: ' || :OLD.id_sectie);
END;
/

CREATE OR REPLACE TRIGGER trg_block_delete_saloane
BEFORE DELETE ON saloane
FOR EACH ROW
BEGIN
  RAISE_APPLICATION_ERROR(-20053, 
    'Stergerea este interzisa. Foloseste UPDATE pentru soft delete. ID salon: ' || :OLD.id_salon);
END;
/

CREATE OR REPLACE TRIGGER trg_block_delete_medici
BEFORE DELETE ON medici
FOR EACH ROW
BEGIN
  RAISE_APPLICATION_ERROR(-20054, 
    'Stergerea este interzisa. Foloseste UPDATE pentru soft delete. ID medic: ' || :OLD.id_angajat);
END;
/

CREATE OR REPLACE TRIGGER trg_block_delete_asistenti
BEFORE DELETE ON asistenti
FOR EACH ROW
BEGIN
  RAISE_APPLICATION_ERROR(-20055, 
    'Stergerea este interzisa. Foloseste UPDATE pentru soft delete. ID asistent: ' || :OLD.id_angajat);
END;
/

-- Nu permite activarea unui medic daca angajatul este inactiv
CREATE OR REPLACE TRIGGER trg_check_medic_angajat_activ
BEFORE INSERT OR UPDATE ON medici
FOR EACH ROW
DECLARE
  v_angajat_activ angajati.activ%TYPE;
BEGIN
  SELECT activ INTO v_angajat_activ
  FROM angajati
  WHERE id_angajat = :NEW.id_angajat;

  IF v_angajat_activ = 'N' AND :NEW.activ = 'Y' THEN
    RAISE_APPLICATION_ERROR(-20032, 'Angajat inactiv. Medicul nu poate fi activ.');
  END IF;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20033, 'Angajat inexistent pentru medic.');
END;
/

-- Nu permite activarea unui asistent daca angajatul este inactiv
CREATE OR REPLACE TRIGGER trg_check_asistent_angajat_activ
BEFORE INSERT OR UPDATE ON asistenti
FOR EACH ROW
DECLARE
  v_angajat_activ angajati.activ%TYPE;
BEGIN
  SELECT activ INTO v_angajat_activ
  FROM angajati
  WHERE id_angajat = :NEW.id_angajat;

  IF v_angajat_activ = 'N' AND :NEW.activ = 'Y' THEN
    RAISE_APPLICATION_ERROR(-20034, 'Angajat inactiv. Asistentul nu poate fi activ.');
  END IF;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20035, 'Angajat inexistent pentru asistent.');
END;
/

-- Constraint pentru a preveni internari noi cu entitati inactive
CREATE OR REPLACE TRIGGER trg_check_internare_activ
BEFORE INSERT OR UPDATE OF id_pacient, id_medic, id_salon ON internari
FOR EACH ROW
DECLARE
  v_pacient_activ CHAR(1);
  v_medic_activ CHAR(1);
  v_salon_activ CHAR(1);
BEGIN
  BEGIN
    SELECT activ INTO v_pacient_activ FROM pacienti WHERE id_pacient = :NEW.id_pacient;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20004, 'Pacient inexistent.');
  END;
  
  BEGIN
    SELECT activ INTO v_medic_activ FROM medici WHERE id_angajat = :NEW.id_medic;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20005, 'Medic inexistent.');
  END;
  
  BEGIN
    SELECT activ INTO v_salon_activ FROM saloane WHERE id_salon = :NEW.id_salon;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20006, 'Salon inexistent.');
  END;
  
  IF v_pacient_activ = 'N' THEN
    RAISE_APPLICATION_ERROR(-20001, 'Pacientul este inactiv.');
  END IF;
  
  IF v_medic_activ = 'N' THEN
    RAISE_APPLICATION_ERROR(-20002, 'Medicul este inactiv.');
  END IF;
  
  IF v_salon_activ = 'N' THEN
    RAISE_APPLICATION_ERROR(-20003, 'Salonul este inactiv.');
  END IF;
END;
/

-- Validare: administrarea medicamentelor doar in perioada internarii
CREATE OR REPLACE TRIGGER trg_valid_administrare
BEFORE INSERT OR UPDATE ON internari_medicamente
FOR EACH ROW
DECLARE
  v_data_int DATE;
  v_data_ext DATE;
BEGIN
  SELECT data_internare, data_externare 
  INTO v_data_int, v_data_ext
  FROM internari WHERE id_internare = :NEW.id_internare;
  
  IF :NEW.data_administrare < v_data_int THEN
    RAISE_APPLICATION_ERROR(-20010, 'Administrarea nu poate fi înainte de internare.');
  END IF;
  
  IF v_data_ext IS NOT NULL AND :NEW.data_administrare > v_data_ext THEN
    RAISE_APPLICATION_ERROR(-20011, 'Administrarea nu poate fi după externare.');
  END IF;
  
  IF v_data_ext IS NOT NULL AND (:NEW.data_administrare + :NEW.durata_zile - 1) > v_data_ext THEN
    RAISE_APPLICATION_ERROR(-20012, 
      'Tratamentul depășește data externării. Finalizare tratament: ' || 
      TO_CHAR(:NEW.data_administrare + :NEW.durata_zile - 1, 'DD-MON-YYYY') ||
      ', Externare: ' || TO_CHAR(v_data_ext, 'DD-MON-YYYY'));
  END IF;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20009, 'Internare inexistenta pentru administrare medicamente.');
END;
/

-- Validare inversă: la modificarea externării, verifică medicamentele
CREATE OR REPLACE TRIGGER trg_valid_externare_medicamente
BEFORE UPDATE OF data_externare ON internari
FOR EACH ROW
WHEN (NEW.data_externare IS NOT NULL)
DECLARE
  v_medicamente_invalide NUMBER;
  v_data_max_tratament DATE;
BEGIN
  SELECT COUNT(*), MAX(data_administrare + durata_zile - 1)
  INTO v_medicamente_invalide, v_data_max_tratament
  FROM internari_medicamente
  WHERE id_internare = :NEW.id_internare
    AND (data_administrare + durata_zile - 1) > :NEW.data_externare;
  
  IF v_medicamente_invalide > 0 THEN
    RAISE_APPLICATION_ERROR(-20013,
      'Nu se poate externa: există ' || v_medicamente_invalide || 
      ' tratamente incomplete. Ultima finalizare: ' || 
      TO_CHAR(v_data_max_tratament, 'DD-MON-YYYY'));
  END IF;
END;
/

-- Validare: capacitatea salonului nu este depasita
CREATE OR REPLACE TRIGGER trg_check_capacitate_salon
FOR INSERT OR UPDATE ON internari
COMPOUND TRIGGER
  TYPE t_internare_rec IS RECORD (
    id_salon internari.id_salon%TYPE,
    data_internare internari.data_internare%TYPE
  );
  TYPE t_internare_tab IS TABLE OF t_internare_rec INDEX BY PLS_INTEGER;
  TYPE t_salon_set IS TABLE OF BOOLEAN INDEX BY PLS_INTEGER;
  TYPE t_salon_cap IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
  g_rows t_internare_tab;
  g_saloane t_salon_set;
  g_capacitate t_salon_cap;
  g_idx PLS_INTEGER := 0;

  AFTER EACH ROW IS
  BEGIN
    g_idx := g_idx + 1;
    g_rows(g_idx).id_salon := :NEW.id_salon;
    g_rows(g_idx).data_internare := :NEW.data_internare;
    g_saloane(:NEW.id_salon) := TRUE;
  END AFTER EACH ROW;

  AFTER STATEMENT IS
    v_internari_active NUMBER;
    v_salon_key PLS_INTEGER;
  BEGIN
    v_salon_key := g_saloane.FIRST;
    WHILE v_salon_key IS NOT NULL LOOP
      SELECT nr_paturi INTO g_capacitate(v_salon_key)
      FROM saloane
      WHERE id_salon = v_salon_key
      FOR UPDATE;
      
      v_salon_key := g_saloane.NEXT(v_salon_key);
    END LOOP;

    FOR i IN 1..g_idx LOOP
      SELECT COUNT(*) INTO v_internari_active
      FROM internari
      WHERE id_salon = g_rows(i).id_salon
        AND data_internare <= g_rows(i).data_internare
        AND (data_externare IS NULL 
             OR data_externare >= g_rows(i).data_internare);
      
      IF v_internari_active > g_capacitate(g_rows(i).id_salon) THEN
        RAISE_APPLICATION_ERROR(-20020, 
          'Salonul ' || g_rows(i).id_salon || ' este la capacitate maximă (' || 
          g_capacitate(g_rows(i).id_salon) || ' paturi). ' ||
          'Ocupare curentă: ' || v_internari_active || ' pacienți.');
      END IF;
    END LOOP;
  END AFTER STATEMENT;
END trg_check_capacitate_salon;
/

-- MARK: - INSERTS

-- Grupe de sange
INSERT INTO grupe_sange (id_grupa, descriere, denumire) VALUES (1, 'Grupa 0 negativ', '0-');
INSERT INTO grupe_sange (id_grupa, descriere, denumire) VALUES (2, 'Grupa 0 pozitiv', '0+');
INSERT INTO grupe_sange (id_grupa, descriere, denumire) VALUES (3, 'Grupa A negativ', 'A-');
INSERT INTO grupe_sange (id_grupa, descriere, denumire) VALUES (4, 'Grupa A pozitiv', 'A+');
INSERT INTO grupe_sange (id_grupa, descriere, denumire) VALUES (5, 'Grupa B pozitiv', 'B+');
INSERT INTO grupe_sange (id_grupa, descriere, denumire) VALUES (6, 'Grupa B negativ', 'B-');
INSERT INTO grupe_sange (id_grupa, descriere, denumire) VALUES (7, 'Grupa AB negativ', 'AB-');
INSERT INTO grupe_sange (id_grupa, descriere, denumire) VALUES (8, 'Grupa AB pozitiv', 'AB+');

-- Tipuri de salon
INSERT INTO tipuri (id_tip, descriere, denumire) VALUES (1, 'Salon general', 'General');
INSERT INTO tipuri (id_tip, descriere, denumire) VALUES (2, 'Terapie Intensiva', 'ATI');
INSERT INTO tipuri (id_tip, descriere, denumire) VALUES (3, 'Maternitate', 'Maternitate');
INSERT INTO tipuri (id_tip, descriere, denumire) VALUES (4, 'Pediatrie', 'Pediatrie');
INSERT INTO tipuri (id_tip, descriere, denumire) VALUES (5, 'Chirurgie', 'Chirurgie');

-- Sectii
INSERT INTO sectii (id_sectie, denumire, telefon, email, locatie) VALUES (10, 'Cardiologie', '0210000001', 'cardiologie@spital.ro', 'Corp A');
INSERT INTO sectii (id_sectie, denumire, telefon, email, locatie) VALUES (11, 'Chirurgie',   '0210000002', 'chirurgie@spital.ro',   'Corp B');
INSERT INTO sectii (id_sectie, denumire, telefon, email, locatie) VALUES (12, 'Pediatrie',   '0210000003', 'pediatrie@spital.ro',   'Corp C');
INSERT INTO sectii (id_sectie, denumire, telefon, email, locatie) VALUES (13, 'Neurologie',  '0210000004', 'neurologie@spital.ro',  'Corp D');
INSERT INTO sectii (id_sectie, denumire, telefon, email, locatie) VALUES (14, 'Oncologie',   '0210000005', 'oncologie@spital.ro',   'Corp E');

-- Saloane
INSERT INTO saloane (id_salon, id_sectie, nr_salon, nr_paturi, tip) VALUES (101, 10, 1, 6, 1);
INSERT INTO saloane (id_salon, id_sectie, nr_salon, nr_paturi, tip) VALUES (102, 11, 2, 4, 5);
INSERT INTO saloane (id_salon, id_sectie, nr_salon, nr_paturi, tip) VALUES (103, 12, 3, 8, 4);
INSERT INTO saloane (id_salon, id_sectie, nr_salon, nr_paturi, tip) VALUES (104, 13, 4, 5, 2);
INSERT INTO saloane (id_salon, id_sectie, nr_salon, nr_paturi, tip) VALUES (105, 14, 5, 7, 1);

-- Medicamente
INSERT INTO medicamente (id_medicament, denumire, forma_med, doza_standard, producator)
VALUES (1001, 'Paracetamol', 'comprimate', '500 mg', 'PharmaX');
INSERT INTO medicamente (id_medicament, denumire, forma_med, doza_standard, producator)
VALUES (1002, 'Ibuprofen', 'comprimate', '200 mg', 'PharmaX');
INSERT INTO medicamente (id_medicament, denumire, forma_med, doza_standard, producator)
VALUES (1003, 'Ceftriaxona', 'injectabil', '1 g', 'MedLife');
INSERT INTO medicamente (id_medicament, denumire, forma_med, doza_standard, producator)
VALUES (1004, 'Metoclopramid', 'injectabil', '10 mg', 'BioMed');
INSERT INTO medicamente (id_medicament, denumire, forma_med, doza_standard, producator)
VALUES (1005, 'Omeprazol', 'capsule', '20 mg', 'GastroPharm');

-- Angajati
INSERT INTO angajati (id_angajat, nume, prenume, data_angajare, data_nastere, telefon, email, salariu)
VALUES (2001, 'Popescu', 'Andrei', TO_DATE('2015-06-15','YYYY-MM-DD'), TO_DATE('1985-05-10','YYYY-MM-DD'), '0710000001', 'andrei.popescu@spital.ro', 12000);
INSERT INTO angajati (id_angajat, nume, prenume, data_angajare, data_nastere, telefon, email, salariu)
VALUES (2002, 'Ionescu', 'Maria', TO_DATE('2016-03-20','YYYY-MM-DD'), TO_DATE('1988-02-12','YYYY-MM-DD'), '0710000002', 'maria.ionescu@spital.ro', 11500);
INSERT INTO angajati (id_angajat, nume, prenume, data_angajare, data_nastere, telefon, email, salariu)
VALUES (2003, 'Georgescu', 'Mihai', TO_DATE('2018-09-01','YYYY-MM-DD'), TO_DATE('1990-11-08','YYYY-MM-DD'), '0710000003', 'mihai.georgescu@spital.ro', 11000);
INSERT INTO angajati (id_angajat, nume, prenume, data_angajare, data_nastere, telefon, email, salariu)
VALUES (2004, 'Dumitrescu', 'Ioana', TO_DATE('2017-01-10','YYYY-MM-DD'), TO_DATE('1987-07-22','YYYY-MM-DD'), '0710000004', 'ioana.dumitrescu@spital.ro', 13000);
INSERT INTO angajati (id_angajat, nume, prenume, data_angajare, data_nastere, telefon, email, salariu)
VALUES (2005, 'Radu', 'Victor', TO_DATE('2019-05-05','YYYY-MM-DD'), TO_DATE('1991-03-30','YYYY-MM-DD'), '0710000005', 'victor.radu@spital.ro', 10500);
INSERT INTO angajati (id_angajat, nume, prenume, data_angajare, data_nastere, telefon, email, salariu)
VALUES (2006, 'Stan', 'Elena', TO_DATE('2020-02-14','YYYY-MM-DD'), TO_DATE('1992-12-01','YYYY-MM-DD'), '0710000006', 'elena.stan@spital.ro', 7000);
INSERT INTO angajati (id_angajat, nume, prenume, data_angajare, data_nastere, telefon, email, salariu)
VALUES (2007, 'Marin', 'Daniel', TO_DATE('2021-08-23','YYYY-MM-DD'), TO_DATE('1993-04-17','YYYY-MM-DD'), '0710000007', 'daniel.marin@spital.ro', 7200);
INSERT INTO angajati (id_angajat, nume, prenume, data_angajare, data_nastere, telefon, email, salariu)
VALUES (2008, 'Nistor', 'Alina', TO_DATE('2022-11-11','YYYY-MM-DD'), TO_DATE('1994-09-09','YYYY-MM-DD'), '0710000008', 'alina.nistor@spital.ro', 7100);
INSERT INTO angajati (id_angajat, nume, prenume, data_angajare, data_nastere, telefon, email, salariu)
VALUES (2009, 'Barbu', 'Sorin', TO_DATE('2023-04-01','YYYY-MM-DD'), TO_DATE('1995-01-05','YYYY-MM-DD'), '0710000009', 'sorin.barbu@spital.ro', 6900);
INSERT INTO angajati (id_angajat, nume, prenume, data_angajare, data_nastere, telefon, email, salariu)
VALUES (2010, 'Tudor', 'Cristina', TO_DATE('2016-10-30','YYYY-MM-DD'), TO_DATE('1989-08-20','YYYY-MM-DD'), '0710000010', 'cristina.tudor@spital.ro', 7300);

-- Medici
INSERT INTO medici (id_angajat, specializare, cod_parafa, grad)
VALUES (2001, 'Cardiologie', 'PARA001', 'primar');
INSERT INTO medici (id_angajat, specializare, cod_parafa, grad)
VALUES (2002, 'Chirurgie generala', 'PARA002', 'specialist');
INSERT INTO medici (id_angajat, specializare, cod_parafa, grad)
VALUES (2003, 'Pediatrie', 'PARA003', 'rezident');
INSERT INTO medici (id_angajat, specializare, cod_parafa, grad)
VALUES (2004, 'Neurologie', 'PARA004', 'specialist');
INSERT INTO medici (id_angajat, specializare, cod_parafa, grad)
VALUES (2005, 'Oncologie', 'PARA005', 'primar');

-- Asistenti
INSERT INTO asistenti (id_angajat, tip, id_salon)
VALUES (2006, 'generalist', 101);
INSERT INTO asistenti (id_angajat, tip, id_salon)
VALUES (2007, 'medical', 102);
INSERT INTO asistenti (id_angajat, tip, id_salon)
VALUES (2008, 'laborator', 103);
INSERT INTO asistenti (id_angajat, tip, id_salon)
VALUES (2009, 'generalist', 104);
INSERT INTO asistenti (id_angajat, tip, id_salon)
VALUES (2010, 'medical', 105);

-- Pacienti
INSERT INTO pacienti (id_pacient, nume, prenume, cnp, data_nasterii, adresa, telefon, email, grupa_sange)
VALUES (3001, 'Iacob', 'Rares', '6000101012345', TO_DATE('2000-01-01','YYYY-MM-DD'), 'Str. Lalelelor 10', '0722000001', 'rares.iacob@example.com', 1);
INSERT INTO pacienti (id_pacient, nume, prenume, cnp, data_nasterii, adresa, telefon, email, grupa_sange)
VALUES (3002, 'Matei', 'Ana', '6010202123456', TO_DATE('2001-02-02','YYYY-MM-DD'), 'Bd. Unirii 25', '0722000002', 'ana.matei@example.com', 2);
INSERT INTO pacienti (id_pacient, nume, prenume, cnp, data_nasterii, adresa, telefon, email, grupa_sange)
VALUES (3003, 'Preda', 'Ioan', '9903031234567', TO_DATE('1999-03-03','YYYY-MM-DD'), 'Str. Independentei 7', '0722000003', 'ioan.preda@example.com', 3);
INSERT INTO pacienti (id_pacient, nume, prenume, cnp, data_nasterii, adresa, telefon, email, grupa_sange)
VALUES (3004, 'Dinu', 'Elisa', '9804042345678', TO_DATE('1998-04-04','YYYY-MM-DD'), 'Calea Mosilor 12', '0722000004', 'elisa.dinu@example.com', 4);
INSERT INTO pacienti (id_pacient, nume, prenume, cnp, data_nasterii, adresa, telefon, email, grupa_sange)
VALUES (3005, 'Enache', 'Paul', '9705053456789', TO_DATE('1997-05-05','YYYY-MM-DD'), 'Str. Florilor 3', '0722000005', 'paul.enache@example.com', 5);

-- Internari
INSERT INTO internari (id_internare, id_pacient, id_medic, id_salon, data_internare, data_externare, diagnostic, stare_externare)
VALUES (4001, 3001, 2001, 101, TO_DATE('2025-12-20','YYYY-MM-DD'), TO_DATE('2025-12-28','YYYY-MM-DD'), 'Pneumonie', 'vindecat');
INSERT INTO internari (id_internare, id_pacient, id_medic, id_salon, data_internare, data_externare, diagnostic, stare_externare)
VALUES (4002, 3002, 2002, 102, TO_DATE('2025-12-22','YYYY-MM-DD'), NULL, 'Apendicita acuta', NULL);
INSERT INTO internari (id_internare, id_pacient, id_medic, id_salon, data_internare, data_externare, diagnostic, stare_externare)
VALUES (4003, 3003, 2003, 103, TO_DATE('2025-12-15','YYYY-MM-DD'), TO_DATE('2025-12-19','YYYY-MM-DD'), 'Bronșiolită', 'ameliorat');
INSERT INTO internari (id_internare, id_pacient, id_medic, id_salon, data_internare, data_externare, diagnostic, stare_externare)
VALUES (4004, 3004, 2004, 104, TO_DATE('2025-12-10','YYYY-MM-DD'), TO_DATE('2025-12-20','YYYY-MM-DD'), 'Migrena severă', 'transferat');
INSERT INTO internari (id_internare, id_pacient, id_medic, id_salon, data_internare, data_externare, diagnostic, stare_externare)
VALUES (4005, 3005, 2005, 105, TO_DATE('2025-12-05','YYYY-MM-DD'), NULL, 'Neoplasm', NULL);

-- Administrari medicamente
-- 4001 (internare cu externare 20-28 dec)
INSERT INTO internari_medicamente (id_internare, id_medicament, doza, frecventa, data_administrare, durata_zile)
VALUES (4001, 1001, '500 mg', 'de 3 ori/zi', TO_DATE('2025-12-21','YYYY-MM-DD'), 5);
INSERT INTO internari_medicamente (id_internare, id_medicament, doza, frecventa, data_administrare, durata_zile)
VALUES (4001, 1005, '20 mg', 'o data/zi', TO_DATE('2025-12-22','YYYY-MM-DD'), 7);

-- 4002 (internare activa din 22 dec)
INSERT INTO internari_medicamente (id_internare, id_medicament, doza, frecventa, data_administrare, durata_zile)
VALUES (4002, 1002, '200 mg', 'de 2 ori/zi', TO_DATE('2025-12-23','YYYY-MM-DD'), 3);
INSERT INTO internari_medicamente (id_internare, id_medicament, doza, frecventa, data_administrare, durata_zile)
VALUES (4002, 1004, '10 mg', 'la nevoie', TO_DATE('2025-12-24','YYYY-MM-DD'), 1);
INSERT INTO internari_medicamente (id_internare, id_medicament, doza, frecventa, data_administrare, durata_zile)
VALUES (4002, 1001, '500 mg', 'o data/zi', TO_DATE('2025-12-25','YYYY-MM-DD'), 2);

-- 4003 (15-19 dec)
INSERT INTO internari_medicamente (id_internare, id_medicament, doza, frecventa, data_administrare, durata_zile)
VALUES (4003, 1003, '1 g', 'o data/zi', TO_DATE('2025-12-16','YYYY-MM-DD'), 3);
INSERT INTO internari_medicamente (id_internare, id_medicament, doza, frecventa, data_administrare, durata_zile)
VALUES (4003, 1001, '500 mg', 'de 2 ori/zi', TO_DATE('2025-12-17','YYYY-MM-DD'), 2);

-- 4004 (10-20 dec)
INSERT INTO internari_medicamente (id_internare, id_medicament, doza, frecventa, data_administrare, durata_zile)
VALUES (4004, 1004, '10 mg', 'de 3 ori/zi', TO_DATE('2025-12-12','YYYY-MM-DD'), 2);
INSERT INTO internari_medicamente (id_internare, id_medicament, doza, frecventa, data_administrare, durata_zile)
VALUES (4004, 1005, '20 mg', 'o data/zi', TO_DATE('2025-12-13','YYYY-MM-DD'), 5);

-- 4005 (internari activa din 5 dec)
INSERT INTO internari_medicamente (id_internare, id_medicament, doza, frecventa, data_administrare, durata_zile)
VALUES (4005, 1003, '1 g', 'o data/zi', TO_DATE('2025-12-06','YYYY-MM-DD'), 7);
INSERT INTO internari_medicamente (id_internare, id_medicament, doza, frecventa, data_administrare, durata_zile)
VALUES (4005, 1002, '200 mg', 'de 2 ori/zi', TO_DATE('2025-12-07','YYYY-MM-DD'), 3);

COMMIT;
