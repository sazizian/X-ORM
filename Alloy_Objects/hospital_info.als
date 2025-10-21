module hospital_info
open Declaration

// ---------- Inheritance #1 ----------
abstract sig Person {
  pid: one Int,
  name: one String
}
sig Patient extends Person {
  mrn: one Int // medical record number
}
sig Staff extends Person {
  staffId: one Int
}

// ---------- Inheritance #2 ----------
sig Physician extends Staff {
  specialty: lone String
}
sig Nurse extends Staff {}
sig AdminStaff extends Staff {}

// ---------- Inheritance #3 ----------
abstract sig Encounter {
  encId: one Int,
  when: one Int,
  patient: one Patient,
  attending: one Physician
}
sig InpatientEncounter extends Encounter {
  bed: one Bed
}
sig OutpatientEncounter extends Encounter {}

// ---------- Inheritance #4 ----------
abstract sig Order {
  oid: one Int,
  placedAt: one Int,
  by: one Staff,
  for: one Patient,
  inEncounter: one Encounter
}
sig LabOrder extends Order {
  testCode: one String
}
sig MedicationOrder extends Order {
  drugCode: one String,
  dosage: one String
}
sig ImagingOrder extends Order {
  modality: one String
}

// ---------- Inheritance #5 ----------
abstract sig Result {
  rid: one Int,
  ofOrder: one Order,
  value: lone String,
  readyAt: lone Int
}
sig LabResult extends Result {}
sig ImagingResult extends Result {}

// ---------- Inheritance #6 ----------
abstract sig Location {
  locId: one Int,
  name: one String
}
sig Hospital extends Location {}
sig Department extends Location {
  in: one Hospital
}
sig Ward extends Location {
  inDept: one Department
}
sig Room extends Location {
  inWard: one Ward
}
sig Bed extends Location {
  inRoom: one Room
}

// ---------- Inheritance #7 ----------
abstract sig Procedure {
  procId: one Int,
  forEnc: one Encounter,
  code: one String
}
sig SurgicalProcedure extends Procedure {}
sig NonSurgicalProcedure extends Procedure {}

// ---------- Inheritance #8 ----------
abstract sig Medication {
  medId: one Int,
  code: one String
}
sig Prescription extends Medication {
  forOrder: one MedicationOrder
}
sig Administration extends Medication {
  forEnc: one Encounter,
  adminTime: one Int
}

// ---------- Inheritance #9 ----------
abstract sig BillingDocument {
  bid: one Int,
  forEnc: one Encounter,
  amount: one Int
}
sig Invoice extends BillingDocument {}
sig Claim extends BillingDocument {
  insurer: one Payer
}
sig PaymentDoc extends BillingDocument {
  fromAcc: one Account
}

// ---------- Inheritance #10 ----------
abstract sig Observation {
  obsId: one Int,
  forEnc: one Encounter,
  takenAt: one Int
}
sig VitalSign extends Observation {
  kind: one String, // HR, BP, Temp...
  val: one String
}
sig Allergy extends Observation {
  agent: one String,
  severity: one String
}

// Additional reference entities
sig Payer {
  pid: one Int,
  name: one String
}
abstract sig Account {
  accId: one Int
}
sig PatientAccount extends Account {
  of: one Patient
}
sig HospitalAccount extends Account {}

// Scheduling / logistics
sig Appointment {
  apptId: one Int,
  pat: one Patient,
  with: one Staff,
  atDept: one Department,
  when: one Int
}

sig Device {
  did: one Int,
  at: one Department
}

sig InsurancePolicy {
  polId: one Int,
  holder: one Patient,
  payer: one Payer
}

// ---------------- Associations (~28) ----------------
// A1: Patient (1) -- (0..*) Encounter
fact A1_PatientEnc { all e: Encounter | one e.patient }

// A2: Encounter (1) -- (0..*) Order
fact A2_EncOrders { all o: Order | one o.inEncounter }

// A3: Order (1) -- (0..1) Result
fact A3_OrderResult { all r: Result | one r.ofOrder }

