# Feature: Patient Discharge (Desligamento de Paciente)

## User Stories
- US-01: Discharge patient (POST /patients/{patientId}/discharge)
- US-02: Readmit patient (POST /patients/{patientId}/readmit)
- US-03: Filter patients by status (GET /patients?status=active|discharged)

## Domain Changes
- New VOs: PatientStatus, DischargeReason, DischargeInfo
- Aggregate Patient: +status, +dischargeInfo, discharge(), readmit()
- New Events: PatientDischargedEvent, PatientReadmittedEvent

## Application Changes
- DischargePatientCommand + Handler
- ReadmitPatientCommand + Handler
- ListPatientsQuery: +status filter

## IO Changes
- Migration: add status, discharge_reason, discharge_notes, discharged_at, discharged_by columns
- Controller: discharge + readmit endpoints
- Repository: list() with status filter
- DTOs: DischargePatientRequest, ReadmitPatientRequest, PatientResponse +status

## Error Codes
- DISC-001: Patient already discharged (409)
- DISC-002: Invalid reason (400)
- DISC-003: Notes required when reason=other (400)
- DISC-004: Patient not found (404)
- READM-001: Patient already active (409)
- READM-002: Patient not found (404)
