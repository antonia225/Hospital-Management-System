-- Să se creeze un trigger LDD la nivel de schemă care monitorizează modificările 
-- de tip DDL și blochează încercările de ștergere a tabelelor protejate, pentru a 
-- nu se pierde datele gestionate prin mecanismul de „soft delete”. Trigger-ul se va 
-- declanșa la comenzi de tip DROP și va verifica numele obiectului vizat, iar dacă 
-- acesta este unul dintre tabelele esențiale ale aplicației (PACIENTI, SECTII, SALOANE, 
-- ANGAJATI, MEDICI, ASISTENTI, INTERNARI, INTERNARI_MEDICAMENTE, MEDICAMENTE), comanda 
-- va fi anulată prin ridicarea unei erori cu mesaj descriptiv. În acest fel, structura 
-- bazei de date rămâne protejată împotriva ștergerilor accidentale sau neautorizate.

CREATE OR REPLACE TRIGGER trg_protectie_drop_tabele
BEFORE DROP ON SCHEMA
DECLARE
  v_table_name VARCHAR2(50);
BEGIN
  v_table_name := UPPER(ora_dict_obj_name);
  
  IF v_table_name IN (
    'PACIENTI', 'SECTII', 'SALOANE', 'ANGAJATI', 'MEDICI', 'ASISTENTI',
    'INTERNARI', 'INTERNARI_MEDICAMENTE', 'MEDICAMENTE'
  ) THEN
    RAISE_APPLICATION_ERROR(-20200, 
      'ACCES INTERZIS: Tabelul ' || v_table_name || ' nu poate fi șters!');
  END IF;
END trg_protectie_drop_tabele;
/

SET SERVEROUTPUT ON;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Test 1: Creare tabel temporar de test');
  EXECUTE IMMEDIATE 'CREATE TABLE test_temp_drop (id NUMBER, descriere VARCHAR2(50))';
  DBMS_OUTPUT.PUT_LINE('SUCCESS: Tabel test_temp_drop creat.');
  DBMS_OUTPUT.PUT_LINE('');
  
  DBMS_OUTPUT.PUT_LINE('Test 2: Ștergere tabel temporar neprotejat (SUCCESS)');
  BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE test_temp_drop';
    DBMS_OUTPUT.PUT_LINE('SUCCESS: Tabelul test_temp_drop a fost șters (neprotejat).');
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('EROARE neașteptată: ' || SQLERRM);
  END;
  DBMS_OUTPUT.PUT_LINE('');
  
  DBMS_OUTPUT.PUT_LINE('Test 3: Încercare ștergere PACIENTI (BLOCAT)');
  BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE pacienti';
    DBMS_OUTPUT.PUT_LINE('EROARE: Nu ar fi trebuit să permită ștergerea!');
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('BLOCAT CORECT: ' || SQLERRM);
  END;
  DBMS_OUTPUT.PUT_LINE('');
END;
/

-- Pentru a șterge efectiv tabelele când e nevoie (ex: reset bază de date),
-- se dezactivează temporar trigger-ul:
--
-- ALTER TRIGGER trg_protectie_drop_tabele DISABLE;
-- 
-- NOTĂ: Pentru GRUPE_SANGE și TIPURI poate fi necesar
-- DROP TABLE ... CASCADE CONSTRAINTS din cauza FK-urilor existente.
--
-- DROP TABLE internari_medicamente CASCADE CONSTRAINTS;
-- DROP TABLE internari CASCADE CONSTRAINTS;
-- DROP TABLE asistenti CASCADE CONSTRAINTS;
-- DROP TABLE medici CASCADE CONSTRAINTS;
-- ... (restul tabelelor)
--
-- ALTER TRIGGER trg_protectie_drop_tabele ENABLE;
