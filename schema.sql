DROP TABLE IF EXISTS Pay_slips, Redeems, Buys, Registers, Cancels, Sessions, Offerings, Course_packages, Courses, Rooms, Owns, Credit_cards,
Customers, Administrators, Full_time_instructors, Part_time_instructors, Instructors, Course_areas, Managers, Full_time_Emp, Part_time_Emp, Employees CASCADE;

CREATE TABLE Employees ( -- 1 to 100
  eid SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  phone INTEGER NOT NULL,
  email TEXT NOT NULL,
  join_date Date NOT NULL,
  address TEXT NOT NULL,
  depart_date Date,
  CHECK (join_date <= depart_date)
);

CREATE TABLE Part_time_Emp ( -- 1 to 50
  eid INTEGER PRIMARY KEY,
  hourly_rate NUMERIC NOT NULL,
  FOREIGN KEY(eid) REFERENCES Employees
    ON DELETE CASCADE,
  CHECK (hourly_rate > 0)
);

CREATE TABLE Full_time_Emp ( -- 51 to 100
  eid INTEGER PRIMARY KEY,
  monthly_rate NUMERIC NOT NULL,
  FOREIGN KEY(eid) REFERENCES Employees
    ON DELETE CASCADE,
  CHECK (monthly_rate > 0)
);

CREATE TABLE Managers ( -- 71 to 80
  eid INTEGER PRIMARY KEY,
  FOREIGN KEY(eid) REFERENCES Full_time_Emp
    ON DELETE CASCADE
);

CREATE TABLE Course_areas (
  name TEXT PRIMARY KEY,
  eid INTEGER NOT NULL REFERENCES Managers
);

CREATE TABLE Instructors ( -- 1 to 70
  eid INTEGER PRIMARY KEY,
  FOREIGN KEY(eid) REFERENCES Employees
    ON DELETE CASCADE,
  name TEXT NOT NULL REFERENCES Course_areas
);

CREATE TABLE Part_time_instructors (
  eid INTEGER PRIMARY KEY REFERENCES Part_time_Emp
    REFERENCES Instructors
    ON DELETE CASCADE
);

CREATE TABLE Full_time_instructors (
  eid INTEGER PRIMARY KEY REFERENCES Full_time_Emp
    REFERENCES Instructors
    ON DELETE CASCADE
);

CREATE TABLE Administrators ( -- 81 TO 100
  eid INTEGER PRIMARY KEY,
  FOREIGN KEY(eid) REFERENCES Full_time_Emp
    ON DELETE CASCADE
);

CREATE TABLE Customers (
  cust_id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT,
  address TEXT,
  phone INTEGER
);

CREATE TABLE Credit_cards (
  number TEXT PRIMARY KEY,
  CVV INTEGER NOT NULL,
  expiry_date Date NOT NULL,
  cust_id INTEGER NOT NULL
    REFERENCES Customers
    ON UPDATE CASCADE
);

CREATE TABLE Owns (
  cust_id INTEGER REFERENCES Customers,
  number TEXT REFERENCES Credit_cards,
  from_date Date,
  PRIMARY KEY(cust_id, number)
);

CREATE TABLE Rooms (
  rid SERIAL PRIMARY KEY,
  location TEXT NOT NULL,
  seating_capacity INTEGER NOT NULL,
  CHECK (seating_capacity >= 0)
);

CREATE TABLE Courses (
  course_id SERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  duration NUMERIC NOT NULL,
  description TEXT,
  name TEXT NOT NULL REFERENCES Course_areas,
  CHECK (duration > 0)
);

CREATE TABLE Course_packages (
  package_id SERIAL PRIMARY KEY,
  sale_start_date Date,
  num_free_registrations INTEGER,
  name TEXT,
  sale_end_date Date,
  price NUMERIC,
  CHECK (sale_start_date <= sale_end_date), --KIV null pass check anot
  CHECK (price >= 0)
);

