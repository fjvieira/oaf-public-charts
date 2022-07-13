# WARNING: LOTS of duplication here, needs cleanup!

# TODO: move passwords to secrets...

{{- define "kc_dburl" -}}
postgis://{{ .Values.postgresql.postgresqlUsername }}:{{ urlquery .Values.postgresql.postgresqlPassword }}@{{ .Release.Name }}-postgresql:5432/{{ .Values.postgresql.kobocatDatabase }}
{{- end -}}

{{- define "kpi_dburl" -}}
postgis://{{ .Values.postgresql.postgresqlUsername }}:{{ urlquery .Values.postgresql.postgresqlPassword }}@{{ .Release.Name }}-postgresql:5432/{{ .Values.postgresql.kpiDatabase }}
{{- end -}}

{{- define "internal_domain" -}}
kobo.local
{{- end -}}

{{- define "boolean2str" -}}
{{ . | ternary "True" "False" }}
{{- end -}}

# TODO... define external port only if non-standard 80/443
{{- define "external_port" -}}
{{- end -}}

{{- define "kpi_url" -}}
{{ .Values.general.externalScheme }}://{{ .Values.kpi.subdomain }}.{{ .Values.general.externalDomain }}{{ include "external_port" . }}
{{- end -}}

{{- define "kobocat_url" -}}
{{ .Values.general.externalScheme }}://{{ .Values.kobocat.subdomain }}.{{ .Values.general.externalDomain }}{{ include "external_port" . }}
{{- end -}}

{{- define "enketo_url" -}}
{{ .Values.general.externalScheme }}://{{ .Values.enketo.subdomain }}.{{ .Values.general.externalDomain }}{{ include "external_port" . }}
{{- end -}}

{{- define "redis_url_session" -}}
redis://:{{ urlquery .Values.global.redis.password }}@{{ .Release.Name }}-rediscache-master:6379/2
{{- end -}}

{{- define "redis_url_lock" -}}
redis://:{{ urlquery .Values.global.redis.password }}@{{ .Release.Name }}-rediscache-master:6379/3
{{- end -}}

{{- define "redis_url_kobobroker" -}}
redis://:{{ urlquery .Values.global.redis.password }}@{{ .Release.Name }}-redismain-master:6379/2
{{- end -}}

{{- define "redis_url_kpibroker" -}}
redis://:{{ urlquery .Values.global.redis.password }}@{{ .Release.Name }}-redismain-master:6379/1
{{- end -}}

{{- define "env_general" -}}
# Choose between http or https
- name: PUBLIC_REQUEST_SCHEME
  value: {{ .Values.general.externalScheme | quote }}
# The publicly-accessible domain where your KoBo Toolbox instance will be reached (e.g. example.com).
- name: PUBLIC_DOMAIN_NAME
  value: {{ .Values.general.externalDomain }}
- name: SESSION_COOKIE_DOMAIN
  value: .{{ .Values.general.externalDomain }}
# The private domain used in docker network. Useful for communication between containers without passing through
# a load balancer. No need to be resolved by a public DNS.
- name: INTERNAL_DOMAIN_NAME
  value: {{ include "internal_domain" . }}
# The publicly-accessible subdomain for the KoBoForm form building and management interface (e.g. koboform).
- name: KOBOFORM_PUBLIC_SUBDOMAIN
  value: {{ .Values.kpi.subdomain }}
# The publicly-accessible subdomain for the KoBoCAT data collection and project management interface (e.g.kobocat).
- name: KOBOCAT_PUBLIC_SUBDOMAIN
  value: {{ .Values.kobocat.subdomain }}
# The publicly-accessible subdomain for the Enketo Express web forms (e.g. enketo).
- name: ENKETO_EXPRESS_PUBLIC_SUBDOMAIN
  value: {{ .Values.enketo.subdomain }}

