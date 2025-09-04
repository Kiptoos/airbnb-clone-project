# Normalization to 3NF — Rationale & Steps

This document explains how the schema satisfies 1NF, 2NF, and 3NF, highlighting functional dependencies (FDs) and any denormalization choices.

## Functional Dependencies (selected)

- **User**: user_id → {first_name, last_name, email, password_hash, phone_number, role, created_at}; email → user_id (via UNIQUE)
- **Property**: property_id → {host_id, name, description, location, price_per_night, created_at, updated_at}
- **Booking**: booking_id → {property_id, user_id, start_date, end_date, total_price, status, created_at}
- **Payment**: payment_id → {booking_id, amount, payment_date, payment_method}
- **Review**: review_id → {property_id, user_id, rating, comment, created_at}
- **Message**: message_id → {sender_id, recipient_id, message_body, sent_at}

## 1NF (Atomicity)

- All attributes hold atomic values; no repeating groups or arrays in a single column.
- Example: `location` is a single VARCHAR field (if a structured address is needed later, split into street/city/country tables).

## 2NF (No Partial Dependency on Composite Keys)

- All tables use surrogate PKs (UUIDs), so there are no composite primary keys. Every non-key attribute depends on the whole PK.

## 3NF (No Transitive Dependencies)

- Non-key attributes do not depend on other non-key attributes.
- Example: `email` is unique in `User` but does not determine other attributes beyond user identity; we avoid embedding derived or look-up data (e.g., avoid storing `nights` if derivable from dates).

## Denormalization (None by default)

- No denormalization is applied. If later performance needs arise (e.g., caching `review_avg` on `Property`), document maintenance rules (triggers or background jobs) to keep data consistent.

## Outcome

- The design adheres to **3NF**, minimizing redundancy and update anomalies while remaining practical for real-world query patterns.