CREATE TABLE Offerings (
  launch_date Date,
  start_date Date,
  end_date Date,
  registration_deadline Date,
  target_number_registrations INTEGER CHECK (target_number_registrations >= 0),
  seating_capacity INTEGER CHECK (seating_capacity >= 0),
  fees NUMERIC CHECK (fees >= 0),
  eid INTEGER NOT NULL REFERENCES Administrators,
  course_id INTEGER REFERENCES Courses
    ON DELETE CASCADE,
  PRIMARY KEY(launch_date, course_id),
  CONSTRAINT a1 CHECK (start_date <= end_date AND launch_date <= start_date),
  CONSTRAINT b2 CHECK(registration_deadline >= launch_date AND registration_deadline <= end_date),
  CONSTRAINT c3 CHECK(target_number_registrations <= seating_capacity),
  CONSTRAINT d4 CHECK(registration_deadline = start_date - 10)
);

CREATE TABLE Sessions (
  sid INTEGER,
  date Date,
  end_time INTEGER,
  start_time INTEGER,
  launch_date Date,
  course_id INTEGER,
  rid INTEGER NOT NULL REFERENCES Rooms,
  eid INTEGER NOT NULL REFERENCES Instructors,
  PRIMARY KEY(sid, launch_date, course_id),
  FOREIGN KEY(launch_date, course_id) REFERENCES Offerings,
  CHECK (start_time < end_time),
  CHECK (launch_date <= date)
);

CREATE TABLE Cancels (
  cust_id INTEGER REFERENCES Customers,
  date Date, -- 7 days before session date, after registers date / redeems redeem_date.
  refund_amt NUMERIC CHECK (refund_amt >= 0), -- either refund_amt or package_credit must be null.
  package_credit INTEGER CHECK (package_credit in (0, 1)),
  sid INTEGER,
  launch_date Date,
  course_id INTEGER,
  FOREIGN KEY(sid, launch_date, course_id) REFERENCES Sessions,
  PRIMARY KEY(date, cust_id, sid, launch_date, course_id),
  CHECK (launch_date < date),
  CONSTRAINT null_check CHECK((refund_amt IS NOT null AND package_credit IS NULL) OR (refund_amt IS null AND package_credit IS NOT NULL))
);

CREATE TABLE Registers (
  date Date, -- after session launch_date, 10 days before offerings reg_deadline
  cust_id INTEGER,
  number TEXT,
  sid INTEGER,
  launch_date Date,
  course_id INTEGER,
  PRIMARY KEY(date, cust_id, number, sid, launch_date, course_id),
  FOREIGN KEY(cust_id, number) REFERENCES Owns,
  FOREIGN KEY(sid, launch_date, course_id) REFERENCES Sessions,
  CHECK (date >= launch_date)
);

CREATE TABLE Buys (
  buy_date Date, -- after course packages sale date, before sale end date
  num_remaining_redemptions INTEGER CHECK (num_remaining_redemptions >= 0), -- less than num_free_registrations Course_packages
  cust_id INTEGER, -- 16 to 30
  number TEXT,
  package_id INTEGER REFERENCES Course_packages,
  PRIMARY KEY(buy_date, cust_id, number, package_id),
  FOREIGN KEY(cust_id, number) REFERENCES Owns
);

CREATE TABLE Redeems (
  redeem_date Date, -- after buy_date
  buy_date Date, -- after course packages sale date
  cust_id INTEGER, 
  number TEXT,
  package_id INTEGER,
  sid INTEGER,
  launch_date Date,
  course_id INTEGER,
  FOREIGN KEY(buy_date, cust_id, number, package_id) REFERENCES Buys,
  FOREIGN KEY(sid, launch_date, course_id) REFERENCES Sessions,
  PRIMARY KEY(redeem_date, buy_date, cust_id, number, package_id, sid, launch_date, course_id),
  CHECK (redeem_date >= buy_date)
);

