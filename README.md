# CUCM SIP Normalization — STIR/SHAKEN Verstat Display Name Tagging

A Cisco Unified Communications Manager (CUCM) SIP Normalization Script that reads the STIR/SHAKEN `verstat` parameter from inbound INVITEs and appends a human-readable verification status to the caller display name — surfacing call attestation directly on Cisco IP phones with no changes to call routing.

## How It Works

On each inbound INVITE, the script:

1. Reads the `P-Asserted-Identity` header
2. Extracts the `verstat` parameter (supports both URI-param and header-param positions)
3. Maps it to a display name suffix:

| verstat | Suffix appended |
|---|---|
| `TN-Validation-Passed` | `(Verified)` |
| `TN-Validation-Failed` | `(Scam Likely)` |
| `No-TN-Validation` | `(Unverified)` |
| Missing / unknown | `(Unverified)` |

4. Appends the suffix to the display name in both `P-Asserted-Identity` and `From`
5. Handles both quoted display names (`"John Doe"`) and bare SIP URIs

The operation is idempotent — re-processing a header that already contains the suffix is a no-op.

## Installation

### 1. Upload the script to CUCM

1. Log in to **Cisco Unified CM Administration**
2. Navigate to **Device > Device Settings > SIP Normalization Scripts**
3. Click **Add New**
4. Enter a name (e.g., `stir-shaken-verstat`)
5. Paste the contents of `sip.lua` into the script editor
6. Click **Save**

### 2. Apply the script to a SIP Trunk

1. Navigate to **Device > Trunk** and open the SIP trunk that receives PSTN calls
2. Scroll to the **SIP Information** section
3. Set **Normalization Script** to the script name you created above
4. Click **Save**, then **Apply Config**

Apply only to trunks that receive inbound PSTN calls carrying STIR/SHAKEN headers.

## Result on Cisco IP Phones

Once applied, the incoming call screen on Cisco IP phones will display the verification suffix as part of the caller name — for example:

```
John Doe (Verified)
John Doe (Scam Likely)
+15005550006 (Unverified)
```

No additional CUCM configuration or phone firmware changes are required.

## Known Limitations

- **Attestation level variants** (`TN-Validation-Passed-A`, `-B`, `-C`) are treated as `(Unverified)`. Extend the `verstat_suffix` table if your carrier sends attestation-level suffixes.
- **Unquoted display names** (e.g., `John Doe <sip:...>` without surrounding quotes) will not receive the suffix.
- **`tel:` URIs** in PAI/From are not handled by the bare-URI injection path.
- Only the first `P-Asserted-Identity` header is processed if multiple are present.

## Requirements

- Cisco Unified Communications Manager (CUCM) — any version supporting SIP Normalization Scripts (Device > Device Settings > SIP Normalization Scripts)

