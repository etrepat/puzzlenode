# Puzzlenode #1 - International trade

You have been given two files. The first is an XML file containing the conversion
rates for exchanging one currency with another. The second is a CSV file containing
sales data by transaction for an international business. Your goal is to parse all
the transactions and return the grand total of all sales for a given item.

## Problem

What is the grand total of sales for item `DM1182` across all stores in USD
currency?

## Notes

After each conversion, the result should be rounded to 2 decimal places using
bankers rounding.

Some conversion rates are missing; you will need to derive them using the
information provided.

Since we are working with financial transactions, we need to avoid floating point
arithmetic errors.

## Example

Given a `RATES.xml` of:

    <?xml version="1.0"?>
    <rates>
      <rate>
        <from>AUD</from>
        <to>CAD</to>
        <conversion>1.0079</conversion>
      </rate>
      <rate>
        <from>CAD</from>
        <to>USD</to>
        <conversion>1.0090</conversion>
      </rate>
      <rate>
        <from>USD</from>
        <to>CAD</to>
        <conversion>0.9911</conversion>
      </rate>
    </rates>

and a `TRANS.csv` of:

    store,sku,amount
    Yonkers,DM1210,70.00 USD
    Yonkers,DM1182,19.68 AUD
    Nashua,DM1182,58.58 AUD
    Scranton,DM1210,68.76 USD
    Camden,DM1182,54.64 USD

You program should return `134.22` as the total of `DM1182` in USD. You can use
the sample files from this example to test your program before submitting an
answer for the real dataset for this problem.