CREATE TABLE Pay_slips (
  payment_date Date,
  amount NUMERIC NOT NULL CHECK (amount >= 0),
  num_work_hours NUMERIC CHECK (num_work_hours >= 0),
  num_work_days NUMERIC CHECK (num_work_days >= 0),
  eid INTEGER REFERENCES Employees
    ON DELETE CASCADE,
  PRIMARY KEY(payment_date, eid),
  CONSTRAINT null_check CHECK((num_work_hours IS NOT null AND num_work_days IS NULL) OR (num_work_hours IS null AND num_work_days IS NOT NULL))
);












-- ####################################
-- ####          TRIGGERS          ####
-- ####################################

CREATE TRIGGER Owns_insert_trigger
BEFORE INSERT OR UPDATE ON Buys
FOR EACH ROW EXECUTE FUNCTION check_for_owns_insert();

CREATE OR REPLACE FUNCTION check_for_owns_insert() RETURNS TRIGGER AS $$
BEGIN

    IF (NEW.cust_id not in (SELECT cust_id FROM Customers)) THEN
        RAISE EXCEPTION 'Customer does not exist';
        RETURN NULL;
    END IF;

    IF (NEW.number not in (SELECT number FROM Credit_cards)) THEN
        RAISE EXCEPTION 'Card does not exist';
        RETURN NULL;
    END IF;

    IF (NEW.package_id not in (SELECT cp.package_id FROM Course_packages cp)) THEN
        RAISE EXCEPTION 'Package does not exist';
        RETURN NULL;
    END IF;

    IF (NEW.cust_id not in (SELECT cust_id FROM Owns)) THEN
        RAISE EXCEPTION 'Customer does not exist';
        RETURN NULL;
    END IF;

    IF (NEW.buy_date <> CURRENT_DATE) THEN
        RAISE EXCEPTION 'Incorrect buy date';
        RETURN NULL;
    END IF;

    IF (num_remaining_redemptions <= (SELECT num_free_registrations FROM Course_packages cp WHERE NEW.package_id = cp.package_id)) THEN
        RAISE EXCEPTION 'Number of remaining redemption must be <= initial';
        RETURN NULL;
    END IF;

    IF (NEW.buy_date <= (SELECT expiry_date FROM Credit_cards C WHERE NEW.number = C.number)) THEN
        RAISE EXCEPTION 'Credit card has expired';
        RETURN NULL;
    END IF;

    IF (NEW.buy_date > (SELECT sale_end_date FROM Course_packages cp WHERE NEW.package_id = cp.package_id)) THEN
        RAISE EXCEPTION 'Sale of package has ended';
        RETURN NULL;
    END IF;

    IF (NEW.buy_date < (SELECT sale_start_date FROM Course_packages cp WHERE NEW.package_id = cp.package_id)) THEN
        RAISE EXCEPTION 'Sale of package has yet to start';
        RETURN NULL;
    END IF;

    IF (SELECT EXISTS (SELECT 1 FROM Buys B WHERE (B.cust_id = NEW.cust_id) and (B.num_remaining_redemptions > 0))) THEN
        RAISE EXCEPTION 'Customer has an existing active package';
        RETURN NULL;
    END IF;

    IF (SELECT EXISTS (SELECT 1 FROM (Redeems natural join Sessions) as RS WHERE (RS.cust_id = NEW.cust_id) and (RS.date >= NEW.buy_date + 7))) THEN
        RAISE EXCEPTION 'Customer has an existing partially active package';
        RETURN NULL;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER Owns_delete_trigger
BEFORE DELETE ON Buys
FOR EACH ROW EXECUTE FUNCTION check_for_owns_delete();

CREATE OR REPLACE FUNCTION check_for_owns_delete() RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'Entries should not be deleted for archival purposes';
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER Offerings_insert_trigger
BEFORE INSERT OR UPDATE ON Offerings
FOR EACH ROW EXECUTE FUNCTION check_for_offerings_insert();

