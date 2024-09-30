FROM python:3

VOLUME /etc/letsencrypt
VOLUME /etc/nginx/conf.d
VOLUME /updater/config

WORKDIR /usr/src/app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY init-letsencrypt.py ./
COPY domain.conf.j2 ./

CMD [ "python", "./init-letsencrypt.py" ]