# For now, you must set ENKETO_API_TOKEN, used by KPI and KoBoCAT, to the same
# value as ENKETO_API_KEY. Eventually, KPI and KoBoCAT will also read
# ENKETO_API_KEY and the duplication will no longer be necessary.
#  For a description of this setting, see "api key" here:
#  https://github.com/kobotoolbox/enketo-express/tree/master/config#linked-form-and-data-server.
- name: ENKETO_API_KEY
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-secrets
      key: ENKETO_API_KEY
- name: ENKETO_API_TOKEN
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-secrets
      key: ENKETO_API_KEY

# Canonically a 50-character random string. For Django 1.8.13, see https://docs.djangoproject.com/en/1.8/ref/settings/#secret-key and https://github.com/django/django/blob/4022b2c306e88a4ab7f80507e736ce7ac7d01186/django/core/management/commands/startproject.py#L29-L31.
# To generate a secret key in the same way as `django-admin startproject` you can run:
# docker-compose run --rm kpi python -c 'from django.utils.crypto import get_random_string; print(get_random_string(50, "abcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*(-_=+)"))'
- name: DJANGO_SECRET_KEY
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-secrets
      key: DJANGO_SECRET_KEY

- name: ENKETO_ENCRYPTION_KEY
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-secrets
      key: ENKETO_ENCRYPTION_KEY

# The initial superuser's username.
- name: KOBO_SUPERUSER_USERNAME
  value: {{ .Values.general.superUser.username | quote }}
# The initial superuser's password.
- name: KOBO_SUPERUSER_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-secrets
      key: KOBO_SUPERUSER_PASSWORD

# The e-mail address where your users can contact you.
- name: KOBO_SUPPORT_EMAIL
  value: {{ .Values.general.supportEmail | quote }}

- name: BACKUPS_DIR
  value: /srv/backups

- name: DJANGO_ALLOWED_HOSTS
  value: ".{{ .Values.general.externalDomain }} .{{ include "internal_domain" . }} localhost"
{{- end -}}

{{- define "env_mongo" -}}
- name: KOBO_MONGO_PORT
  value: '27017'
- name: KOBO_MONGO_HOST
  value: {{ .Release.Name }}-mongodb
- name: MONGO_INITDB_ROOT_USERNAME
  value: root
- name: MONGO_INITDB_ROOT_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-secrets
      key: MONGO_INITDB_ROOT_PASSWORD
- name: MONGO_INITDB_DATABASE
  value: {{ .Values.mongodb.auth.database | quote }}
- name: KOBO_MONGO_USERNAME
  value: {{ .Values.mongodb.auth.username | quote }}
- name: KOBO_MONGO_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-secrets
      key: KOBO_MONGO_PASSWORD

# No idea why these need to be duplicated...
- name: KOBOCAT_MONGO_HOST
  value: {{ .Release.Name }}-mongodb
- name: KOBOCAT_MONGO_PORT
  value: '27017'
- name: KOBOCAT_MONGO_NAME
  value: {{ .Values.mongodb.auth.database | quote }}
- name: KOBOCAT_MONGO_USER
  value: {{ .Values.mongodb.auth.username | quote }}
- name: KOBOCAT_MONGO_PASS
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-secrets
      key: KOBOCAT_MONGO_PASS

- name: KPI_MONGO_HOST
  value: {{ .Release.Name }}-mongodb
- name: KPI_MONGO_PORT
  value: '27017'
- name: KPI_MONGO_NAME
  value: {{ .Values.mongodb.auth.database | quote }}
- name: KPI_MONGO_USER
  value: {{ .Values.mongodb.auth.username | quote }}
- name: KPI_MONGO_PASS
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-secrets
      key: KPI_MONGO_PASS
{{- end -}}

{{- define "env_postgres" -}}
# These `KOBO_POSTGRES_` settings only affect the postgres container itself and the
# `wait_for_postgres.bash` init script that runs within the kpi and kobocat
# containers. To control Django database connections, please see the
# `DATABASE_URL` environment variable.
- name: POSTGRES_PORT
  value: '5432'
- name: POSTGRES_HOST
  value: {{ .Release.Name }}-postgresql
- name: POSTGRES_USER
  value: {{ .Values.postgresql.postgresqlUsername | quote }}
- name: POSTGRES_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-secrets
      key: POSTGRES_PASSWORD
