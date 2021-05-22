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
Common labels mssql
*/}}
{{- define "identityserver4admin.labelsMssql" -}}
helm.sh/chart: {{ include "identityserver4admin.chart" . }}
{{ include "identityserver4admin.selectorLabelsMssql" . }}
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
Selector labels Mssql
*/}}
{{- define "identityserver4admin.selectorLabelsMssql" -}}
app.kubernetes.io/name: {{ include "identityserver4admin.name" . }}-mssql
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "identityserver4admin.serviceAccountName" -}}
{{- if .Values.admin.serviceAccount.create }}
{{- default (include "identityserver4admin.fullname" .) .Values.admin.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.admin.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name for the SA password secret key.
*/}}
{{- define "mssql.sapassword" -}}
  sa_password
{{- end -}}
