# ERD Requirements — Airbnb-like Database

This document describes the entities, attributes, and relationships to be represented in the ER diagram. It mirrors the given specification and adds practical notes for cardinalities and constraints.

## Entities & Attributes

### User
- `user_id` **UUID PK, indexed**
- `first_name` VARCHAR NOT NULL
- `last_name` VARCHAR NOT NULL
- `email` VARCHAR NOT NULL **UNIQUE**
- `password_hash` VARCHAR NOT NULL
- `phone_number` VARCHAR NULL
- `role` ENUM('guest','host','admin') NOT NULL  — implemented as CHECK
- `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP

### Property
- `property_id` **UUID PK, indexed**
- `host_id` UUID NOT NULL **FK → User(user_id)**
- `name` VARCHAR NOT NULL
- `description` TEXT NOT NULL
- `location` VARCHAR NOT NULL
- `price_per_night` DECIMAL(10,2) NOT NULL
- `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
- `updated_at` TIMESTAMP NULL  (managed by trigger or app layer)

### Booking
- `booking_id` **UUID PK, indexed**
- `property_id` UUID NOT NULL **FK → Property(property_id)**
- `user_id` UUID NOT NULL **FK → User(user_id)**
- `start_date` DATE NOT NULL
- `end_date` DATE NOT NULL
- `total_price` DECIMAL(12,2) NOT NULL
- `status` ENUM('pending','confirmed','canceled') NOT NULL  — implemented as CHECK
- `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP

### Payment
- `payment_id` **UUID PK, indexed**
- `booking_id` UUID NOT NULL **FK → Booking(booking_id)**
- `amount` DECIMAL(12,2) NOT NULL
- `payment_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
- `payment_method` ENUM('credit_card','paypal','stripe') NOT NULL  — implemented as CHECK

### Review
- `review_id` **UUID PK, indexed**
- `property_id` UUID NOT NULL **FK → Property(property_id)**
- `user_id` UUID NOT NULL **FK → User(user_id)**
- `rating` INT NOT NULL CHECK (1..5)
- `comment` TEXT NOT NULL
- `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP

### Message
- `message_id` **UUID PK, indexed**
- `sender_id` UUID NOT NULL **FK → User(user_id)**
- `recipient_id` UUID NOT NULL **FK → User(user_id)**
- `message_body` TEXT NOT NULL
- `sent_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP

## Relationships (Cardinalities)

- **User (host) 1 — * Property** via `Property.host_id`.
- **User (guest) 1 — * Booking** via `Booking.user_id`.
- **Property 1 — * Booking** via `Booking.property_id`.
- **Booking 1 — 0..1 Payment** via `Payment.booking_id`.
- **Property 1 — * Review** and **User 1 — * Review**.
- **User ↔ User** via Message (self-referencing FKs): a User can send many messages and receive many messages.

> Optional business rule: if you allow only one review per completed stay, enforce a unique constraint like `UNIQUE (user_id, property_id, date_trunc('day', created_at))` or a surrogate link to a completed booking.

## Indexing Plan (beyond PKs)

- `user(email)`
- `property(host_id)`, `property(location)`, `property(price_per_night)`
- `booking(property_id)`, `booking(user_id)`, `booking(start_date, end_date)`
- `payment(booking_id)`
- `review(property_id)`, `review(user_id)`
- `message(sender_id)`, `message(recipient_id)`, `message(sent_at)`

## Notes & Assumptions

- **UUIDs** are preferred for portability and sharding readiness.
- **ENUMs** are implemented with CHECK constraints for portability across SQL engines.
- **Booking overlap** validation is typically enforced in the application layer; in PostgreSQL, an exclusion constraint could be used if needed.
- **Currency**: `DECIMAL(10,2)` for price fields; assume single currency for now.