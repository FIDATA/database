-- FIDATA. Open-source system for analysis of financial and economic data
-- Copyright © 2013  Basil Peace

/*
   This file is part of FIDATA.

   FIDATA is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.
   
   FIDATA is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with FIDATA.  If not, see <http://www.gnu.org/licenses/>.
*/




CREATE FUNCTION get_portfolio_curr(portfolio_id bigint) RETURNS bigint
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		RETURN (SELECT curr FROM portfolios WHERE id = portfolio_id);
	END
$$;

CREATE TABLE portfolios (
	id bigserial PRIMARY KEY,
	name character varying(64) NOT NULL
		CHECK (char_length(name) > 0),
	curr bigint NOT NULL -- Functional currency in terms of IAS 21
		REFERENCES currencies (id)
			ON UPDATE CASCADE ON DELETE RESTRICT
	-- timeframe interval(YEAR TO DAY)
);
CREATE UNIQUE INDEX ON portfolios (upper(name));
CREATE INDEX ON portfolios (curr);

GRANT
	DELETE, TRUNCATE
	ON TABLE portfolios
	TO fidata
;


CREATE FUNCTION get_portfolio(portfolio_id bigint, OUT res portfolios)
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		SELECT * FROM portfolios WHERE id = portfolio_id INTO res;
	END
$$;

CREATE FUNCTION get_portfolio_by_name(portfolio_name character varying(64), OUT res portfolios)
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		SELECT * FROM portfolios WHERE upper(name) = upper(portfolio_name) INTO res;
	END
$$;




CREATE TYPE account_type AS ENUM (
	'Active',
	'Passive'
);

CREATE FUNCTION get_portfolio_account_type(account_id character varying(5)) RETURNS account_type
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		RETURN (SELECT account_type FROM portfolio_accounts WHERE id = account_id);
	END
$$;

CREATE FUNCTION get_portfolio_account_instrument_dimension(account_id character varying(5)) RETURNS bool
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		RETURN (SELECT instrument_dimension FROM portfolio_accounts WHERE id = account_id);
	END
$$;

CREATE TABLE portfolio_accounts (
	id character varying(5) PRIMARY KEY
		CHECK (char_length(id) > 0),
		-- TODO: CHECK on id
	name character varying(32) NOT NULL
		CHECK (char_length(name) > 0),
	account_type account_type NOT NULL,
	instrument_dimension bool NOT NULL
	-- description, comments ?
);
CREATE UNIQUE INDEX ON portfolio_accounts (upper(name));
-- CREATE INDEX ON portfolio_accounts (account_type);

REVOKE
	INSERT, UPDATE
	ON TABLE portfolio_accounts
	FROM fidata
	CASCADE
;

CREATE FUNCTION get_portfolio_account(account_id character varying(5), OUT res portfolio_accounts)
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		SELECT * FROM portfolio_accounts WHERE id = account_id INTO res;
	END
$$;

CREATE FUNCTION get_portfolio_account_by_name(account_name character varying(32), OUT res portfolio_accounts)
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		SELECT * FROM portfolio_accounts WHERE upper(name) = upper(account_name) INTO res;
	END
$$;


INSERT INTO portfolio_accounts (id, name, account_type, instrument_dimension) VALUES
	-- Assets
	('11', 'Assets',             'Active',  TRUE ), -- TODO: Long-term, Short-term, Cash etc.
	('12', 'Margin Account',     'Active',  TRUE ),
	
	-- Liabilities
	('21', 'Leveraged Assets',   'Passive', TRUE ), -- Assets Borrowed
	-- Use cash basis, no accrued liabilities
	
	-- Equity
	('31', 'Equity Capital',     'Passive', FALSE),
	
	-- Revenues
	('41', 'Revenues',           'Passive', FALSE),
	
	-- Expenses
	('51', 'Brokerage Expenses', 'Active',  FALSE)
;




CREATE FUNCTION get_portfolio_transaction_portfolio(transact_id bigint) RETURNS bigint
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		RETURN (SELECT portfolio FROM portfolio_transactions WHERE id = transact_id);
	END
$$;

CREATE FUNCTION get_portfolio_transaction_moment(transact_id bigint) RETURNS time_moment
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		RETURN (SELECT moment FROM portfolio_transactions WHERE id = transact_id);
	END
$$;

