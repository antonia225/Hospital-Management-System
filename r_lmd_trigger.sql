-- Să se implementeze trigger-e LMD la nivel de rând pentru a menține corectă înregistrarea 
-- subtipurilor de angajați. Un angajat poate fi încadrat fie ca medic, fie ca asistent, dar 
-- nu în ambele categorii în același timp. Se vor crea două trigger-e: unul pe tabelul MEDICI 
-- și unul pe tabelul ASISTENTI, care se declanșează la fiecare operațiune de inserare și 
-- verifică dacă angajatul respectiv nu există deja în celălalt tabel. Dacă regula este încălcată, 
-- trigger-ul va opri inserarea și va genera o eroare cu un mesaj clar, care explică motivul. 
-- Implementarea se va valida prin teste cu inserări atât valide, cât și invalide.

CREATE OR REPLACE TRIGGER trg_angajat_unic_rol_medic
BEFORE INSERT OR UPDATE OF id_angajat ON medici
FOR EACH ROW
DECLARE
  v_exists NUMBER;
BEGIN
  IF INSERTING OR :NEW.id_angajat != :OLD.id_angajat THEN
    SELECT COUNT(*) INTO v_exists 
    FROM asistenti WHERE id_angajat = :NEW.id_angajat;
    
    IF v_exists > 0 THEN
      RAISE_APPLICATION_ERROR(-20030, 
        'EROARE: Angajatul cu ID ' || :NEW.id_angajat || ' este deja înregistrat ca asistent.');
    END IF;
  END IF;
END trg_angajat_unic_rol_medic;
/

CREATE OR REPLACE TRIGGER trg_angajat_unic_rol_asist
BEFORE INSERT OR UPDATE OF id_angajat ON asistenti
FOR EACH ROW
DECLARE
  v_exists NUMBER;
BEGIN
  IF INSERTING OR :NEW.id_angajat != :OLD.id_angajat THEN
    SELECT COUNT(*) INTO v_exists 
    FROM medici WHERE id_angajat = :NEW.id_angajat;
    
    IF v_exists > 0 THEN
      RAISE_APPLICATION_ERROR(-20031, 
        'EROARE: Angajatul cu ID ' || :NEW.id_angajat || ' este deja înregistrat ca medic.');
    END IF;
  END IF;
END trg_angajat_unic_rol_asist;
/

SET SERVEROUTPUT ON;
DECLARE
  v_id_medic NUMBER;
  v_id_asist NUMBER;
BEGIN
  SELECT NVL(MAX(id_angajat), 2000) + 1
  INTO v_id_medic
  FROM angajati;
  v_id_asist := v_id_medic + 1;

  DBMS_OUTPUT.PUT_LINE('Test 1: medic valid');
  INSERT INTO angajati (id_angajat, nume, prenume, data_angajare, data_nastere, telefon, email, salariu)
  VALUES (v_id_medic, 'Test', 'Medic', SYSDATE, ADD_MONTHS(SYSDATE, -360),
          '07' || LPAD(v_id_medic, 8, '0'), 'test.medic' || v_id_medic || '@spital.ro', 10000);
  INSERT INTO medici (id_angajat, specializare, cod_parafa, grad)
  VALUES (v_id_medic, 'Medicina Generala', 'PARA' || v_id_medic, 'rezident');

  DBMS_OUTPUT.PUT_LINE('Test 2: asistent pe acelasi angajat (invalid)');
  BEGIN
    INSERT INTO asistenti (id_angajat, tip, id_salon)
    VALUES (v_id_medic, 'generalist', 101);
    DBMS_OUTPUT.PUT_LINE('EROARE: nu trebuia sa permita.');
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('BLOCAT CORECT.');
  END;

  DBMS_OUTPUT.PUT_LINE('Test 3: asistent valid');
  INSERT INTO angajati (id_angajat, nume, prenume, data_angajare, data_nastere, telefon, email, salariu)
  VALUES (v_id_asist, 'Test', 'Asistent', SYSDATE, ADD_MONTHS(SYSDATE, -300),
          '07' || LPAD(v_id_asist, 8, '0'), 'test.asist' || v_id_asist || '@spital.ro', 7000);
  INSERT INTO asistenti (id_angajat, tip, id_salon)
  VALUES (v_id_asist, 'medical', 102);

  DBMS_OUTPUT.PUT_LINE('Test 4: medic pe acelasi angajat (invalid)');
  BEGIN
    INSERT INTO medici (id_angajat, specializare, cod_parafa, grad)
    VALUES (v_id_asist, 'Chirurgie', 'PARA' || v_id_asist, 'specialist');
    DBMS_OUTPUT.PUT_LINE('EROARE: nu trebuia sa permita.');
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('BLOCAT CORECT.');
  END;

  ROLLBACK;
END;
/
