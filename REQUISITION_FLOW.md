# Requisition Flow Documentation

## 1. Overview
This document describes the flow of a requisition from the database schema, through the backend API, to the Flutter service and UI layers. It details the process for different service types (ATM Collection, Pick and Drop, BSS), crew commanders assigning requests to vault officers, the completion logic, and location tracking.

---

## 2. Service Types and Their Flows

### 2.1 ATM Collection Flow
1. **Pickup Phase**
   - Break existing seal
   - Confirm denominations
   - Apply new seal
   - Confirm pickup (updates status to `in_progress`)
   - Start location tracking
   - Track to delivery
   - Complete delivery (only requires location)
   - **Reassignment Option**: If team leader cannot complete, reassign to vault officer

### 2.2 Pick and Drop Flow
1. **Pickup Phase**
   - Confirm pickup (updates status to `in_progress`)
   - Start location tracking
   - Track to delivery
   - Complete delivery (only requires location)
   - **Reassignment Option**: If team leader cannot complete, reassign to vault officer

### 2.3 BSS (Bank to Bank) Flow
1. **Pickup Phase**
   - Capture banking slip photo
   - Enter cash denominations
   - Confirm pickup (updates status to `in_progress`)
   - Start location tracking
   - Track to delivery
   - Complete delivery (only requires location)
   - **Reassignment Option**: If team leader cannot complete, reassign to vault officer

2. **Bank to Vault**
   - Enter cash count denominations
   - Enter seal number
   - Confirm pickup (updates status to `in_progress`)
   - Start location tracking
   - Track to delivery
   - Complete delivery (only requires location)
   - **Reassignment Option**: If team leader cannot complete, reassign to vault officer

### 2.4 CDM (Cash Deposit Machine) Flow
1. **Pickup Phase**
   - Enter cash count denominations
   - Enter seal number
   - Confirm pickup (updates status to `in_progress`)
   - Start location tracking
   - Track to delivery
   - Complete delivery (only requires location)
   - **Reassignment Option**: If team leader cannot complete, reassign to vault officer

---

## 3. Database Schema (`schema.prisma`)
- **Request**: Core model for a requisition, with fields for user, service type, locations, status, staff, branch, and relations to `CashCount`, `CrewLocation`, and `delivery_completion`.
- **delivery_completion**: Tracks delivery completion, including who completed it, photo, bank details, location, seal number, and status.
- **seals**: Manages seal numbers and their status with the following states:
  - `assigned`: Initial state when seal is assigned to a request
  - `broken`: When seal is broken during ATM collection
  - `re_assigned`: When a new seal is assigned after breaking
- **cash_counts**: Tracks denomination details for cash handling
- **Other models**: `Staff`, `branches`, etc., support the requisition process.

---

## 4. Backend API (`request.controller.js`)
- **Fetching**: Endpoints for pending/in-progress requests, with joins to related models.
- **Pickup**: `confirmPickup` endpoint updates status, creates `CashCount` if needed.
- **Complete Delivery**:
  - `confirmDelivery` (crew commander): Creates a `delivery_completion` record, updates request.
  - `completeVaultDelivery` (vault officer): Similar, but checks vault officer assignment.
- **Assignment**: `assignToVaultOfficer` assigns a vault officer to a request.
- **Seal Management**: Endpoints for seal breaking and application.

---

## 5. Flutter Service Layer (`lib/services/requisitions/`)
- **requisitions_service.dart**: Main entry, delegates to `RequestFetcher` and `RequestUpdater`.
  - Methods: `getPendingRequests`, `getInProgressRequests`, `completeRequisition`, `completeVaultDelivery`, `confirmPickup`, `assignToVaultOfficer`.
- **request_fetcher.dart**: Handles GET requests to fetch requisition data.
- **request_updater.dart**: Handles POST/PUT requests to update requisition state (pickup, complete, assign).
- **cash_count_service.dart**: Handles cash denomination counting and verification.

---

## 6. Flutter UI Layer (`lib/pages/requisitions/`)
- **inProgress/inTransitDetail.dart**: Main delivery tracking interface
- **cashCount_page.dart**: Cash denomination counting interface
- **pending/pending_requisitions_page.dart**: Pending requests management
- **completed/completed_requisitions_page.dart**: Completed requests view

---

## 7. Service-Specific Completion Requirements