CREATE TABLE portfolio_transactions (
	portfolio bigint NOT NULL
		REFERENCES portfolios (id)
			ON UPDATE CASCADE ON DELETE CASCADE,
	moment time_moment NOT NULL,
	id bigserial PRIMARY KEY,
	
	debit_account character varying(5) NOT NULL
		REFERENCES portfolio_accounts (id)
			ON UPDATE CASCADE ON DELETE RESTRICT,
	debit_instrument bigint
		REFERENCES instruments (id)
			ON UPDATE CASCADE ON DELETE RESTRICT,
	debit_volume pieces_type,
	CHECK (
		get_portfolio_account_instrument_dimension(debit_account) AND (debit_instrument IS NOT NULL) AND (debit_volume <> 0)
		OR NOT get_portfolio_account_instrument_dimension(debit_account) AND (debit_instrument IS NULL) AND (debit_volume IS NULL)
	),
	-- TODO: prices; trigger for amount = price * volume
	
	credit_account character varying(5) NOT NULL
		REFERENCES portfolio_accounts (id)
			ON UPDATE CASCADE ON DELETE RESTRICT,
	credit_instrument bigint
		REFERENCES instruments (id)
			ON UPDATE CASCADE ON DELETE RESTRICT,
	credit_volume pieces_type,
	CHECK (
		get_portfolio_account_instrument_dimension(credit_account) AND (credit_instrument IS NOT NULL) AND (credit_volume <> 0)
		OR NOT get_portfolio_account_instrument_dimension(credit_account) AND (credit_instrument IS NULL) AND (credit_volume IS NULL)
	),
	
	amount amount_type NOT NULL, -- in portfolio's currency
	
	-- Checks against useless (probably erroneous) transactions
	CHECK ((debit_account <> credit_account) OR (debit_instrument IS DISTINCT FROM credit_instrument)),
	CHECK ((debit_volume IS NOT NULL) OR (credit_volume IS NOT NULL) OR (amount <> 0))
	
	-- TODO: Check of instruments == portfolio's currency
);
CREATE UNIQUE INDEX ON portfolio_transactions (portfolio, moment DESC, id DESC);
CREATE INDEX ON portfolio_transactions (debit_account);
CREATE INDEX ON portfolio_transactions (debit_instrument);
CREATE INDEX ON portfolio_transactions (credit_account);
CREATE INDEX ON portfolio_transactions (credit_instrument);

CREATE FUNCTION get_portfolio_transaction(transact_id bigint, OUT res portfolio_transactions)
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		SELECT * FROM portfolio_transactions WHERE id = transact_id INTO res;
	END
$$;

CREATE FUNCTION triggers.portfolio_transactions_protect_from_update() RETURNS trigger
	LANGUAGE plpgsql VOLATILE
AS $$
	BEGIN
		NEW.portfolio := OLD.portfolio;
		RETURN NEW;
	END
$$;
CREATE TRIGGER protect_from_update
	BEFORE UPDATE
	ON portfolio_transactions
	FOR EACH ROW
	EXECUTE PROCEDURE triggers.portfolio_transactions_protect_from_update()
;




-- Boundaries of validity of portfolios' stocks tables
CREATE TABLE portfolio_stock_boundaries (
	portfolio bigint PRIMARY KEY,
	moment time_moment NOT NULL,
	transact bigint NOT NULL,
	FOREIGN KEY (portfolio, moment, transact)
		REFERENCES portfolio_transactions (portfolio, moment, id)
			MATCH FULL
			ON UPDATE NO ACTION ON DELETE NO ACTION, -- triggers are fired
	actuality bool NOT NULL
);
CREATE UNIQUE INDEX ON portfolio_stock_boundaries (portfolio);
-- CREATE UNIQUE INDEX ON portfolio_stock_boundaries (portfolio, moment, transact);

CREATE FUNCTION triggers.portfolio_stock_boundaries_insert_only_absent() RETURNS trigger
	LANGUAGE plpgsql VOLATILE
AS $$
	BEGIN
		IF NOT EXISTS(SELECT * FROM portfolio_stock_boundaries WHERE portfolio = NEW.portfolio) THEN
			RETURN NEW;
		ELSE
			UPDATE portfolio_stock_boundaries SET
				id = NEW.id,
				moment = NEW.moment,
				actuality = NEW.actuality
			WHERE
				portfolio = NEW.portfolio;
			RETURN NULL;
		END IF;
	END
$$;
CREATE TRIGGER insert_only_absent
	BEFORE INSERT
	ON portfolio_stock_boundaries
	FOR EACH ROW
	EXECUTE PROCEDURE triggers.portfolio_stock_boundaries_insert_only_absent()
;

CREATE FUNCTION get_portfolio_stock_boundary(portfolio_id bigint, OUT res portfolio_stock_boundaries)
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		SELECT * FROM portfolio_stock_boundaries WHERE portfolio = portfolio_id INTO res;
	END
