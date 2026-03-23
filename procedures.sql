-- Să se implementeze o procedură care primește ca parametri ID-ul unei internări și o dată 
-- de externare propusă și verifică dacă externarea pacientului este permisă. Validarea se 
-- realizează printr-o singură interogare SQL, folosind informații despre internare, pacient, 
-- medicul coordonator și salon. Se ridică excepția medicament_incomplet dacă există tratamente 
-- care ar depăși data externării propuse, externare_ati_restrictionata dacă pacientul este 
-- internat la ATI și durata internării este mai mică de 3 zile, respectiv entitate_inactiva 
-- dacă pacientul, medicul sau salonul sunt marcate ca inactive în sistem. Dacă toate condițiile 
-- sunt îndeplinite, se actualizează înregistrarea internării cu data externării și starea „vindecat”. 
-- Procedura se va apela astfel încât să fie evidențiate toate excepțiile definite, precum și un 
-- caz de externare realizată cu succes.

CREATE OR REPLACE PROCEDURE finalizeaza_externare(
  p_id_internare internari.id_internare%TYPE,
  p_data_externare DATE
) IS
  medicament_incomplet EXCEPTION;
  externare_ati_restrictionata EXCEPTION;
  entitate_inactiva EXCEPTION;

  v_tip_salon VARCHAR2(20);
  v_data_internare DATE;
  v_entitate_inactiva NUMBER;
  v_medicament_incomplet NUMBER;
BEGIN
  SELECT COUNT(*)
  INTO v_entitate_inactiva
  FROM internari i
  JOIN pacienti p ON i.id_pacient = p.id_pacient
  JOIN medici m ON i.id_medic = m.id_angajat
  JOIN angajati a ON m.id_angajat = a.id_angajat
  JOIN saloane s ON i.id_salon = s.id_salon
  WHERE i.id_internare = p_id_internare
    AND (p.activ = 'N' OR m.activ = 'N' OR s.activ = 'N');

  IF v_entitate_inactiva > 0 THEN
    RAISE entitate_inactiva;
  END IF;
  
  SELECT COUNT(*)
  INTO v_medicament_incomplet
  FROM internari_medicamente
  WHERE id_internare = p_id_internare
    AND (data_administrare + durata_zile - 1) > p_data_externare;
  
  IF v_medicament_incomplet > 0 THEN
    RAISE medicament_incomplet;
  END IF;
  
  SELECT t.denumire, i.data_internare
  INTO v_tip_salon, v_data_internare
  FROM internari i
  JOIN saloane s ON i.id_salon = s.id_salon
  JOIN tipuri t ON s.tip = t.id_tip
  WHERE i.id_internare = p_id_internare;
  
  IF p_data_externare IS NULL THEN
    RAISE_APPLICATION_ERROR(-20007, 'Data externarii este obligatorie.');
  END IF;
  
  IF p_data_externare < v_data_internare THEN
    RAISE_APPLICATION_ERROR(-20008, 'Data externarii nu poate fi inainte de data internarii.');
  END IF;
  
  IF UPPER(v_tip_salon) = 'ATI' AND (p_data_externare - v_data_internare) < 3 THEN
    RAISE externare_ati_restrictionata;
  END IF;
  
  UPDATE internari
  SET data_externare = p_data_externare,
      stare_externare = 'vindecat'
  WHERE id_internare = p_id_internare;
  DBMS_OUTPUT.PUT_LINE('SUCCESS: Externare finalizată cu succes pentru internarea ' || p_id_internare);
  
EXCEPTION
  WHEN medicament_incomplet THEN
    DBMS_OUTPUT.PUT_LINE('EROARE: Există medicamente incomplete la data externării propuse.');
  WHEN externare_ati_restrictionata THEN
    DBMS_OUTPUT.PUT_LINE('EROARE: Pacienții din ATI trebuie să fie internați minim 3 zile.');
  WHEN entitate_inactiva THEN
    DBMS_OUTPUT.PUT_LINE('EROARE: Una dintre entități (pacient/medic/salon) este inactivă.');
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('EROARE: Internarea ' || p_id_internare || ' nu există.');
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('EROARE: ' || SQLERRM);
END finalizeaza_externare;
/

SET SERVEROUTPUT ON;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Ex 1: Externare validă');
  finalizeaza_externare(4001, TO_DATE('2025-12-28','YYYY-MM-DD'));
  DBMS_OUTPUT.PUT_LINE('');
  
  DBMS_OUTPUT.PUT_LINE('Ex 2: Medicament incomplet');
  UPDATE internari SET data_externare = NULL, stare_externare = NULL 
  WHERE id_internare = 4001;
  finalizeaza_externare(4001, TO_DATE('2025-12-27','YYYY-MM-DD'));
  DBMS_OUTPUT.PUT_LINE('');
  
  DBMS_OUTPUT.PUT_LINE('Ex 3: Externare ATI restrictionata');
  UPDATE internari SET data_externare = NULL, stare_externare = NULL 
  WHERE id_internare = 4004;
  finalizeaza_externare(4004, TO_DATE('2025-12-12','YYYY-MM-DD'));
  DBMS_OUTPUT.PUT_LINE('');
  
  DBMS_OUTPUT.PUT_LINE('Ex 4: Entitate inactiva');
  UPDATE pacienti SET activ = 'N', data_inactivare = SYSDATE 
  WHERE id_pacient = 3001;
  finalizeaza_externare(4001, TO_DATE('2025-12-28','YYYY-MM-DD'));

  UPDATE pacienti SET activ = 'Y', data_inactivare = NULL 
  WHERE id_pacient = 3001;
  DBMS_OUTPUT.PUT_LINE('');
  
  DBMS_OUTPUT.PUT_LINE('Ex 5: Internare inexistentă');
  finalizeaza_externare(99999, TO_DATE('2025-12-28','YYYY-MM-DD'));
  
  ROLLBACK;
END;
/