- name: KC_POSTGRES_DB
  value: {{ .Values.postgresql.kobocatDatabase | quote }}
- name: KPI_POSTGRES_DB
  value: {{ .Values.postgresql.kpiDatabase | quote }}

# Postgres database used by kpi and kobocat Django apps
- name: KC_DATABASE_URL
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-secrets
      key: KC_DATABASE_URL
- name: KPI_DATABASE_URL
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-secrets
      key: KPI_DATABASE_URL
{{- end -}}

{{- define "env_redis" -}}
- name: REDIS_SESSION_URL
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-secrets
      key: REDIS_SESSION_URL
- name: REDIS_LOCK_URL
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-secrets
      key: REDIS_LOCK_URL
- name: REDIS_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-secrets
      key: REDIS_PASSWORD
{{- end -}}

{{- define "env_enketo" -}}
- name: ENKETO_REDIS_MAIN_HOST
  value: {{ .Release.Name }}-redismain-master
- name: ENKETO_REDIS_CACHE_HOST
  value: {{ .Release.Name }}-rediscache-master
- name: ENKETO_LINKED_FORM_AND_DATA_SERVER_SERVER_URL
  value: "{{ .Values.kobocat.subdomain }}.{{ .Values.general.externalDomain }}"
- name: ENKETO_LINKED_FORM_AND_DATA_SERVER_API_KEY
  value: {{ .Values.enketo.apiKey | quote }}
- name: ENKETO_SUPPORT_EMAIL
  value: {{ .Values.general.supportEmail }}
{{- end -}}

{{- define "env_externals" -}}
- name: GOOGLE_ANALYTICS_TOKEN
  value: {{ .Values.external.google.analyticsToken | quote }}
- name: KOBOCAT_RAVEN_DSN
  value: {{ .Values.external.ravenDSN.kobocat | quote }}
- name: KPI_RAVEN_DSN
  value: {{ .Values.external.ravenDSN.kpi | quote }}
- name: KPI_RAVEN_JS_DSN
  value: {{ .Values.external.ravenDSN.kpiJs | quote }}
{{- end -}}

{{- define "env_kobocat" -}}
- name: KOBOCAT_DJANGO_DEBUG
  value: {{ include "boolean2str" .Values.general.debug | quote }}
- name: TEMPLATE_DEBUG
  value: {{ include "boolean2str" .Values.general.debug | quote }}
- name: USE_X_FORWARDED_HOST
  value: 'False'

# - name: DJANGO_SETTINGS_MODULE
#   value: onadata.settings.kc_environ
- name: ENKETO_VERSION
  value: Express

- name: KOBOCAT_BROKER_URL
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-secrets
      key: KOBOCAT_BROKER_URL

- name: KOBOCAT_CELERY_LOG_FILE
  value: /srv/logs/celery.log

- name: ENKETO_OFFLINE_SURVEYS
  value: 'True'

- name: KOBOCAT_MONGO_HOST
  value: {{ .Release.Name }}-mongodb

- name: KOBOFORM_URL
  value: {{ include "kpi_url" . | quote }}
- name: KOBOFORM_INTERNAL_URL
  value: "http://{{ .Values.kpi.subdomain }}.{{ include "internal_domain" . }}"
- name: KOBOCAT_URL
  value: {{ include "kobocat_url" . | quote }}
- name: ENKETO_URL
  value: {{ include "enketo_url" . | quote }}

# DATABASE
- name: DATABASE_URL
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-secrets
      key: KC_DATABASE_URL
- name: POSTGRES_DB
  value: {{ .Values.postgresql.kobocatDatabase | quote }}

# OTHER
- name: KPI_URL
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-secrets
      key: KPI_URL
- name: KPI_INTERNAL_URL
  value: "http://{{ .Values.kpi.subdomain }}.{{ include "internal_domain" . }}"
- name: DJANGO_DEBUG
  value: {{ include "boolean2str" .Values.general.debug | quote }}
- name: RAVEN_DSN
  value: {{ .Values.external.ravenDSN.kobocat | quote }}
{{- end -}}

