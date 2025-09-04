-- Schema for Airbnb-like database (PostgreSQL flavor; portable CHECK-based enums)

CREATE EXTENSION IF NOT EXISTS pgcrypto; -- for gen_random_uuid() on PG

-- Drop in dependency order (safe re-run)
DROP TABLE IF EXISTS message CASCADE;
DROP TABLE IF EXISTS review CASCADE;
DROP TABLE IF EXISTS payment CASCADE;
DROP TABLE IF EXISTS booking CASCADE;
DROP TABLE IF EXISTS property CASCADE;
DROP TABLE IF EXISTS "user" CASCADE;

-- USER
CREATE TABLE "user" (
  user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  email VARCHAR(255) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  phone_number VARCHAR(30),
  role VARCHAR(10) NOT NULL CHECK (role IN ('guest','host','admin')),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_user_email ON "user"(email);

-- PROPERTY
CREATE TABLE property (
  property_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  host_id UUID NOT NULL REFERENCES "user"(user_id) ON DELETE RESTRICT,
  name VARCHAR(150) NOT NULL,
  description TEXT NOT NULL,
  location VARCHAR(150) NOT NULL,
  price_per_night DECIMAL(10,2) NOT NULL CHECK (price_per_night >= 0),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL
);
CREATE INDEX idx_property_host ON property(host_id);
CREATE INDEX idx_property_location ON property(location);
CREATE INDEX idx_property_price ON property(price_per_night);

-- BOOKING
CREATE TABLE booking (
  booking_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id UUID NOT NULL REFERENCES property(property_id) ON DELETE RESTRICT,
  user_id UUID NOT NULL REFERENCES "user"(user_id) ON DELETE RESTRICT,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  total_price DECIMAL(12,2) NOT NULL CHECK (total_price >= 0),
  status VARCHAR(10) NOT NULL CHECK (status IN ('pending','confirmed','canceled')),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CHECK (end_date > start_date)
);
CREATE INDEX idx_booking_property ON booking(property_id);
CREATE INDEX idx_booking_user ON booking(user_id);
CREATE INDEX idx_booking_dates ON booking(start_date, end_date);

-- PAYMENT
CREATE TABLE payment (
  payment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id UUID NOT NULL REFERENCES booking(booking_id) ON DELETE CASCADE,
  amount DECIMAL(12,2) NOT NULL CHECK (amount >= 0),
  payment_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  payment_method VARCHAR(20) NOT NULL CHECK (payment_method IN ('credit_card','paypal','stripe'))
);
CREATE INDEX idx_payment_booking ON payment(booking_id);

-- REVIEW
CREATE TABLE review (
  review_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id UUID NOT NULL REFERENCES property(property_id) ON DELETE RESTRICT,
  user_id UUID NOT NULL REFERENCES "user"(user_id) ON DELETE RESTRICT,
  rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_review_property ON review(property_id);
CREATE INDEX idx_review_user ON review(user_id);

-- MESSAGE
CREATE TABLE message (
  message_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id UUID NOT NULL REFERENCES "user"(user_id) ON DELETE RESTRICT,
  recipient_id UUID NOT NULL REFERENCES "user"(user_id) ON DELETE RESTRICT,
  message_body TEXT NOT NULL,
  sent_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_message_sender ON message(sender_id);
CREATE INDEX idx_message_recipient ON message(recipient_id);
CREATE INDEX idx_message_sent_at ON message(sent_at);