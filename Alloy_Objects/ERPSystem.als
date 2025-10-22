module ERPSystem
open Declaration

// -------------------- Time Stub --------------------
abstract sig Date {}

// -------------------- Organization -----------------
sig Company {
  departments : set Department,
  warehouses  : set Warehouse
}

sig Department {
  company   : one Company,
  employees : set Employee
}

sig Warehouse {
  company : one Company
}

// -------------------- Parties ----------------------
abstract sig Party {}

sig Customer extends Party {}
sig Supplier extends Party {}
sig Employee extends Party {
  company : one Company,
  dept    : one Department
}

// Dept/Employee coherence + aggregation into company
fact DeptEmployeeCoherence {
  // Department employees are exactly those pointing to it
  all d: Department | d.employees = { e: Employee | e.dept = d }
  // Dept->Company consistency
  all e: Employee | e.dept.company = e.company
}

fact CompanyAggregations {
  all c: Company |
    c.departments = { d: Department | d.company = c } and
    c.warehouses  = { w: Warehouse  | w.company  = c }
}

// -------------------- Items & BOM ------------------
sig Item {
  bom : lone BOM
}

sig BOM {
  parent     : one Item,
  components : set Item
}

// No cyclic dependencies in BOM
fact BOM_Acyclic { all b: BOM | b.parent not in ^components }

// -------------------- Documents --------------------
abstract sig Doc {
  company : one Company,
  date    : one Date
}

// -------------------- Sales & Purchase -------------
sig SalesOrder extends Doc {
  customer : one Customer,
  lines    : some SOLine
}

sig PurchaseOrder extends Doc {
  supplier : one Supplier,
  lines    : some POLine
}

// -------------------- Invoices ---------------------
sig SalesInvoice extends Doc {
  customer : one Customer,
  source   : lone SalesOrder,
  lines    : some SalesInvLine
}

sig PurchaseInvoice extends Doc {
  supplier : one Supplier,
  source   : lone PurchaseOrder,
  lines    : some PurchaseInvLine
}

// -------------------- Lines (Quantities, Items) ----
abstract sig Line {
  item : one Item,
  qty  : one Int
}

sig SOLine extends Line { order : one SalesOrder }
sig POLine extends Line { order : one PurchaseOrder }

// Split invoice lines by direction for stricter typing
sig SalesInvLine extends Line { invoice : one SalesInvoice }
sig PurchaseInvLine extends Line { invoice : one PurchaseInvoice }

// Quantities must be strictly positive
fact PositiveQuantities { all l: Line | l.qty > 0 }

// Company consistency (lines/documents)
fact SalesPurchaseCoherence {
  all so: SalesOrder | so.lines.order = so
  all po: PurchaseOrder | po.lines.order = po

  all si: SalesInvoice |
    (no si.source or si.source.customer = si.customer) and
    all l: SalesInvLine | l.invoice = si and l.invoice.company = si.company

  all pi: PurchaseInvoice |
    (no pi.source or pi.source.supplier = pi.supplier) and
    all l: PurchaseInvLine | l.invoice = pi and l.invoice.company = pi.company
}

// -------------------- Warehouse & Stock ------------
sig StockLedgerEntry extends Doc {
  item      : one Item,
  warehouse : one Warehouse,
  deltaQty  : one Int
}

// SLE belongs to same company as its warehouse
fact StockCompanyConsistency {
  all e: StockLedgerEntry | e.company = e.warehouse.company
}

// -------------------- Production -------------------
sig ProductionOrder extends Doc {
  bom : one BOM,
  qty : one Int
}

fact ProductionPositiveQty { all p: ProductionOrder | p.qty > 0 }

// -------------------- Payments ---------------------
sig CustomerPayment extends Doc {
  payer    : one Customer,
  invoices : some SalesInvoice
}

sig SupplierPayment extends Doc {
  payee    : one Supplier,
  invoices : some PurchaseInvoice
}

fact PaymentCompanyConsistency {
  all p: CustomerPayment | all inv: p.invoices | inv.company = p.company
  all p: SupplierPayment | all inv: p.invoices | inv.company = p.company
}

// ===================================================
//            FEATURE FLAGS (Schema Hints)
// ===================================================
// These are *hints* to downstream synthesis/serializers. They do not
// change validity here, but allow experiments with indexing/normalization.

// Feature atoms you can toggle on/off.
abstract sig Feature {}

// Index hints (suggest adding indexes in the ORM/DDL stage)
sig FKIndex, CompositeItemIndex, DateIndex extends Feature {}

// Normalization/denormalization hints
// - NormalizeAssocTables: prefer join tables for N:M
// - DenormalizeParty: allow duplicating key party attributes in docs for read-heavy workloads
// - FlattenPartyHierarchy: collapse Customer/Supplier into Party with discriminator
sig NormalizeAssocTables, DenormalizeParty, FlattenPartyHierarchy extends Feature {}

// For 1:N associations (e.g., Order->Line), a join-table vs FK is typical FK;
// these hints are mainly for your pipeline to try alternatives.

// Singleton to carry enabled features.
one sig SchemaOptions {
  enabled : set Feature
}

// Convenience facts (optional guards you can use downstream)
// (No hard constraints here; they’re tags for your generator)
pred featureEnabled[f: Feature] { f in SchemaOptions.enabled }

// ===================================================
//            WORKLOAD TAGS (Label Generation)
// ===================================================
abstract sig IsolationLevel {}
sig ReadCommitted, RepeatableRead, Serializable extends IsolationLevel {}

one sig Workload {
  // Integers in 0..100, sum to 100
  readRatio  : one Int,
  writeRatio : one Int,
  isolation  : one IsolationLevel
}

// Read/write mix must be a proper percentage split
fact WorkloadMixValid {
  Workload.readRatio >= 0 and Workload.writeRatio >= 0
  and Workload.readRatio + Workload.writeRatio = 100
}

// Example alignment suggestions (non-binding):
// - If read-heavy + DateIndex enabled, serializers may index Doc.date
// - If read-heavy + DenormalizeParty enabled, serializers may duplicate party keys in Doc tables
// - If write-heavy, prefer normalized shapes to minimize update anomalies, etc.

// ===================================================
//                 EXPLORATION PREDS
// ===================================================
pred someBaseline() {
  some Company
  some Department
  some Warehouse
  some Employee
  some Customer
  some Supplier
  some Item
  some SalesOrder
  some PurchaseOrder
  some SalesInvoice
  some PurchaseInvoice
  // Optional: at least one production order and stock entries
  some ProductionOrder
  some StockLedgerEntry
}

// Example world with a sensible workload and some toggled features.
// (Adjust scopes below for denser/larger instances.)
pred demoWithFeatures() {
  someBaseline()

  // Workload example: 70% reads / 30% writes
  Workload.readRatio  = 70
  Workload.writeRatio = 30
  Workload.isolation  = ReadCommitted

  // Turn on a few features (pure tags)
  FKIndex in SchemaOptions.enabled
  DateIndex in SchemaOptions.enabled
  // Choose either normalized assoc tables OR denormalization — can toggle both for ablation
  // NormalizeAssocTables in SchemaOptions.enabled
  // DenormalizeParty      in SchemaOptions.enabled
}

// -------------------- Commands ---------------------

run someBaseline for 7 but 5 Int

// Feature/demo instance:
run demoWithFeatures for 9 but 7 Int
