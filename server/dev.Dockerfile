FROM python:3.12

WORKDIR /app

# Install Poetry
RUN curl -sSL https://install.python-poetry.org | python3 -
ENV PATH="/root/.local/bin:$PATH"

RUN mkdir -p /usr/local/share/ca-certificates /app/certs
COPY ./small-creek-wild-int.pem /app/certs/.
COPY ./small-creek-wild-int-key.pem /app/certs/.
COPY ./phoenix-smallcreek-CA.crt /usr/local/share/ca-certificates/.
RUN apt update && apt install -y --no-install-recommends ca-certificates
RUN chmod 644 /usr/local/share/ca-certificates/phoenix-smallcreek-CA.crt
RUN update-ca-certificates --fresh

# Copy requirements first for better caching
COPY server/requirements.txt .
RUN pip install -r requirements.txt
RUN pip install --upgrade pip certifi
RUN pip install --upgrade truststore pip-system-certs

# Install mem0 in editable mode using Poetry
WORKDIR /app/packages
COPY pyproject.toml .
COPY poetry.lock .
COPY README.md .
COPY mem0 ./mem0
RUN pip install -e .[graph]

# Return to app directory and copy server code
WORKDIR /app
COPY server .

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--reload", "--ssl-certfile", "/app/certs/small-creek-wild-int.pem", "--ssl-keyfile", "/app/certs/small-creek-wild-int-key.pem"]