### 7.1 ATM Collection
- Seal breaking confirmation (during pickup)
- Cash denomination verification (during pickup)
- New seal application (during pickup)
- Location tracking throughout journey
- Simple delivery confirmation (only requires location)

### 7.2 Pick and Drop
- Simple pickup confirmation
- Location tracking throughout journey
- Simple delivery confirmation (only requires location)

### 7.3 BSS (Bank to Bank)
- Banking slip capture (during pickup)
- Cash denomination counting (during pickup)
- Location tracking throughout journey
- Simple delivery confirmation (only requires location)

### 7.4 BSS (Bank to Vault)
- Cash denomination counting (during pickup)
- Seal number entry (during pickup)
- Location tracking throughout journey
- Simple delivery confirmation (only requires location)

### 7.5 CDM (Cash Deposit Machine)
- Cash denomination counting (during pickup)
- Seal number entry (during pickup)
- Location tracking throughout journey
- Simple delivery confirmation (only requires location)

### 7.6 Request Reassignment
- **Trigger**: When team leader cannot complete the delivery
- **Process**:
  1. Team leader initiates reassignment
  2. Select vault officer from available list
  3. System updates request status to `reassigned`
  4. Vault officer receives notification
  5. Vault officer accepts the request
  6. Vault officer delivers the request as-is (no modifications to cash count or seals)
- **Status Changes**:
  - Request status changes to `reassigned`
  - Original team leader's assignment is marked as incomplete
  - New vault officer is assigned
  - Location tracking continues under new assignment
- **Vault Officer's Role**:
  - Only accepts and delivers the requisition
  - Does not modify cash counts or seals
  - Maintains the original cash count and seal numbers
  - Responsible for secure delivery only

---

## 8. Location Tracking
- When a request is picked up, location tracking is started for that request.
- **On completion (by either crew commander or vault officer):**
  - The app calls `stopTrackingForRequest(requestId)` before posting the completion.
  - This ensures background location updates are stopped for the completed request.

---

## 9. What is Posted for Different Service Types

### 9.1 ATM Collection
- Endpoint: `/requests/{id}/complete`
- Payload: 
  ```json
  {
    "status": "completed",
    "latitude": "number",
    "longitude": "number"
  }
  ```

### 9.2 Pick and Drop
- Endpoint: `/requests/{id}/complete`
- Payload:
  ```json
  {
    "status": "completed",
    "latitude": "number",
    "longitude": "number"
  }
  ```

### 9.3 BSS (Bank to Bank)
  - Endpoint: `/requests/{id}/complete`
- Payload:
  ```json
  {
    "status": "completed",
    "latitude": "number",
    "longitude": "number"
  }
  ```

### 9.4 BSS (Bank to Vault)
- Endpoint: `/requests/{id}/complete-vault-delivery`
- Payload:
  ```json
  {
    "status": "completed",
    "latitude": "number",
    "longitude": "number"
  }
  ```

### 9.5 CDM (Cash Deposit Machine)
- Endpoint: `/requests/{id}/complete-vault-delivery`
- Payload:
  ```json
  {
    "status": "completed",
    "latitude": "number",
    "longitude": "number"
  }
  ```

### 9.6 Request Reassignment
- Endpoint: `/requests/{id}/reassign`
- Payload:
  ```json
  {
    "status": "reassigned",
    "vaultOfficerId": "number",
    "vaultOfficerName": "string",
    "reassignmentReason": "string",
    "currentLocation": {
      "latitude": "number",
      "longitude": "number"
    }
  }
  ```

### 9.7 Vault Officer Delivery
  - Endpoint: `/requests/{id}/complete-vault-delivery`
- Payload:
  ```json
  {
    "status": "completed",
    "photoUrl": "string",
    "latitude": "number",
    "longitude": "number",
    "notes": "string",
    "deliveryConfirmation": "string"
  }
  ```
- Note: Vault officer only confirms delivery, does not modify cash counts or seals

---

## 10. Summary Table

| Service Type  | Key Requirements                    | Completion Endpoint           | Reassignment Endpoint        |
|---------------|-------------------------------------|-------------------------------|------------------------------|
| ATM Collection| Seal break, cash count, new seal    | `/requests/{id}/complete`     | `/requests/{id}/reassign`    |
| Pick and Drop | Simple pickup and delivery          | `/requests/{id}/complete`     | `/requests/{id}/reassign`    |
| BSS (Bank)    | Banking slip, bank details          | `/requests/{id}/complete`     | `/requests/{id}/reassign`    |
| BSS (Vault)   | Cash count, seal, vault officer     | `/requests/{id}/complete-vault-delivery` | `/requests/{id}/reassign` |
| CDM           | Cash count, seal, vault officer     | `/requests/{id}/complete-vault-delivery` | `/requests/{id}/reassign` |

