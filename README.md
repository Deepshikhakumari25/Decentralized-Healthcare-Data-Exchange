# Decentralized Healthcare Data Exchange Platform

A blockchain-based healthcare data exchange platform that demonstrates secure patient consent, role-based access control, medical record integrity verification, and blockchain-based audit logging.

> **Note:** This project is an educational proof of concept. It uses only synthetic/dummy healthcare data and does not contain real patient medical information.

---

## 🎥 Demo Video

[Watch the Project Demo Video](https://drive.google.com/file/d/1gmuye8sduarSJ3TBu_gmQ5Q0LAvkAjPT/view?usp=sharing)

The demo video shows:

- Patient registration
- Doctor registration
- Hospital registration
- Medical record creation
- Doctor access request
- Patient consent
- Authorized record access
- Hash verification
- Tampering detection
- Access revocation
- Unauthorized access prevention
- Blockchain audit logging

---

## 📌 Project Overview

Traditional healthcare systems often store sensitive medical information in centralized databases. This project demonstrates how blockchain can be used as a trust and authorization layer for healthcare data exchange.

The actual medical document is not stored directly on the blockchain.

Instead, the blockchain is used for:

- Access permissions
- Patient consent
- Medical record metadata
- Document hashes
- Access-control rules
- Audit events

Synthetic medical data is used throughout the project.

---

## 🎯 Objectives

- Implement blockchain-based healthcare access control
- Define Patient, Doctor, Hospital and Admin roles
- Implement patient-controlled consent
- Store medical record metadata and hashes on-chain
- Verify document integrity using hashes
- Support access revocation
- Prevent unauthorized access
- Maintain an immutable blockchain audit trail

---

## 🏗️ System Architecture

```text
                    ┌──────────────────────┐
                    │       Patient        │
                    │   Consent / Revoke   │
                    └──────────┬───────────┘
                               │
                               ▼
                    ┌──────────────────────┐
                    │   Smart Contract     │
                    │ HealthcareDataExchange│
                    └──────────┬───────────┘
                               │
              ┌────────────────┼────────────────┐
              │                │                │
              ▼                ▼                ▼
         Doctor          Hospital          Admin
       Access Data      Create Record    Manage Roles

                         │
                         ▼
              ┌──────────────────────┐
              │   Off-Chain Storage  │
              │ Synthetic Documents  │
              └──────────────────────┘

                         │
                         ▼
                    Document Hash
                         │
                         ▼
                  Blockchain Record
