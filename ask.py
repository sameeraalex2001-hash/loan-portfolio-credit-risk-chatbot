import os, re, time
import mysql.connector
from google import genai
from google.genai import types

client = genai.Client(api_key=os.environ["GEMINI_API_KEY"])

RULEBOOK = """
You are a SQL assistant for a Loan Portfolio & Credit Risk dashboard. The database is MySQL.
Convert the manager's plain-English question into ONE MySQL SELECT query.

TABLES (use only these three):
clean_customers(customer_id, age, employment_type, monthly_income, city, region, credit_score, kyc_status, acquisition_channel, onboarding_date)
clean_loans(loan_id, customer_id, product, disbursal_date, loan_amount, tenure_months, interest_rate, emi_amount, loan_status)
clean_repayments(repayment_id, loan_id, due_date, paid_date, emi_due, amount_paid, days_past_due, payment_status)

JOINS: clean_loans.customer_id = clean_customers.customer_id ; clean_repayments.loan_id = clean_loans.loan_id
NEVER use raw_* tables, loans, loan, customers or repayments. The loan table is ALWAYS clean_loans.

VALUES:
loan_status: 'Active', 'Closed', 'Defaulted', 'Written Off'
payment_status: 'On Time', 'Late', 'Missed', 'Partial'
product: 'Home Improvement', 'Vehicle Loan', 'Personal Loan', 'Education Loan', 'Business Loan'
region: 'North', 'South', 'East', 'West'
employment_type: 'Salaried', 'Self-Employed', 'Business Owner', 'Gig Worker'

DATES are TEXT in format YYYY-MM-DD. For year/month use YEAR(STR_TO_DATE(disbursal_date,'%Y-%m-%d')). paid_date may be empty for missed payments.

KPI DEFINITIONS (must match the dashboard exactly):
- Total Loans = COUNT(*) on clean_loans
- Total Loan Amount = SUM(loan_amount)
- Average Loan Amount = AVG(loan_amount)
- Defaulted Loan Rate = loans with loan_status='Defaulted' / all loans x 100
- Written-Off Loan Rate = loans with loan_status='Written Off' / all loans x 100
- On-Time Repayment Rate = repayments with payment_status='On Time' / all repayments x 100
Default means loan_status='Defaulted'. Do NOT use days_past_due unless asked about days past due or delinquency.

RULES:
1. Only SELECT. Never INSERT, UPDATE, DELETE, DROP, ALTER.
2. Never invent columns, tables or values. If the question cannot be answered from these tables, return exactly: CANNOT_ANSWER
3. Rates are rounded to 2 decimals.
4. Count loans with COUNT(DISTINCT loan_id) when joining repayments to loans.

OUTPUT FORMAT: Return ONLY the SQL statement. No explanation, no notes, no markdown, no semicolon.

EXAMPLES (always use the clean_ table names):
Q: What is the total loan amount?
SELECT SUM(loan_amount) AS total_loan_amount FROM clean_loans

Q: What is the defaulted loan rate?
SELECT ROUND(100*SUM(loan_status='Defaulted')/COUNT(*),2) AS defaulted_loan_rate_pct FROM clean_loans

Q: How many loans are written off?
SELECT COUNT(*) AS written_off_loans FROM clean_loans WHERE loan_status='Written Off'

Q: What is the on-time repayment rate?
SELECT ROUND(100*SUM(payment_status='On Time')/COUNT(*),2) AS on_time_repayment_rate_pct FROM clean_repayments

Q: Total loan amount by city
SELECT c.city, SUM(l.loan_amount) AS total_loan_amount FROM clean_loans l JOIN clean_customers c ON l.customer_id=c.customer_id GROUP BY c.city ORDER BY total_loan_amount DESC

Q: How many loans by tenure?
SELECT tenure_months, COUNT(*) AS total_loans FROM clean_loans GROUP BY tenure_months ORDER BY tenure_months

Q: What is the CEO's salary?
CANNOT_ANSWER
"""

MODELS = ["gemini-3.1-flash-lite", "gemini-3.5-flash", "gemini-flash-latest"]
ALLOWED_TABLES = {"clean_customers", "clean_loans", "clean_repayments"}
BLOCKED = re.compile(r"\b(insert|update|delete|drop|alter|create|truncate|grant)\b", re.I)

