# Use an official Airflow image as base
FROM apache/airflow:2.7.0

# Set environment variables
ENV AIRFLOW_HOME=/opt/airflow
ENV AIRFLOW__CORE__LOAD_EXAMPLES=False
ENV AIRFLOW__CORE__EXECUTOR=SequentialExecutor
ENV AIRFLOW__WEBSERVER__WEB_SERVER_MASTER_TIMEOUT=300
ENV AIRFLOW__WEBSERVER__WORKER_CLASS=gevent
ENV AIRFLOW__WEBSERVER__WEB_SERVER_PORT=7860
ENV AWS_DEFAULT_REGION=eu-west-3

# Switch user
USER root

# COPY DAGS & PEM Key
COPY ./dags /opt/airflow/dags
COPY secrets/<YOUR_KEY_PAIR_NAME>.pem /opt/airflow/

# Change the UID of airflow user to 1000
RUN usermod -u 1000 airflow

# Ensure correct permissions for the .pem file
RUN chmod 400 /opt/airflow/<YOUR_KEY_PAIR_NAME>.pem \
   && chown airflow /opt/airflow/<YOUR_KEY_PAIR_NAME>.pem

# Switch back to airflow user
USER airflow

# Install any additional dependencies if needed
COPY requirements.txt requirements.txt 
RUN pip install -r requirements.txt

# Initialize the Airflow database (PostgreSQL in this case)
# IF YOU WANT TO HAVE THAT RUNNING IN HUGGINGFACE, YOU NEED TO HARD CODE THE VALUE HERE UNFORTUNATELY
# DON'T STAGE THAT IN A PRIVATE REPO BECAUSE THE ENV VARIABLE IS HARD CODED IN PLAIN TEXT
# IF YOU STAGE THAT IN HUGGING FACE SPACE, YOU DON'T HAVE A CHOICE THOUGH
# SO MAKE SURE YOUR SPACE IS PRIVATE
ENV AIRFLOW__DATABASE__SQL_ALCHEMY_CONN=$POSTGRES_URL

RUN airflow db init

# Create default admin user for Airflow (username: admin, password: admin)
RUN airflow users create \
   --username admin \
   --firstname Admin \
   --lastname User \
   --role Admin \
   --email admin@example.com \
   --password admin

# Expose the necessary ports (optional if Hugging Face already handles port exposure)
EXPOSE 7860

# Start Airflow webserver and scheduler within the same container
CMD ["bash", "-c", "airflow scheduler & airflow webserver"]
