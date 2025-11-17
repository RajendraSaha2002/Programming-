-- Accounts table
CREATE TABLE accounts (
    acc_no SERIAL PRIMARY KEY,
    holder_name VARCHAR(50),
    balance DECIMAL(10,2)
);

-- Transactions
CREATE TABLE bank_transactions (
    trans_id SERIAL PRIMARY KEY,
    acc_no INT REFERENCES accounts(acc_no),
    trans_type VARCHAR(10), -- deposit/withdraw
    amount DECIMAL(10,2),
    trans_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create accounts
INSERT INTO accounts (holder_name, balance) VALUES
('Rajendra Saha', 5000),
('Suchismita Saha', 3000);

-- Deposit 1000
UPDATE accounts SET balance = balance + 1000 WHERE acc_no = 1;

INSERT INTO bank_transactions (acc_no, trans_type, amount)
VALUES (1, 'deposit', 1000);

-- Withdraw 500
UPDATE accounts SET balance = balance - 500 WHERE acc_no = 1;

INSERT INTO bank_transactions (acc_no, trans_type, amount)
VALUES (1, 'withdraw', 500);

-- Show all transactions
SELECT * FROM bank_transactions ORDER BY trans_date DESC;
