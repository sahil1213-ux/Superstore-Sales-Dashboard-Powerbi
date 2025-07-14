import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import random

# Try multiple encodings until one works
encodings_to_try = ['latin1', 'cp1252', 'ISO-8859-1', 'utf-8']
df = None

for encoding in encodings_to_try:
    try:
        print(f"Trying to read file with {encoding} encoding...")
        df = pd.read_csv('SuperStoreOrders1.csv', na_values=['NULL'], encoding=encoding)
        print(f"Successfully read file with {encoding} encoding")
        break
    except UnicodeDecodeError:
        print(f"Failed to read with {encoding} encoding")

if df is None:
    raise ValueError("Could not read file with any of the attempted encodings")

# Clean 'sales' column
df['sales'] = df['sales'].replace(r'[\$,]', '', regex=True).astype(float)

# Check for NULL values
print(f"NULL values in order_date: {df['order_date'].isna().sum()}")
print(f"NULL values in ship_date: {df['ship_date'].isna().sum()}")

# Convert date columns to datetime
df['order_date'] = pd.to_datetime(df['order_date'], errors='coerce')
df['ship_date'] = pd.to_datetime(df['ship_date'], errors='coerce')

# Function to generate realistic dates based on patterns
def generate_dates(df):
    # Calculate typical shipping delays from existing data
    valid_orders = df[df['order_date'].notna() & df['ship_date'].notna()]
    if len(valid_orders) > 0:
        ship_delays = (valid_orders['ship_date'] - valid_orders['order_date']).dt.days
        min_delay = max(1, ship_delays.min())
        max_delay = min(14, ship_delays.max())
        median_delay = int(ship_delays.median())
    else:
        # Default values if no valid order pairs exist
        min_delay = 1
        max_delay = 7
        median_delay = 3
    
    # For rows with missing order_date but valid ship_date
    missing_order = df[df['order_date'].isna() & df['ship_date'].notna()]
    for idx in missing_order.index:
        ship_date = df.loc[idx, 'ship_date']
        rand_days = random.randint(min_delay, max_delay)
        df.loc[idx, 'order_date'] = ship_date - timedelta(days=rand_days)
        
    # For rows with missing ship_date but valid order_date
    missing_ship = df[df['order_date'].notna() & df['ship_date'].isna()]
    for idx in missing_ship.index:
        order_date = df.loc[idx, 'order_date']
        rand_days = random.randint(median_delay - 2, median_delay + 3)
        rand_days = max(1, rand_days)
        df.loc[idx, 'ship_date'] = order_date + timedelta(days=rand_days)
        
    # For rows with both dates missing
    missing_both = df[df['order_date'].isna() & df['ship_date'].isna()]
    for idx in missing_both.index:
        try:
            year = int(df.loc[idx, 'year']) if 'year' in df.columns and not pd.isna(df.loc[idx, 'year']) else 2011
        except:
            year = 2011
            
        month = random.randint(1, 12)
        day = random.randint(1, 28)
        order_date = datetime(year, month, day)
        df.loc[idx, 'order_date'] = order_date
        
        rand_days = random.randint(min_delay, max_delay)
        df.loc[idx, 'ship_date'] = order_date + timedelta(days=rand_days)
    
    return df

# Apply the function
df = generate_dates(df)

# Verify no NULLs remain
print(f"NULL values in order_date after fixing: {df['order_date'].isna().sum()}")
print(f"NULL values in ship_date after fixing: {df['ship_date'].isna().sum()}")

# Check for duplicates
dup_keys = df.duplicated(subset=['order_id', 'product_id'], keep=False)
print(f"Number of duplicate keys found: {dup_keys.sum()}")

# Deduplicate the dataframe
df_deduplicated = df.drop_duplicates(subset=['order_id', 'product_id'], keep='first')

# IMPORTANT: Don't reassign df_deduplicated to a boolean series!
# This line was incorrect: df_dedup = df_dedup.duplicated(...)
# Instead, store the check in a new variable:
remaining_dups = df_deduplicated.duplicated(subset=['order_id', 'product_id'], keep=False)
print(f"Number of duplicate keys after deduplication: {remaining_dups.sum()}")

# Save the FIXED deduplicated dataframe
df_deduplicated.to_csv('SuperStoreOrders_fixed.csv', index=False, encoding='latin1')
print(f"Original record count: {len(df)}, After deduplication: {len(df_deduplicated)}")