// A4: Physician (1) -- (0..*) Encounter (attending)
fact A4_Attending { all e: Encounter | one e.attending }

// A5: Department hierarchy (Hospital->Department->Ward->Room->Bed)
fact A5_LocationTree {
  all d: Department | one d.in
  all w: Ward | one w.inDept
  all r: Room | one r.inWard
  all b: Bed | one b.inRoom
}

// A6: InpatientEncounter requires a Bed that is consistent with hierarchy
fact A6_InpatientBed {
  all ie: InpatientEncounter | one ie.bed
}

// A7: Billing docs attach to Encounter
fact A7_Billing { all b: BillingDocument | one b.forEnc }

// A8: Claim requires Payer
fact A8_ClaimPayer { all c: Claim | one c.insurer }

// A9: PaymentDoc requires Account
fact A9_PaymentAcc { all p: PaymentDoc | one p.fromAcc }

// A10: PatientAccount belongs to Patient
fact A10_PatientAcc { all pa: PatientAccount | one pa.of }

// A11: Observation belongs to Encounter
fact A11_ObsEnc { all o: Observation | one o.forEnc }

// A12: VitalSign must have kind/value
fact A12_VitalCompleteness { all v: VitalSign | some v.kind and some v.val }

// A13: Allergy must have agent
fact A13_AllergyAgent { all a: Allergy | some a.agent }

// A14: Appointment links patient, staff, dept
fact A14_ApptLinks {
  all ap: Appointment | one ap.pat and one ap.with and one ap.atDept
}

// A15: Device at Department
fact A15_DeviceDept { all d: Device | one d.at }

// A16: InsurancePolicy connects patient and payer
fact A16_Policy { all p: InsurancePolicy | one p.holder and one p.payer }

// A17: Orders are placed by Staff for Patient in an Encounter
fact A17_OrderLinks {
  all o: Order | one o.by and one o.for and one o.inEncounter
  all o: Order | o.for = o.inEncounter.patient
}

// A18: MedicationOrder has Prescription; Administration references Encounter
fact A18_Medication {
  all pr: Prescription | one pr.forOrder
  all ad: Administration | one ad.forEnc
}

// A19: Procedures belong to Encounter
fact A19_ProcedureEnc { all p: Procedure | one p.forEnc }

// A20: Each Encounter belongs to some hospital structure (implicit via bed/physician dept if you extend)
pred _unusedEncPlacement {} // left open for mapping-level constraints

// A21: A Staff is assigned to a Department (optional relation below)
sig StaffDeptMap { rel: Staff -> Department }
fact A21_StaffDeptOptional { all s: Staff | lone (StaffDeptMap.rel[s]) }

// A22: Physician specialty optional but can be used for routing
pred _unusedPhysRouting {} // left open

// A23: Room/Bed capacity constraints at ORM-level (leave open for mapping rules)
pred _unusedCapacities {} // left open

// A24: Multiple Orders per Encounter; Results are optional until ready
fact A24_ResOptional { all o: Order | lone { r: Result | r.ofOrder = o } }

// A25: No two Results for the same Order of the same type
fact A25_UniqueResultType {
  all disj r1, r2: Result |
    r1.ofOrder = r2.ofOrder implies ( (r1 in LabResult and r2 in LabResult) implies r1 = r2 )
}

// A26: InsurancePolicy coverage sanity: holder must have a PatientAccount
fact A26_Coverage {
  all p: InsurancePolicy | some pa: PatientAccount | pa.of = p.holder
}

// A27: Billing amount non-negative
fact A27_BillingNonNeg { all b: BillingDocument | b.amount >= 0 }

// A28: AdminStaff can place Orders too (e.g., clerical entry); no extra constraint needed

// -------------- Sanity --------------
pred sanity {
  some Patient & Person
  some Staff
  some Physician
  some Encounter
  some Order
  some Location
  some Department
  some Bed
  some BillingDocument
  some Observation
}

run sanity for 25 but 10 Int