# Questions answered instantly from tested SQL (no Google needed)
KNOWN = {
    "what is the total loan amount":
        "SELECT SUM(loan_amount) AS total_loan_amount FROM clean_loans",
    "how many loans are there":
        "SELECT COUNT(*) AS total_loans FROM clean_loans",
    "what is the average loan amount":
        "SELECT AVG(loan_amount) AS average_loan_amount FROM clean_loans",
    "what is the defaulted loan rate":
        "SELECT ROUND(100*SUM(loan_status='Defaulted')/COUNT(*),2) AS defaulted_loan_rate_pct FROM clean_loans",
    "what is the written off loan rate":
        "SELECT ROUND(100*SUM(loan_status='Written Off')/COUNT(*),2) AS written_off_loan_rate_pct FROM clean_loans",
    "what is the on time repayment rate":
        "SELECT ROUND(100*SUM(payment_status='On Time')/COUNT(*),2) AS on_time_repayment_rate_pct FROM clean_repayments",
    "how many loans are written off":
        "SELECT COUNT(*) AS written_off_loans FROM clean_loans WHERE loan_status='Written Off'",
    "how many loans are defaulted":
        "SELECT COUNT(*) AS defaulted_loans FROM clean_loans WHERE loan_status='Defaulted'",
    "total loan amount by city":
        "SELECT c.city, SUM(l.loan_amount) AS total_loan_amount FROM clean_loans l JOIN clean_customers c ON l.customer_id=c.customer_id GROUP BY c.city ORDER BY total_loan_amount DESC",
    "how many loans by tenure":
        "SELECT tenure_months, COUNT(*) AS total_loans FROM clean_loans GROUP BY tenure_months ORDER BY tenure_months",
    "total loan amount by loan status":
        "SELECT loan_status, SUM(loan_amount) AS total_loan_amount FROM clean_loans GROUP BY loan_status ORDER BY total_loan_amount DESC",
    "how many loans by loan status":
        "SELECT loan_status, COUNT(*) AS total_loans FROM clean_loans GROUP BY loan_status ORDER BY total_loans DESC",
    "how many repayments by payment status":
        "SELECT payment_status, COUNT(*) AS repayment_count FROM clean_repayments GROUP BY payment_status ORDER BY repayment_count DESC",
}
CACHE = {}


def clean_sql(text):
    text = text.replace("```sql", "").replace("```", "").strip()
    if "CANNOT_ANSWER" in text:
        return "CANNOT_ANSWER"
    text = text.split(";")[0]
    text = re.split(r"\n\s*\n", text)[0].strip()
    return text


def normalize(q):
    return " ".join(re.sub(r"[^a-z0-9 ]", " ", q.lower()).split())


def get_sql(question):
    key = normalize(question)
    if key in KNOWN:
        return KNOWN[key]
    if key in CACHE:
        return CACHE[key]
    last_error = None
    config = types.GenerateContentConfig(system_instruction=RULEBOOK, temperature=0)
    for model in MODELS:
        for attempt in range(2):
            try:
                resp = client.models.generate_content(
                    model=model, contents=f"Question: {question}\nSQL:", config=config
                )
                sql = clean_sql(resp.text)
                CACHE[key] = sql
                return sql
            except Exception as e:
                last_error = e
                msg = str(e)
                print(f"  [{model}] attempt {attempt+1} failed:", msg[:80])
                if "429" in msg or "404" in msg:
                    break
                time.sleep(2)
    print("Google's AI is busy right now. Please try again in a minute.")
    print("Last error:", str(last_error)[:200])
    return None


def is_safe(sql):
    if not sql.lower().startswith("select") or BLOCKED.search(sql):
        return False
    tables = set(t.lower() for t in re.findall(r"\b(?:from|join)\s+`?(\w+)`?", sql, re.I))
    return bool(tables) and tables <= ALLOWED_TABLES


def run_query(sql):
    conn = mysql.connector.connect(
        host="localhost", user="chatbot_ro",
                    password= os.environ.get("DB_PASSWORD", ""), database="loan_db",
    )
    cur = conn.cursor()
    cur.execute(sql)
    cols = [c[0] for c in cur.description]
    rows = cur.fetchall()
    conn.close()
    return cols, rows


if __name__ == "__main__":
    print("Rulebook loaded:", len(RULEBOOK), "characters")
    while True:
        q = input("\nAsk a question (or type exit): ").strip()
        if q.lower() == "exit":
            break
        sql = get_sql(q)
        if sql is None:
            continue
        if sql == "CANNOT_ANSWER":
            print("I can't answer that from the loan data.")
            continue
        if not is_safe(sql):
            print("Blocked: that query was not safe or used a table I'm not allowed to use.\n", sql)
            continue
        print("\nSQL used:\n", sql)
        try:
            cols, rows = run_query(sql)
        except Exception as e:
            print("Query error:", e)
            continue
        print("\nResult:", cols)
        for r in rows[:20]:
            print(r)