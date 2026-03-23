-- Să se creeze un pachet pentru gestionarea procesului de internare și a administrării 
-- medicamentelor pe durata internării. Pachetul va defini două tipuri de date complexe, 
-- unul pentru stocarea completă a detaliilor unei internări (record) și unul pentru lista 
-- medicamentelor administrate unui pacient (nested table), astfel încât informațiile să 
-- poată fi prelucrate unitar. În cadrul pachetului se vor implementa două funcții: una 
-- care verifică disponibilitatea paturilor dintr-un salon și returnează numărul de locuri 
-- libere, respectiv una care calculează durata unei internări în zile. De asemenea, se vor 
-- implementa două proceduri: una care înregistrează o internare nouă folosind regulile deja 
-- existente în schemă (constrângeri și trigger-e) și una care adaugă/înregistrează administrarea 
-- unui medicament în perioada internării. Prin aceste componente, pachetul oferă un flux 
-- integrat pentru internare și tratament, fără a duplica regulile de validare deja impuse 
-- în baza de date.

CREATE OR REPLACE PACKAGE pkg_gestiune_medicala AS
  -- Tipuri de date
  TYPE t_detalii_internare IS RECORD (
    id_internare internari.id_internare%TYPE,
    nume_pacient angajati.nume%TYPE,
    prenume_pacient angajati.prenume%TYPE,
    nume_medic angajati.nume%TYPE,
    prenume_medic angajati.prenume%TYPE,
    nr_salon saloane.nr_salon%TYPE,
    data_internare internari.data_internare%TYPE,
    data_externare internari.data_externare%TYPE,
    diagnostic internari.diagnostic%TYPE
  );
  
  TYPE t_medicament_rec IS RECORD (
    denumire medicamente.denumire%TYPE,
    doza internari_medicamente.doza%TYPE,
    data_administrare internari_medicamente.data_administrare%TYPE
  );
  
  TYPE t_medicamente_administrate IS TABLE OF t_medicament_rec;
  
  -- Funcții
  FUNCTION verifica_disponibilitate_paturi(
    p_id_salon saloane.id_salon%TYPE,
    p_data_internare DATE
  ) RETURN NUMBER;
  
  FUNCTION calculeaza_durata_internare(
    p_id_internare internari.id_internare%TYPE
  ) RETURN NUMBER;
  
  -- Proceduri
  PROCEDURE inregistreaza_internare_noua(
    p_id_internare internari.id_internare%TYPE,
    p_id_pacient pacienti.id_pacient%TYPE,
    p_id_medic medici.id_angajat%TYPE,
    p_id_salon saloane.id_salon%TYPE,
    p_data_internare DATE,
    p_diagnostic VARCHAR2
  );
  
  PROCEDURE adauga_medicament_internare(
    p_id_internare internari.id_internare%TYPE,
    p_id_medicament medicamente.id_medicament%TYPE,
    p_doza VARCHAR2,
    p_frecventa VARCHAR2,
    p_data_administrare DATE,
    p_durata_zile NUMBER
  );
  
  PROCEDURE afiseaza_detalii_internare(
    p_id_internare internari.id_internare%TYPE
  );
END pkg_gestiune_medicala;
/

