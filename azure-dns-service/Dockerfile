FROM python:3.10-alpine as build
WORKDIR /app
COPY pyproject.toml /app/
COPY poetry.toml /app/
RUN pip3 install poetry && poetry export --output requirements.txt

FROM python:3.10-alpine as final
WORKDIR /app
COPY azdns-update.py /app
COPY --from=build /app/requirements.txt /app/
RUN adduser -D someuser
USER someuser
RUN pip3 install -r requirements.txt --no-cache-dir
ENTRYPOINT [ "./azdns-update.py" ]
