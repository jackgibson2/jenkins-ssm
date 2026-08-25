# pacs.008 shared contract

This directory holds one logical message — ISO 20022 **pacs.008.001.08**
(`FIToFICustomerCreditTransferV08`, single credit-transfer-transaction case)
— expressed three ways, so every language/protocol benchmark exchanges the
same information regardless of wire format:

- `xsd/` — the XML Schema
- `json/` — the JSON Schema equivalent
- `proto/` — the Protobuf equivalent
- `samples/` — one example payload per format, all representing the *same*
  transfer (same amounts, IDs, parties), for cross-format validation

## Scope note

The official ISO 20022 `pacs.008.001.08` XSD defines hundreds of optional
fields (multiple transactions per message, full postal address blocks,
ultimate debtor/creditor, regulatory reporting, tax, related remittance
documents, etc.). This scaffold implements a **representative subset**
sufficient to drive realistic benchmark payload sizes and a non-trivial
handler pipeline (validate → route by BIC → apply amount/currency rule →
respond), without carrying the full spec's surface area into every
language's benchmark code:

- `GroupHeader` — `MsgId`, `CreDtTm`, `NbOfTxs`, `SttlmInf/SttlmMtd`
- One `CreditTransferTransactionInformation` — `PmtId` (InstrId, EndToEndId,
  TxId, UETR), `IntrBkSttlmAmt` (+ currency), `IntrBkSttlmDt`, `ChrgBr`,
  `InstgAgt`/`InstdAgt`/`DbtrAgt`/`CdtrAgt` (BICFI only), `Dbtr`/`Cdtr`
  (name only), `DbtrAcct`/`CdtrAcct` (IBAN only), `RmtInf/Ustrd`

If a benchmark later needs the full spec surface (e.g. to test larger
payload sizes or nested-repetition parsing cost), extend all three schemas
and all sample files together so they stay in lockstep.
