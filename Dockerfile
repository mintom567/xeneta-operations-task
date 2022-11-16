FROM python:3.7.8
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y python3-pip
COPY rates /app
WORKDIR /app
RUN pip install -U gunicorn && pip install -Ur requirements.txt
CMD ["gunicorn","-b :80", "wsgi"]