---

## 11. Flow Diagram (Textual)

1. **Request Created** → `Request` record in DB with service type.
2. **Service-Specific Flow**:
   - **ATM**: 
     1. Break seal (during pickup)
     2. Count cash (during pickup)
     3. Apply new seal (during pickup)
     4. Confirm pickup
     5. Track to delivery
     6. Complete delivery
   - **Pick and Drop**: 
     1. Confirm pickup
     2. Track to delivery
     3. Complete delivery
   - **BSS (Bank)**: 
     1. Capture banking slip (during pickup)
     2. Count cash (during pickup)
     3. Confirm pickup
     4. Track to delivery
     5. Complete delivery
   - **BSS (Vault)**: 
     1. Count cash (during pickup)
     2. Apply seal (during pickup)
     3. Confirm pickup
     4. Track to delivery
     5. Complete delivery
   - **CDM**: 
     1. Count cash (during pickup)
     2. Apply seal (during pickup)
     3. Confirm pickup
     4. Track to delivery
     5. Complete delivery
3. **Reassignment Flow** (if team leader cannot complete):
   1. Team leader initiates reassignment
   2. Select vault officer
   3. Status changes to `reassigned`
   4. Vault officer accepts request
   5. Vault officer delivers as-is (no modifications)
   6. Continue with delivery only
4. **Location Tracking**: Started at pickup, stopped at delivery
5. **Completion**: Service-specific completion with required data
6. **UI**: All actions triggered from appropriate service-specific UI

---

**For further details or diagrams, see the code or request a visual flowchart.**

## 12. Navigation Flow

### 12.1 Pending Phase
```
pending.dart (List) → requisitionDetail.dart → process/[service_type].dart
```

Service-specific pages in `/pending/process/`:
- `pickandDrop.dart` - For Pick and Drop service
- `bssSlip.dart` - For BSS Bank to Bank service
- `cdmCollection.dart` - For CDM Collection service
- `atmCollection.dart` - For ATM Collection service
- `bssVault.dart` - For BSS Vault service

### 12.2 In Progress Phase
```
inProgress.dart (List) → [service_type].dart
```

Service-specific pages:
- `bssSlip.dart` - For BSS Bank to Bank service
- `inTransitDetail.dart` - For other services (Pick and Drop, CDM, ATM, BSS Vault)

### 12.3 Shared Components
- `cashCount_page.dart` - Used by services that require cash counting (BSS, CDM, ATM)

### 12.4 Service Type Routing
1. **Pick and Drop** (ServiceTypeId: 1)
   ```
   pending.dart → requisitionDetail.dart → process/pickandDrop.dart → inProgress.dart → inTransitDetail.dart
   ```

2. **BSS Bank to Bank** (ServiceTypeId: 2)
   ```
   pending.dart → requisitionDetail.dart → process/bssSlip.dart → inProgress.dart → bssSlip.dart
   ```

3. **CDM Collection** (ServiceTypeId: 3)
   ```
   pending.dart → requisitionDetail.dart → process/cdmCollection.dart → inProgress.dart → inTransitDetail.dart
   ```

4. **ATM Collection** (ServiceTypeId: 4)
   ```
   pending.dart → requisitionDetail.dart → process/atmCollection.dart → inProgress.dart → inTransitDetail.dart
   ```

5. **BSS Vault** (ServiceTypeId: 5)
   ```
   pending.dart → requisitionDetail.dart → process/bssVault.dart → inProgress.dart → inTransitDetail.dart
   ```

### 12.5 Common Flow Pattern
1. User starts in `pending.dart` (list of pending requests)
2. Selects a request → goes to `requisitionDetail.dart`
3. `requisitionDetail.dart` routes to appropriate service page in `/pending/process/`
4. After pickup, user goes to `inProgress.dart` (list of in-progress requests)
5. Selects a request → goes to appropriate service page in `/inProgress/`

---

**For further details or diagrams, see the code or request a visual flowchart.** 