CREATE OR REPLACE PACKAGE BODY pkg_gestiune_medicala AS

  FUNCTION verifica_disponibilitate_paturi(
    p_id_salon saloane.id_salon%TYPE,
    p_data_internare DATE
  ) RETURN NUMBER IS
    v_nr_paturi NUMBER;
    v_paturi_ocupate NUMBER;
  BEGIN
    -- Obține capacitatea salonului
    SELECT nr_paturi INTO v_nr_paturi
    FROM saloane
    WHERE id_salon = p_id_salon AND activ = 'Y';
    
    -- Numără internările active la data respectivă
    SELECT COUNT(*) INTO v_paturi_ocupate
    FROM internari
    WHERE id_salon = p_id_salon
      AND data_internare <= p_data_internare
      AND (data_externare IS NULL OR data_externare >= p_data_internare);
    
    RETURN v_nr_paturi - v_paturi_ocupate;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20310, 'Salon inexistent sau inactiv: ' || p_id_salon);
  END verifica_disponibilitate_paturi;
  
  -- Funcție: Calculează durata internării (zile)
  FUNCTION calculeaza_durata_internare(
    p_id_internare internari.id_internare%TYPE
  ) RETURN NUMBER IS
    v_data_int DATE;
    v_data_ext DATE;
  BEGIN
    SELECT data_internare, data_externare
    INTO v_data_int, v_data_ext
    FROM internari
    WHERE id_internare = p_id_internare;
    
    IF v_data_ext IS NULL THEN
      RETURN TRUNC(SYSDATE - v_data_int);
    ELSE
      RETURN TRUNC(v_data_ext - v_data_int);
    END IF;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN NULL;
  END calculeaza_durata_internare;
  
  -- Procedură: Înregistrează internare nouă
  PROCEDURE inregistreaza_internare_noua(
    p_id_internare internari.id_internare%TYPE,
    p_id_pacient pacienti.id_pacient%TYPE,
    p_id_medic medici.id_angajat%TYPE,
    p_id_salon saloane.id_salon%TYPE,
    p_data_internare DATE,
    p_diagnostic VARCHAR2
  ) IS
  BEGIN
    -- Inserează internarea
    INSERT INTO internari (id_internare, id_pacient, id_medic, id_salon, data_internare, diagnostic)
    VALUES (p_id_internare, p_id_pacient, p_id_medic, p_id_salon, p_data_internare, p_diagnostic);
    
    DBMS_OUTPUT.PUT_LINE('SUCCESS: Internare înregistrată cu ID ' || p_id_internare);
  END inregistreaza_internare_noua;
  
  -- Procedură: Adaugă medicament la internare
  PROCEDURE adauga_medicament_internare(
    p_id_internare internari.id_internare%TYPE,
    p_id_medicament medicamente.id_medicament%TYPE,
    p_doza VARCHAR2,
    p_frecventa VARCHAR2,
    p_data_administrare DATE,
    p_durata_zile NUMBER
  ) IS
  BEGIN
    -- Inserează medicamentul
    INSERT INTO internari_medicamente 
      (id_internare, id_medicament, doza, frecventa, data_administrare, durata_zile)
    VALUES 
      (p_id_internare, p_id_medicament, p_doza, p_frecventa, p_data_administrare, p_durata_zile);
    
    DBMS_OUTPUT.PUT_LINE('SUCCESS: Medicament adăugat la internarea ' || p_id_internare);
  END adauga_medicament_internare;
  
  -- Procedură: Afișează detalii complete internare
  PROCEDURE afiseaza_detalii_internare(
    p_id_internare internari.id_internare%TYPE
  ) IS
    v_detalii t_detalii_internare;
    v_medicamente t_medicamente_administrate := t_medicamente_administrate();
    v_durata NUMBER;
  BEGIN
    -- Obține detalii internare
    SELECT 
      i.id_internare,
      p.nume, p.prenume,
      a.nume, a.prenume,
      s.nr_salon,
      i.data_internare,
      i.data_externare,
      i.diagnostic
    INTO v_detalii
    FROM internari i
    JOIN pacienti p ON i.id_pacient = p.id_pacient
    JOIN medici m ON i.id_medic = m.id_angajat
    JOIN angajati a ON m.id_angajat = a.id_angajat
    JOIN saloane s ON i.id_salon = s.id_salon
    WHERE i.id_internare = p_id_internare;
    
    -- Obține medicamente
    FOR rec IN (
      SELECT m.denumire, im.doza, im.data_administrare
      FROM internari_medicamente im
      JOIN medicamente m ON im.id_medicament = m.id_medicament
      WHERE im.id_internare = p_id_internare
      ORDER BY im.data_administrare
    ) LOOP
      v_medicamente.EXTEND;
      v_medicamente(v_medicamente.COUNT).denumire := rec.denumire;
      v_medicamente(v_medicamente.COUNT).doza := rec.doza;
      v_medicamente(v_medicamente.COUNT).data_administrare := rec.data_administrare;
    END LOOP;
    
    -- Calculează durata
    v_durata := calculeaza_durata_internare(p_id_internare);
    
    -- Afișează
    DBMS_OUTPUT.PUT_LINE('RAPORT INTERNARE #' || v_detalii.id_internare);
    DBMS_OUTPUT.PUT_LINE('Pacient: ' || v_detalii.nume_pacient || ' ' || v_detalii.prenume_pacient);
    DBMS_OUTPUT.PUT_LINE('Medic coordonator: ' || v_detalii.nume_medic || ' ' || v_detalii.prenume_medic);
    DBMS_OUTPUT.PUT_LINE('Salon: ' || v_detalii.nr_salon);
    DBMS_OUTPUT.PUT_LINE('Data internare: ' || TO_CHAR(v_detalii.data_internare, 'DD-MON-YYYY'));
    DBMS_OUTPUT.PUT_LINE('Data externare: ' || 
      CASE WHEN v_detalii.data_externare IS NULL THEN 'În curs' 
           ELSE TO_CHAR(v_detalii.data_externare, 'DD-MON-YYYY') END);
    DBMS_OUTPUT.PUT_LINE('Durata: ' || v_durata || ' zile');
    DBMS_OUTPUT.PUT_LINE('Diagnostic: ' || NVL(v_detalii.diagnostic, 'N/A'));
    
    DBMS_OUTPUT.PUT_LINE('--- Medicamente administrate ---');
    IF v_medicamente.COUNT = 0 THEN
      DBMS_OUTPUT.PUT_LINE('  (Niciun medicament)');
    ELSE
      FOR i IN v_medicamente.FIRST..v_medicamente.LAST LOOP
        DBMS_OUTPUT.PUT_LINE('  ' || v_medicamente(i).denumire || 
          ' - ' || v_medicamente(i).doza || 
          ' (de la ' || TO_CHAR(v_medicamente(i).data_administrare, 'DD-MON-YYYY') || ')');
      END LOOP;
    END IF;
  END afiseaza_detalii_internare;
