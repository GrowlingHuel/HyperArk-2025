## 2025-10-22

- Switched MindsDB integration from PostgreSQL wire protocol to HTTP API (port 47334)
- Implemented Req-based `MindsDB.Client` with robust response parsing
- Standardized HTTP config across environments (`mindsdb_host`, `mindsdb_http_port`, `mindsdb_user`, `mindsdb_password`)
- Removed supervision of MindsDB client (no longer a GenServer)
- Verified connectivity and agent querying via HTTP; seven character agents tested end-to-end