$$;

CREATE FUNCTION set_portfolio_stock_boundary(boundary portfolio_stock_boundaries) RETURNS VOID
	LANGUAGE plpgsql VOLATILE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		IF
			(boundary.moment IS NULL)
			OR (boundary.transact IS NULL)
		THEN
			DELETE FROM portfolio_stock_boundaries WHERE portfolio = boundary.portfolio_id;
		ELSE
			INSERT INTO portfolio_stock_boundaries VALUES (boundary.*);
		END IF;
	END
$$;




CREATE TABLE portfolio_account_stocks (
	id bigserial PRIMARY KEY,
	portfolio bigint NOT NULL,
	moment time_moment NOT NULL,
	transact bigint NOT NULL,
	FOREIGN KEY (portfolio, moment, transact)
		REFERENCES portfolio_transactions (portfolio, moment, id)
			MATCH FULL
			ON UPDATE NO ACTION ON DELETE NO ACTION, -- triggers are fired
	
	account character varying(5) NOT NULL
		REFERENCES portfolio_accounts (id)
			ON UPDATE CASCADE ON DELETE RESTRICT,
	
	amount amount_type NOT NULL
);
CREATE INDEX ON portfolio_account_stocks (portfolio, moment DESC, transact DESC);
CREATE UNIQUE INDEX ON portfolio_account_stocks (portfolio, account, moment DESC, transact DESC);
CREATE INDEX ON portfolio_account_stocks (account);

CREATE FUNCTION get_portfolio_account_stock(portfolio_id bigint, account_id character varying(5)) RETURNS amount_type
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		RETURN (
			SELECT
				COALESCE(amount, 0)
			FROM
				(
					SELECT
						portfolios.id AS portfolio,
						portfolio_accounts.id AS account
					FROM
						portfolios,
						portfolio_accounts
					WHERE
						(portfolios.id = portfolio_id)
						AND (portfolio_accounts.id = account_id)
				) AS t
				LEFT JOIN
					portfolio_account_stocks
				ON
					(t.portfolio = portfolio_account_stocks.portfolio)
					AND (t.account = portfolio_account_stocks.account)
			ORDER BY
				moment DESC,
				transact DESC
			LIMIT
				1
		);
	END
$$;


CREATE TABLE portfolio_account_instrument_stocks (
	id bigserial PRIMARY KEY,
	portfolio bigint NOT NULL,
	moment time_moment NOT NULL,
	transact bigint NOT NULL,
	FOREIGN KEY (portfolio, moment, transact)
		REFERENCES portfolio_transactions (portfolio, moment, id)
			MATCH FULL
			ON UPDATE NO ACTION ON DELETE NO ACTION, -- triggers are fired
	
	account character varying(5) NOT NULL
		REFERENCES portfolio_accounts (id)
			ON UPDATE CASCADE ON DELETE RESTRICT
		CHECK (get_portfolio_account_instrument_dimension(account)),
	instrument bigint NOT NULL
		REFERENCES instruments (id)
			ON UPDATE CASCADE ON DELETE RESTRICT,
	
	volume pieces_type NOT NULL
);
CREATE INDEX ON portfolio_account_instrument_stocks (portfolio, moment DESC, transact DESC);
CREATE UNIQUE INDEX ON portfolio_account_instrument_stocks (portfolio, account, instrument, moment DESC, transact DESC);
CREATE INDEX ON portfolio_account_instrument_stocks (account);
CREATE INDEX ON portfolio_account_instrument_stocks (instrument);

CREATE FUNCTION get_portfolio_account_instrument_stock(portfolio_id bigint, account_id character varying(5), instrument_id bigint) RETURNS amount_type
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		RETURN (
			SELECT
				COALESCE(volume, 0)
			FROM
				(
					SELECT
						portfolios.id AS portfolio,
						portfolio_accounts.id AS account,
						instruments.id AS instrument
					FROM
						portfolios,
						portfolio_accounts,
						instruments
					WHERE
						(portfolios.id = portfolio_id)
						AND (portfolio_accounts.id = account_id)
						AND (instruments.id = instrument_id)
				) AS t
				LEFT JOIN
					portfolio_account_stocks
				ON
					(t.portfolio = portfolio_account_stocks.portfolio)
					AND (t.account = portfolio_account_stocks.account)
					AND (t.instrument = portfolio_account_stocks.instrument)
			ORDER BY
				moment DESC,
				transact DESC
			LIMIT
				1
		);
	END
$$;



CREATE FUNCTION move_portfolio_stock_boundary_forward(transact_id bigint) RETURNS VOID
	LANGUAGE plpgsql VOLATILE RETURNS NULL ON NULL INPUT
