# Loan Portfolio & Credit Risk Analytics with a Natural-Language Chatbot

An end-to-end analytics project: raw loan data cleaned and validated in MySQL, visualised in a Power BI dashboard, and queried through a plain-English chatbot that returns the same exact numbers as the dashboard.

## What it does
- **SQL (MySQL):** 3 CSV datasets (customers, loans, repayments) loaded, cleaned, analysed and validated. 4,000 loans and 69,400 repayment records.
- **Power BI dashboard:** KPIs for total loan amount, defaulted and written-off loan rates and on-time repayment rate, with breakdowns by loan status, tenure, city, product and payment status.
- **Chatbot:** managers ask a question in plain English; the app turns it into SQL, runs it on the database and shows the exact result together with the SQL used.

## Accuracy check: chatbot vs dashboard
| Metric | Power BI dashboard | Chatbot |
|---|---|---|
| Total loan amount | 1,269,670,000 | 1,269,670,000 |
| Total loans | 4,000 | 4,000 |
| Average loan amount | 317,417.5 | 317,417.5 |
| Defaulted loan rate | 2.13% | 2.13% |
| Written-off loan rate | 6.80% | 6.80% |
| On-time repayment rate | 87.54% | 87.54% |

## Screenshots
![Dashboard](images/dashboard.png)
![Chatbot](images/chatbot.png)

## How it works
1. The question goes to a Streamlit app.
2. Common KPI questions run from pre-tested SQL. Other questions are converted to SQL by the Gemini API, using a prompt that holds the schema and the KPI definitions from the dashboard.
3. Safety checks allow only SELECT queries on three approved tables, and the database user is read-only.
4. The result and the SQL used are shown, so every answer can be verified.

## Tech stack
MySQL, Power BI (DAX), Python, Streamlit, Google Gemini API

## Data quality notes
- Standardised city names (merged "New Delhi" into "Delhi").
- Raw text columns converted to proper types in the `clean_*` tables.
- Repayment volume shows isolated spikes on a few dates (for example 20 Sep 2026). Due dates are otherwise spread evenly across the days of the month, so this is not a general month-end effect. Flagged for follow-up.

## Run locally
1. Load the data into MySQL (database `loan_db`, tables `clean_customers`, `clean_loans`, `clean_repayments`) and create a read-only database user.
2. `pip install -r requirements.txt`
3. Set environment variables: `GEMINI_API_KEY` (from Google AI Studio) and `DB_PASSWORD` (the read-only user's password).
4. `python -m streamlit run app.py`

## Limitations
- Open-ended questions depend on the Gemini API, which can be slow or rate-limited on the free tier.
- This project uses a sample loan dataset for demonstration purposes only.

## Author
Sameera Alex | [LinkedIn](https://www.linkedin.com/in/sameera-alex-analyst)
