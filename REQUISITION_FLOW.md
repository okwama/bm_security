# Requisition Flow Documentation

## 1. Overview
This document describes the flow of a requisition from the database schema, through the backend API, to the Flutter service and UI layers. It also details the process for crew commanders assigning requests to vault officers, the completion logic for different service types, and the handling of location tracking.

---

## 2. Database Schema (`schema.prisma`)
- **Request**: Core model for a requisition, with fields for user, service type, locations, status, staff, branch, and relations to `CashCount`, `CrewLocation`, and `delivery_completion`.
- **delivery_completion**: Tracks delivery completion, including who completed it, photo, bank details, location, seal number, and status.
- **Other models**: `Staff`, `CashCount`, `branches`, etc., support the requisition process.

---

## 3. Backend API (`request.controller.js`)
- **Fetching**: Endpoints for pending/in-progress requests, with joins to related models.
- **Pickup**: `confirmPickup` endpoint updates status, creates `CashCount` if needed.
- **Complete Delivery**:
  - `confirmDelivery` (crew commander): Creates a `delivery_completion` record, updates request.
  - `completeVaultDelivery` (vault officer): Similar, but checks vault officer assignment.
- **Assignment**: `assignToVaultOfficer` assigns a vault officer to a request.

---

## 4. Flutter Service Layer (`lib/services/requisitions/`)
- **requisitions_service.dart**: Main entry, delegates to `RequestFetcher` and `RequestUpdater`.
  - Methods: `getPendingRequests`, `getInProgressRequests`, `completeRequisition`, `completeVaultDelivery`, `confirmPickup`, `assignToVaultOfficer`.
- **request_fetcher.dart**: Handles GET requests to fetch requisition data.
- **request_updater.dart**: Handles POST/PUT requests to update requisition state (pickup, complete, assign).

---

## 5. Flutter UI Layer (`lib/pages/requisitions/inProgress/inTransitDetail.dart`)
- Displays requisition details, allows photo capture, seal number entry, bank details (for vault), notes, and completion.
- Calls service methods to complete delivery, confirm pickup, assign vault officer, etc.

---

## 6. Crew Commander to Vault Officer Assignment & Completion

### Assignment
- The crew commander can assign a request to a vault officer using the `assignToVaultOfficer` method.
- This triggers a backend update, setting the vault officer as responsible for the request.

### Completion Logic
- **For Standard Service Types (e.g., not CDM/BSS):**
  - The crew commander completes the delivery by posting to `/requests/{id}/complete`.
  - The payload includes: `photoUrl`, `bankDetails` (if any), `latitude`, `longitude`, `notes`.
  - The backend creates a `delivery_completion` record and updates the request status.

- **For Vault Service Types (CDM/BSS):**
  - The crew commander assigns the request to a vault officer.
  - The vault officer completes the delivery by posting to `/requests/{id}/complete-vault-delivery`.
  - The payload includes: `photoUrl`, `bankDetails`, `latitude`, `longitude`, `notes`.
  - The backend checks the vault officer assignment, creates/updates the `delivery_completion` record, and updates the request status.

---

## 7. Location Tracking
- When a request is picked up, location tracking is started for that request.
- **On completion (by either crew commander or vault officer):**
  - The app calls `stopTrackingForRequest(requestId)` before posting the completion.
  - This ensures background location updates are stopped for the completed request.

---

## 8. What is Posted for Different Service Types
- **Standard (non-vault) services:**
  - Endpoint: `/requests/{id}/complete`
  - Payload: `{ status: 'completed', photoUrl, bankDetails, latitude, longitude, notes }`
- **Vault (CDM/BSS) services:**
  - Endpoint: `/requests/{id}/complete-vault-delivery`
  - Payload: `{ status: 'completed', photoUrl, bankDetails, location: { latitude, longitude }, notes }`
  - Requires vault officer assignment.

---

## 9. Summary Table

| Layer         | File/Model                                    | Key Functions/Endpoints                                 |
|---------------|-----------------------------------------------|---------------------------------------------------------|
| DB Schema     | `Request`, `CashCount`, `delivery_completion` | Data structure for requisition and completion            |
| Backend API   | `request.controller.js`                       | Fetch, pickup, complete, assign, vault delivery         |
| Flutter Svc   | `requisitions_service.dart`, `request_fetcher.dart`, `request_updater.dart` | Fetch, update, assign requisitions                      |
| Flutter UI    | `inTransitDetail.dart`                        | User interaction, calls service methods                 |

---

## 10. Flow Diagram (Textual)

1. **Request Created** → `Request` record in DB.
2. **Fetch Requests** → App calls `/requests/pending` or `/requests/in-progress` (via `RequestFetcher`).
3. **Pickup Confirmed** → App calls `/requests/{id}/confirm-pickup` (via `RequestUpdater`), backend updates status and creates `CashCount` if needed.
4. **Assign Vault Officer** (if needed) → App calls `/requests/{id}/assign-vault-officer`.
5. **Complete Delivery**:
   - **Crew Commander:** App calls `/requests/{id}/complete` (via `RequestUpdater`), backend creates `delivery_completion`.
   - **Vault Officer:** App calls `/requests/{id}/complete-vault-delivery`, backend creates/updates `delivery_completion` with vault officer info.
6. **UI**: All actions are triggered from the UI, which collects data and calls the service layer.

---

**For further details or diagrams, see the code or request a visual flowchart.** 