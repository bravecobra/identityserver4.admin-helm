{{/*
Expand the name of the chart.
*/}}
{{- define "identityserver4admin.name" -}}
{{- default .Chart.Name .Values.admin.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "identityserver4admin.fullname" -}}
{{- if .Values.admin.fullnameOverride }}
{{- .Values.admin.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.admin.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "identityserver4admin.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels Admin
*/}}
{{- define "identityserver4admin.labelsAdmin" -}}
helm.sh/chart: {{ include "identityserver4admin.chart" . }}
{{ include "identityserver4admin.selectorLabelsAdmin" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Common labels Identity
*/}}
{{- define "identityserver4admin.labelsIdentity" -}}
helm.sh/chart: {{ include "identityserver4admin.chart" . }}
{{ include "identityserver4admin.selectorLabelsIdentity" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Common labels Api
*/}}
{{- define "identityserver4admin.labelsApi" -}}
helm.sh/chart: {{ include "identityserver4admin.chart" . }}
{{ include "identityserver4admin.selectorLabelsApi" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels Admin
*/}}
{{- define "identityserver4admin.selectorLabelsAdmin" -}}
app.kubernetes.io/name: {{ include "identityserver4admin.name" . }}-admin
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Selector labels Identity
*/}}
{{- define "identityserver4admin.selectorLabelsIdentity" -}}
app.kubernetes.io/name: {{ include "identityserver4admin.name" . }}-identity
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Selector labels Api
*/}}
{{- define "identityserver4admin.selectorLabelsApi" -}}
app.kubernetes.io/name: {{ include "identityserver4admin.name" . }}-api
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use for admin
*/}}
{{- define "identityserver4admin.serviceAccountNameAdmin" -}}
{{- if .Values.admin.serviceAccount.create }}
{{- default (include "identityserver4admin.fullname" .) .Values.admin.serviceAccount.name }}-admin
{{- else }}
{{- default "default" .Values.admin.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the service account to use for identity
*/}}
{{- define "identityserver4admin.serviceAccountNameIdentity" -}}
{{- if .Values.identity.serviceAccount.create }}
{{- default (include "identityserver4admin.fullname" .) .Values.identity.serviceAccount.name }}-identity
{{- else }}
{{- default "default" .Values.identity.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the service account to use for Api
*/}}
{{- define "identityserver4admin.serviceAccountNameApi" -}}
{{- if .Values.identity.serviceAccount.create }}
{{- default (include "identityserver4admin.fullname" .) .Values.api.serviceAccount.name }}-api
{{- else }}
{{- default "default" .Values.api.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name for the SA password secret key.
*/}}
{{- define "mssql.sapassword" -}}
  sa_password
{{- end -}}

{{/*
Create the name for the mssql service
*/}}
{{- define "mssql.serviceName" -}}
{{ include "identityserver4admin.name" . }}-mssql
{{- end -}}

{{- define "databaseConnectionString" -}}
  {{- $mssqlConnection := printf "Server=%s-mssql;Database=%s;User Id=%s;Password=%s;MultipleActiveResultSets=true" .Release.Name "IdentityServer4Admin" "sa" .Values.mssql.sa_password  -}}
  {{- $mysqlConnection := printf "server=%s-mysql;database=%s;user=%s;password=%s" .Release.Name .Values.mysql.auth.database "root" .Values.mysql.auth.rootPassword  -}}
  {{- $postgresqlConnection := printf "Server=%s-postgresql;Port=5432;Database=%s;User Id=%s;Password=%s" .Release.Name .Values.postgresql.postgresqlDatabase "postgres" .Values.postgresql.postgresqlPassword  -}}
  {{- if .Values.database.connectionString -}}
    {{- default "default" .Values.database.connectionString }}
  {{- else if .Values.mssql.enabled -}}
    {{- default "default" $mssqlConnection }}
  {{- else if .Values.mysql.enabled -}}
    {{- default "default" $mysqlConnection}}
  {{- else if .Values.postgresql.enabled -}}
    {{- default "default" $postgresqlConnection }}
  {{- else -}}
  {{- end -}}

{{- end -}}
