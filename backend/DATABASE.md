# Les tables créées pour mon application

## Label

```SQL
CREATE TABLE labels (
  label_id INTEGER PRIMARY KEY,
  label_name TEXT NOT NULL,
  label_color TEXT NOT NULL DEFAULT 'white'
);
```

## Bank

```SQL
CREATE TABLE banks (
  bank_id INTEGER PRIMARY KEY,
  bank_name TEXT NOT NULL,
  bank_account_type TEXT NOT NULL,
  bank_description TEXT
);
```

## Transaction Method

```SQL
CREATE TABLE transaction_methods (
  transmet_id INTEGER PRIMARY KEY,
  transmet_type TEXT NOT NULL,
  bank_id INTEGER,
  FOREIGN KEY (bank_id) REFERENCES banks(bank_id)
);
```

## Transaction

```SQL
CREATE TABLE transactions (
  transac_id INTEGER PRIMARY KEY,
  transac_name TEXT NOT NULL,
  transac_title TEXT,
  transac_date TEXT NOT NULL,
  transac_amount REAL NOT NULL,
  transac_description TEXT,
  transac_is_recurring INTEGER DEFAULT 0,
  transmet_id INTEGER NOT NULL,
  label_id INTEGER,
  FOREIGN KEY (transmet_id) REFERENCES transaction_methods(transmet_id),
  FOREIGN KEY (label_id) REFERENCES labels(label_id)
);
```

## Recurring transaction

```SQL
CREATE TABLE recurring_transactions (
  rectransac_id INTEGER PRIMARY KEY,
  rectransac_frequency TEXT NOT NULL,
  rectransac_day INTEGER NOT NULL,
  rectransac_start_date TEXT NOT NULL,
  rectransac_end_date TEXT,
  transac_id INTEGER NOT NULL,
  FOREIGN KEY (transac_id) REFERENCES transactions(transac_id)
);
```