AS $$
	DECLARE
		transact portfolio_transactions%ROWTYPE;
		boundary portfolio_stock_boundaries%ROWTYPE;
	BEGIN
		transact := get_portfolio_transaction(transact_id);
		
		IF transact.debit_account = transact.credit_account THEN
			INSERT INTO portfolio_account_stocks (portfolio, moment, transact, account, amount) VALUES (
				transact.portfolio,
				transact.moment,
				transact.id,
				transact.debit_account,
				get_portfolio_account_stock(transact.portfolio, transact.moment, transact.id, transact.debit_account)
			);
		ELSE
			INSERT INTO portfolio_account_stocks (portfolio, moment, transact, account, amount) VALUES (
				transact.portfolio,
				transact.moment,
				transact.id,
				transact.debit_account,
				get_portfolio_account_stock(transact.portfolio, transact.moment, transact.id, transact.debit_account) + transact.amount
			);
			INSERT INTO portfolio_account_stocks (portfolio, moment, transact, account, amount) VALUES (
				transact.portfolio,
				transact.moment,
				transact.id,
				transact.credit_account,
				get_portfolio_account_stock(transact.portfolio, transact.moment, transact.id, transact.credit_account) - transact.amount
			);
		END IF;
		
		IF transact.debit_instrument IS NOT NULL THEN
			INSERT INTO portfolio_account_instrument_stocks (portfolio, moment, transact, account, instrument, volume) VALUES (
				transact.portfolio,
				transact.moment,
				transact.id,
				transact.debit_account,
				transact.debit_instrument,
				get_portfolio_account_instrument_stocks(transact.portfolio, transact.moment, transact.id, transact.debit_account, transact.debit_instrument) + transact.debit_volume
			);
		END IF;
		IF transact.credit_instrument IS NOT NULL THEN
			INSERT INTO portfolio_account_instrument_stocks (portfolio, moment, transact, account, instrument, volume) VALUES (
				transact.portfolio,
				transact.moment,
				transact.id,
				transact.credit_account,
				transact.credit_instrument,
				get_portfolio_account_instrument_stocks(transact.portfolio, transact.moment, transact.id, transact.credit_account, transact.credit_instrument) - transact.credit_volume
			);
		END IF;
		
		boundary.portfolio := transact.portfolio;
		boundary.moment    := transact.moment;
		boundary.transact  := transact.id;
		boundary.actuality := TRUE;
		PERFORM set_portfolio_stock_boundary(boundary);
	END
$$;

CREATE FUNCTION move_portfolio_stock_boundary_backward(portfolio_id bigint, transact_moment time_moment, transact_id bigint, actuality bool) RETURNS VOID
	LANGUAGE plpgsql VOLATILE RETURNS NULL ON NULL INPUT
AS $$
	DECLARE
		boundary portfolio_stock_boundaries%ROWTYPE;
	BEGIN
		DELETE FROM portfolio_account_stocks WHERE
			(portfolio = portfolio_id)
			AND (
				(moment > transact_moment)
				OR (moment = transact_moment) AND (transact >= transact_id)
			)
		;
		DELETE FROM portfolio_account_instrument_stocks WHERE
			(portfolio = portfolio_id)
			AND (
				(moment > transact_moment)
				OR (moment = transact_moment) AND (transact >= transact_id)
			)
		;
		
		boundary.portfolio := portfolio_id;
		SELECT
			moment,
			id
		FROM
			portfolio_transactions
		WHERE
			(portfolio = portfolio_id)
			AND (
				(moment < transact_moment)
				OR (moment = transact_moment) AND (id < transact_id)
			)
		ORDER BY
			moment DESC,
			id DESC
		LIMIT
			1
		INTO
			boundary.moment,
			boundary.transact
		;
		boundary.actuality := actuality;
		PERFORM set_portfolio_stock_boundary(boundary);
	END
$$;


CREATE FUNCTION triggers.portfolio_transactions_move_stock_boundary() RETURNS trigger
	LANGUAGE plpgsql VOLATILE
AS $$
	DECLARE
		boundary portfolio_stock_boundaries%ROWTYPE;
	BEGIN
		boundary := get_portfolio_stock_boundary(NEW.portfolio);
		IF boundary IS NULL THEN
			PERFORM move_portfolio_stock_boundary_forward(NEW.id);
		ELSIF
			(NEW.moment > boundary.moment)
			OR (NEW.moment = boundary.moment) AND (NEW.id > boundary.moment)
		THEN
			IF boundary.actuality THEN
				PERFORM move_portfolio_stock_boundary_forward(NEW.id);
			END IF;
		ELSE
			PERFORM move_portfolio_stock_boundary_backward(NEW.portfolio, NEW.id, NEW.moment, FALSE);
		END IF;
		RETURN NULL;
	END