{{- define "env_kpi" -}}
- name: KPI_DJANGO_DEBUG
  value: {{ include "boolean2str" .Values.general.debug | quote }}
- name: TEMPLATE_DEBUG
  value: {{ include "boolean2str" .Values.general.debug | quote }}
- name: USE_X_FORWARDED_HOST
  value: 'False'

- name: ENKETO_VERSION
  value: Express
- name: KPI_PREFIX
  value: /
- name: KPI_BROKER_URL
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-secrets
      key: KPI_BROKER_URL

- name: KPI_MONGO_HOST
  value: {{ .Release.Name }}-mongodb

- name: DKOBO_PREFIX
  value: 'False'
- name: KOBO_SURVEY_PREVIEW_EXPIRATION
  value: '24'
- name: SKIP_CELERY
  value: 'False'
- name: EMAIL_FILE_PATH
  value: ./emails
- name: SYNC_KOBOCAT_XFORMS_PERIOD_MINUTES
  value: '30'
- name: KPI_UWSGI_PROCESS_COUNT
  value: '2'

- name: KOBOFORM_URL
  value: {{ include "kpi_url" . | quote }}
- name: ENKETO_URL
  value: {{ include "enketo_url" . | quote }}
- name: ENKETO_INTERNAL_URL
  value: "http://{{ .Release.Name }}-enketo:8005"
- name: KOBOCAT_URL
  value: {{ include "kobocat_url" . | quote }}
- name: KOBOCAT_INTERNAL_URL
  value: "http://{{ .Values.kobocat.subdomain }}.{{ include "internal_domain" . }}"

# DATABASE
- name: DATABASE_URL
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-secrets
      key: KPI_DATABASE_URL
- name: POSTGRES_DB
  value: {{ .Values.postgresql.kpiDatabase | quote }}

# OTHER
- name: DJANGO_DEBUG
  value: {{ include "boolean2str" .Values.general.debug | quote }}
- name: RAVEN_DSN
  value: {{ .Values.external.ravenDSN.kpi | quote }}
- name: RAVEN_JS_DSN
  value: {{ .Values.external.ravenDSN.kpiJs | quote }}
- name: KPI_URL
  value: {{ include "kpi_url" . | quote }}
{{- end -}}

{{- define "env_smtp" -}}
- name: EMAIL_BACKEND
  value: django.core.mail.backends.smtp.EmailBackend
- name: EMAIL_HOST
  value: {{ .Values.smtp.host | quote }}
- name: EMAIL_PORT
  value: {{ .Values.smtp.port | quote }}
- name: EMAIL_HOST_USER
  value: {{ .Values.smtp.user | quote }}
- name: EMAIL_HOST_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-secrets
      key: EMAIL_HOST_PASSWORD
- name: EMAIL_USE_TLS
  value: {{ include "boolean2str" .Values.smtp.tls | quote }}
- name: DEFAULT_FROM_EMAIL
  value: {{ .Values.smtp.from | quote }}
{{- end -}}

{{- define "env_uwsgi" -}}
{{- $root := index . 0 -}}
{{- $prefix := index . 1 -}}
- name: {{ $prefix }}_UWSGI_MAX_REQUESTS
  value: '512'
- name: {{ $prefix }}_UWSGI_WORKERS_COUNT
  value: {{ $root.Values.uwsgi.workers | quote }}
- name: {{ $prefix }}_UWSGI_CHEAPER_RSS_LIMIT_SOFT
  value: {{ $root.Values.uwsgi.cheaperRssLimitSoft | quote }}
- name: {{ $prefix }}_UWSGI_CHEAPER_WORKERS_COUNT
  value: {{ $root.Values.uwsgi.cheaper | quote }}
- name: {{ $prefix }}_UWSGI_HARAKIRI
  value: '120'
- name: {{ $prefix }}_UWSGI_WORKER_RELOAD_MERCY
  value: '120'
# - name: UWSGI_GROUP
#   value: wsgi
# - name: UWSGI_USER
#   value: wsgi
{{- end -}}
