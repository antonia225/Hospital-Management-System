# Hospital Admission Management Database 

![Oracle](https://img.shields.io/badge/Oracle-SQL%2FPLSQL-red)

Oracle SQL/PLSQL project focused on the full **patient admission process** in a hospital setting.

The implementation models how a patient is admitted, treated, monitored, and discharged, while enforcing safety and operational rules directly in the database layer.

## Project Overview

This project is centered on the admission lifecycle:

1. A patient is assigned to a doctor and a room.
2. Admission is allowed only if all linked entities are active and room capacity is not exceeded.
3. Medication administration is recorded only within the valid admission interval.
4. Discharge is validated against treatment plans and ICU minimum stay policies.
5. Critical objects are protected from accidental deletion or schema-level DROP operations.

The goal is to keep business logic close to data, so invalid states are blocked even if application code is bypassed.

## Main Components

### 1. Data Model (`create.sql`)

The schema defines entities required for admission management:

- Clinical context: `patients`, `blood_groups`
- Organization: `departments`, `rooms`, `room_types`
- Staff: `employees`, `doctors`, `nurses`
- Admission flow: `admissions`, `medicines`, `admission_medicines`

Key schema constraints include:

- PK/FK relationships for admission traceability
- Date consistency checks (`admission_date` vs `discharge_date`)
- Contact and format validation (SSN, phone, email)
- State consistency (`active` + `inactive_date`)

### 2. Trigger-Based Rule Enforcement

The project uses row-level, statement-level, compound, and schema-level triggers.

Important admission-related trigger logic:

- **Entity activation checks**: prevents admissions with inactive patient/doctor/room.
- **Room capacity checks**: compound trigger blocks admissions beyond room bed count.
- **Medication window checks**: blocks administration before admission or after discharge.
- **Discharge-treatment consistency**: blocks discharge if medication duration exceeds discharge date.
- **Soft delete policy**: blocks direct deletes for critical operational tables.
- **Role exclusivity**: employee cannot be registered simultaneously as doctor and nurse.
- **DDL protection**: prevents dropping core hospital tables.

### 3. PL/SQL Subprograms

- `finalize_discharge` (`procedures.sql`)
  Handles discharge workflow and raises targeted exceptions for invalid scenarios.

- `get_latest_admission_doctor` (`functions.sql`)
  Returns supervising doctor for the most recent admission of a patient.

- `report_doctors_by_department` (`cursors.sql`)
  Department/year reporting on doctors and number of admissions.

- `generate_patient_medical_report` (`collections.sql`)
  Full patient report using PL/SQL collections (medications, admission history, recent rooms).

- `pkg_medical_management` (`packages.sql`)
  Encapsulates reusable admission operations:
  - bed availability check
  - admission duration calculation
  - new admission registration
  - medicine assignment
  - complete admission details report

## Repository Structure

- `create.sql`  
  Schema, constraints, core triggers, and seed data.

- `procedures.sql`  
  Discharge validation procedure and execution block.

- `functions.sql`  
  Latest-admission-doctor function and execution block.

- `cursors.sql`  
  Cursor-based department reporting procedure and execution block.

- `collections.sql`  
  Collection-based patient medical report and execution block.

- `packages.sql`  
  Admission management package (spec + body) and execution block.

- `r_lmd_trigger.sql`  
  Row-level triggers for doctor/nurse role exclusivity + validation block.

- `c_lmd_trigger.sql`  
  Statement-level trigger for occupancy statistics + validation block.

- `ldd_trigger.sql`  
  Schema-level DROP-protection trigger + validation block.

## Environment

- Oracle Database (tested with Oracle Free)
- PDB: `FREEPDB1`
- SQL*Plus or SQL Developer
- Optional Docker setup for local Oracle instance

## How to Run

Connect to Oracle:

```bash
sqlplus APP_USER/your_password@//localhost:1521/FREEPDB1
```

Run scripts in this order:

```sql
@create.sql
@procedures.sql
@functions.sql
@cursors.sql
@collections.sql
@packages.sql
@r_lmd_trigger.sql
@c_lmd_trigger.sql
@ldd_trigger.sql
```

## Test Cases

Each script contains executable test blocks (`SET SERVEROUTPUT ON`) that validate expected behavior.

### `procedures.sql` (`finalize_discharge`)

- Case 1: valid discharge
- Case 2: incomplete medication plan (blocked)
- Case 3: ICU minimum stay violation (blocked)
- Case 4: inactive linked entity (blocked)
- Case 5: non-existent admission (handled)

### `functions.sql` (`get_latest_admission_doctor`)

- Case 1: valid patient with admissions
- Case 2: non-existent patient (`NO_DATA_FOUND` path)
- Case 3: duplicate patient name (`TOO_MANY_ROWS` path)

### `cursors.sql` (`report_doctors_by_department`)

- Case 1: reporting year with admissions
- Case 2: reporting year without admissions for some/all departments

### `collections.sql` (`generate_patient_medical_report`)

- Case 1: existing patient SSN with data
- Case 2: missing patient SSN

### `packages.sql` (`pkg_medical_management`)

- Test 1: room bed availability
- Test 2: admission duration calculation
- Test 3: new admission registration
- Test 4: medicine assignment for admission
- Test 5: details for newly inserted admission
- Test 6: details for existing admission with treatments

### `r_lmd_trigger.sql`

- Valid doctor insertion
- Invalid nurse insertion on same employee (blocked)
- Valid nurse insertion
- Invalid doctor insertion on same employee (blocked)

### `c_lmd_trigger.sql`

- INSERT single admission
- INSERT multiple admissions
- UPDATE diagnosis
- DELETE single discharge
- DELETE multiple discharges
- Trigger output shows operation type, impacted rooms, and occupancy metrics

### `ldd_trigger.sql`

- DROP on unprotected temporary table (allowed)
- DROP on protected core table (blocked)

## Author

Antonia Stoica
