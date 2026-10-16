import streamlit as st
import pandas as pd
from ask import get_sql, is_safe, run_query

st.set_page_config(page_title="Loan Portfolio Chatbot", page_icon="💬")
st.title("Loan Portfolio & Credit Risk Chatbot")
st.caption("Ask a question in plain English. Answers come straight from the loan database.")

if "messages" not in st.session_state:
    st.session_state.messages = []


def show_answer(sql, cols, rows):
    df = pd.DataFrame(rows, columns=cols)
    if df.shape == (1, 1):
        val = df.iloc[0, 0]
        try:
            num = float(val)
            text = f"{int(num):,}" if num == int(num) else f"{num:,.2f}"
        except Exception:
            text = str(val)
        st.metric(cols[0].replace("_", " ").title(), text)
    else:
        st.dataframe(df, use_container_width=True)
    with st.expander("SQL used"):
        st.code(sql, language="sql")


def render(msg):
    with st.chat_message(msg["role"]):
        if msg.get("sql"):
            show_answer(msg["sql"], msg["cols"], msg["rows"])
        else:
            st.write(msg["text"])


for m in st.session_state.messages:
    render(m)

q = st.chat_input("e.g. What is the total loan amount?")
if q:
    user_msg = {"role": "user", "text": q}
    st.session_state.messages.append(user_msg)
    render(user_msg)

    with st.chat_message("assistant"):
        with st.spinner("Thinking..."):
            sql = get_sql(q)
    reply = {"role": "assistant", "text": ""}
    if sql is None:
        reply["text"] = "Google's AI is busy right now. Please try again in a minute."
    elif sql == "CANNOT_ANSWER":
        reply["text"] = "I can't answer that from the loan data."
    elif not is_safe(sql):
        reply["text"] = "That query was not safe, so I did not run it."
    else:
        try:
            cols, rows = run_query(sql)
            reply.update({"sql": sql, "cols": cols, "rows": rows})
        except Exception as e:
            reply["text"] = f"Query error: {e}"
    st.session_state.messages.append(reply)
    render(reply)