$$;
CREATE FUNCTION triggers.portfolio_transactions_unmove_stock_boundary() RETURNS trigger
	LANGUAGE plpgsql VOLATILE
AS $$
	DECLARE
		boundary portfolio_stock_boundaries%ROWTYPE;
	BEGIN
		boundary := get_portfolio_stock_boundary(OLD.portfolio);
		IF boundary.id = OLD.id THEN
			PERFORM move_portfolio_stock_boundary_backward(OLD.portfolio, OLD.id, OLD.moment, boundary.actuality);
		ELSE
			PERFORM move_portfolio_stock_boundary_backward(OLD.portfolio, OLD.id, OLD.moment, FALSE);
		END IF;
		RETURN OLD;
	END
$$;

CREATE TRIGGER move_stock_boundary_after_insert
	AFTER INSERT
	ON portfolio_transactions
	FOR EACH ROW
	EXECUTE PROCEDURE triggers.portfolio_transactions_move_stock_boundary()
;

CREATE TRIGGER unmove_stock_boundary_before_update
	BEFORE UPDATE
	ON portfolio_transactions
	FOR EACH ROW
	EXECUTE PROCEDURE triggers.portfolio_transactions_unmove_stock_boundary()
;

CREATE TRIGGER move_stock_boundary_after_update
	AFTER UPDATE
	ON portfolio_transactions
	FOR EACH ROW
	EXECUTE PROCEDURE triggers.portfolio_transactions_move_stock_boundary()
;

CREATE TRIGGER unmove_stock_boundary_before_delete
	BEFORE DELETE
	ON portfolio_transactions
	FOR EACH ROW
	EXECUTE PROCEDURE triggers.portfolio_transactions_unmove_stock_boundary()
;

CREATE FUNCTION triggers.portfolio_transactions_truncate_stock_boundaries_on_truncate() RETURNS trigger
	LANGUAGE plpgsql VOLATILE
AS $$
	DECLARE
	BEGIN
		TRUNCATE portfolio_accounts_stocks, portfolio_accounts_instrument_stocks RESTART IDENTITY;
		RETURN NULL;
	END
$$;
CREATE TRIGGER truncate_stock_boundaries_on_truncate
	AFTER TRUNCATE
	ON portfolio_transactions
	FOR EACH STATEMENT
	EXECUTE PROCEDURE triggers.portfolio_transactions_truncate_stock_boundaries_on_truncate()
;




CREATE FUNCTION get_portfolio_order_portfolio(portfolio_order_id bigint) RETURNS bigint
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		RETURN (SELECT portfolio FROM portfolio_orders WHERE id = portfolio_order_id);
	END
$$;

CREATE TABLE portfolio_orders (
	id bigserial PRIMARY KEY,
	portfolio bigint NOT NULL
		REFERENCES portfolios (id)
			ON UPDATE CASCADE ON DELETE CASCADE,
	instrument bigint NOT NULL
		REFERENCES instruments (id)
			ON UPDATE CASCADE ON DELETE RESTRICT,
	deal_direction deal_direction NOT NULL,
	volume pieces_type NOT NULL
		CHECK (volume > 0)
);
CREATE INDEX ON portfolio_orders (portfolio);
CREATE INDEX ON portfolio_orders (instrument);
-- CREATE INDEX ON portfolio_orders (deal_direction);




CREATE TABLE portfolio_order_actions (
	id bigserial PRIMARY KEY,
	portfolio_order bigint NOT NULL
		REFERENCES portfolio_orders (id)
			ON UPDATE CASCADE ON DELETE CASCADE,
	moment time_moment NOT NULL,
	action order_action NOT NULL,
	transact_id bigint
		REFERENCES portfolio_transactions (id)
			ON UPDATE CASCADE ON DELETE RESTRICT,
	CHECK (
		(action <> 'Execution') AND (transact_id IS NULL)
		OR
			(action = 'Execution')
			AND (get_portfolio_order_portfolio(portfolio_order) = get_portfolio_transaction_portfolio(transact_id))
			AND (moment = get_portfolio_transaction_moment(portfolio_order))
	)
);
CREATE INDEX ON portfolio_order_actions (portfolio_order, moment DESC);
-- CREATE INDEX ON portfolio_order_actions (action);
CREATE INDEX ON portfolio_order_actions (transact_id);