END pkg_gestiune_medicala;
/

SET SERVEROUTPUT ON;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Test 1: Verificare disponibilitate paturi');
  DBMS_OUTPUT.PUT_LINE('Paturi disponibile în salon 101: ' || 
    pkg_gestiune_medicala.verifica_disponibilitate_paturi(101, SYSDATE));
  DBMS_OUTPUT.PUT_LINE('');
  
  DBMS_OUTPUT.PUT_LINE('Test 2: Calcul durata internare');
  DBMS_OUTPUT.PUT_LINE('Durata internare 4001: ' || 
    pkg_gestiune_medicala.calculeaza_durata_internare(4001) || ' zile');
  DBMS_OUTPUT.PUT_LINE('');
  
  DBMS_OUTPUT.PUT_LINE('Test 3: Înregistrare internare nouă');
  pkg_gestiune_medicala.inregistreaza_internare_noua(
    p_id_internare => 4006,
    p_id_pacient => 3001,
    p_id_medic => 2001,
    p_id_salon => 101,
    p_data_internare => SYSDATE,
    p_diagnostic => 'Control periodic'
  );
  DBMS_OUTPUT.PUT_LINE('');
  
  DBMS_OUTPUT.PUT_LINE('Test 4: Adăugare medicament');
  pkg_gestiune_medicala.adauga_medicament_internare(
    p_id_internare => 4006,
    p_id_medicament => 1001,
    p_doza => '500 mg',
    p_frecventa => '2 ori/zi',
    p_data_administrare => SYSDATE,
    p_durata_zile => 5
  );
  DBMS_OUTPUT.PUT_LINE('');
  
  DBMS_OUTPUT.PUT_LINE('Test 5: Afișare detalii internare completă');
  pkg_gestiune_medicala.afiseaza_detalii_internare(4006);
  DBMS_OUTPUT.PUT_LINE('');
  
  DBMS_OUTPUT.PUT_LINE('Test 6: Afișare internare existentă cu medicamente');
  pkg_gestiune_medicala.afiseaza_detalii_internare(4001);

  ROLLBACK;
END;
/
