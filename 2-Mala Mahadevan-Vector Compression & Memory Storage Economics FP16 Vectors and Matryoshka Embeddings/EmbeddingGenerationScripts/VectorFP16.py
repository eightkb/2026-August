# 02_generate_fp16_embeddings_key_tokens.py

import json
import urllib
import numpy as np
import pandas as pd
from sqlalchemy import create_engine, text
from sentence_transformers import SentenceTransformer

SERVER = "localhost"
DATABASE = "HackerNews"

SOURCE_TABLE = "dbo.HackerNewsStories"
TARGET_TABLE = "dbo.ArticlesEmbeddings_FP16"

SOURCE_BATCH_SIZE = 100000
EMBED_BATCH_SIZE = 64
MAX_ROWS_THIS_RUN = None

MODEL_NAME = "nomic-ai/nomic-embed-text-v1.5"

params = urllib.parse.quote_plus(
    "DRIVER={ODBC Driver 18 for SQL Server};"
    f"SERVER={SERVER};"
    f"DATABASE={DATABASE};"
    "Trusted_Connection=yes;"
    "TrustServerCertificate=yes;"
)

engine = create_engine(
    f"mssql+pyodbc:///?odbc_connect={params}",
    fast_executemany=True,
    pool_pre_ping=True
)

create_sql = f"""
IF OBJECT_ID('{TARGET_TABLE}', 'U') IS NULL
BEGIN
    CREATE TABLE {TARGET_TABLE}
    (
        hn_id BIGINT NOT NULL PRIMARY KEY,
        n_tokens INT NOT NULL,
        embedding VECTOR(768, FLOAT16) NOT NULL
    );
END;
"""

with engine.begin() as conn:
    conn.execute(text(create_sql))

print("FP16 target table ready.", flush=True)

print(f"Loading model: {MODEL_NAME}", flush=True)

model = SentenceTransformer(
    MODEL_NAME,
    trust_remote_code=True
)

embedding_dim = model.get_sentence_embedding_dimension()

print(f"Model dimension = {embedding_dim}", flush=True)

if embedding_dim != 768:
    raise ValueError(f"Expected 768 dimensions, got {embedding_dim}")


def vector_to_json(vec: np.ndarray) -> str:
    return json.dumps(vec.astype(float).tolist(), separators=(",", ":"))


def count_tokens(text_value) -> int:
    return max(1, len(str(text_value).split()))


def get_missing_source_batch() -> pd.DataFrame:
    sql = text(f"""
        WITH DedupedSource AS
        (
            SELECT
                s.hn_id,
                s.title,
                ROW_NUMBER() OVER
                (
                    PARTITION BY s.hn_id
                    ORDER BY s.hn_id
                ) AS rn
            FROM {SOURCE_TABLE} AS s
            WHERE s.hn_id IS NOT NULL
              AND s.title IS NOT NULL
              AND LTRIM(RTRIM(s.title)) <> ''
              AND NOT EXISTS
              (
                  SELECT 1
                  FROM {TARGET_TABLE} AS e
                  WHERE e.hn_id = s.hn_id
              )
        )
        SELECT TOP ({SOURCE_BATCH_SIZE})
            hn_id,
            title
        FROM DedupedSource
        WHERE rn = 1
        ORDER BY hn_id;
    """)

    return pd.read_sql(sql, engine)


def insert_rows(rows):
    if not rows:
        return

    sql = text(f"""
        INSERT INTO {TARGET_TABLE}
        (
            hn_id,
            n_tokens,
            embedding
        )
        SELECT
            :hn_id,
            :n_tokens,
            CAST(:embedding AS VECTOR(768, FLOAT16))
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM {TARGET_TABLE}
            WHERE hn_id = :hn_id
        );
    """)

    with engine.begin() as conn:
        conn.execute(sql, rows)


total_inserted = 0

while True:
    if MAX_ROWS_THIS_RUN is not None and total_inserted >= MAX_ROWS_THIS_RUN:
        break

    df = get_missing_source_batch()

    if df.empty:
        print("No missing rows found.", flush=True)
        break

    df = df.drop_duplicates(subset=["hn_id"])

    if MAX_ROWS_THIS_RUN is not None:
        remaining = MAX_ROWS_THIS_RUN - total_inserted
        df = df.head(remaining)

    titles = df["title"].astype(str).tolist()
    texts = [f"search_document: {title}" for title in titles]

    print(
        f"Generating FP16 embeddings for {len(texts)} rows. "
        f"hn_id range {int(df['hn_id'].min())} - {int(df['hn_id'].max())}",
        flush=True
    )

    embeddings_fp32 = model.encode(
        texts,
        batch_size=EMBED_BATCH_SIZE,
        convert_to_numpy=True,
        normalize_embeddings=True,
        show_progress_bar=True
    ).astype(np.float32)

    # Convert to FP16 before sending to SQL Server
    embeddings_fp16 = embeddings_fp32.astype(np.float16)

    rows = []
    df = df.reset_index(drop=True)

    for idx, row in df.iterrows():
        rows.append({
            "hn_id": int(row["hn_id"]),
            "n_tokens": count_tokens(row["title"]),
            "embedding": vector_to_json(embeddings_fp16[idx])
        })

    insert_rows(rows)

    total_inserted += len(rows)

    print(f"Inserted FP16 this run: {total_inserted:,}", flush=True)

print(f"Done. Inserted FP16 this run: {total_inserted:,}", flush=True)