CREATE OR REPLACE FUNCTION check_for_offerings_insert() RETURNS TRIGGER AS $$
BEGIN

    IF (SELECT EXISTS (SELECT 1 FROM Offerings O WHERE (O.launch_date = NEW.launch_date) and (O.course_id = NEW.course_id))) THEN
        RAISE EXCEPTION 'Course offerings with same course id must have different launch date';
        RETURN NULL;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER Offerings_insert_trigger_deferrable
AFTER INSERT OR UPDATE ON Offerings
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION check_for_offerings_insert_deferrable();

CREATE OR REPLACE FUNCTION check_for_offerings_insert_deferrable() RETURNS TRIGGER AS $$
BEGIN

    IF (NEW.seating_capacity <> (SELECT COALESCE(SUM(SR.seating_capacity), 0) FROM (Sessions natural join Rooms) as SR WHERE SR.launch_date = NEW.launch_date and SR.course_id = NEW.course_id)) THEN
        RAISE EXCEPTION 'Seating capacity does not correspond to room capacity of sessions';
        RETURN NULL;
    END IF;

    IF (SELECT NOT EXISTS (SELECT 1 FROM Sessions S WHERE S.launch_date = NEW.launch_date and S.course_id = NEW.course_id)) THEN
        RAISE EXCEPTION 'Offerings should contain at least 1 session';
        RETURN NULL;
    END IF;

    IF (NEW.start_date <> (SELECT COALESCE(min(date), date'1000-01-01') FROM Sessions S WHERE S.launch_date = NEW.launch_date and S.course_id = NEW.course_id)) THEN
        RAISE EXCEPTION 'Start date does not correspond to earliest session, launch date: %, course id: %', NEW.launch_date, NEW.course_id;
        RETURN NULL;
    END IF;

    IF (NEW.end_date <> (SELECT COALESCE(max(date), date'1000-01-01') FROM Sessions S WHERE S.launch_date = NEW.launch_date and S.course_id = NEW.course_id)) THEN
        RAISE EXCEPTION 'End date does not correspond to latest session, launch date: %, course id: %', NEW.launch_date, NEW.course_id;
        RETURN NULL;
    END IF;

    RETURN NULL;

END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER Offerings_delete_trigger
BEFORE DELETE ON Offerings
FOR EACH ROW EXECUTE FUNCTION check_for_offerings_delete();

CREATE OR REPLACE FUNCTION check_for_offerings_delete() RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT NOT EXISTS (SELECT 1 FROM Sessions S WHERE S.launch_date = OLD.launch_date and S.course_id = OLD.course_id)) THEN
        RETURN OLD;
    END IF;
    RAISE EXCEPTION 'There is still 1 session under this course offering';
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION redeems_trigger_func() RETURNS TRIGGER AS $$ 
BEGIN
    IF (NEW.redeem_date > (SELECT date FROM Sessions s WHERE s.sid = NEW.sid)) THEN -- redeem after session
        raise exception 'Redeem date is after session date.';
        RETURN NULL; -- dont insert
        
    ELSEIF (NEW.buy_date < (SELECT sale_start_date FROM Course_packages cp where cp.package_id = NEW.package_id) 
    or NEW.buy_date > (SELECT sale_end_date FROM Course_packages cp where cp.package_id = NEW.package_id)) THEN -- i can delete this right
        raise exception 'Buy date is not during course package sales';
        RETURN NULL; -- dont insert
    ELSE
        INSERT INTO Registers (date, cust_id, number, sid, launch_date, course_id) 
        values (NEW.redeem_date, NEW.cust_id, NEW.number, NEW.sid, NEW.launch_date, NEW.course_id);
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER redeems_trigger
BEFORE INSERT ON Redeems
FOR EACH ROW EXECUTE FUNCTION redeems_trigger_func();