{{/*
_helpers.tpl - named templates shared by every file in templates/.
Files whose names begin with an underscore never produce objects.
Every name starts with "tasktracker." because named templates are global.
*/}}

{{/* tasktracker.name: the chart name, or nameOverride. */}}
{{- define "tasktracker.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
tasktracker.fullname: the base name of every object, limited to 63 characters.
A release called "task-tracker" gives "task-tracker", not "task-tracker-task-tracker".
*/}}
{{- define "tasktracker.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/* tasktracker.chart: "<name>-<version>" for the helm.sh/chart label. */}}
{{- define "tasktracker.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* tasktracker.environment: stops rendering when no environment is chosen. */}}
{{- define "tasktracker.environment" -}}
{{- required "environment must be set to dev or prod (use -f environments/<env>.yaml)" .Values.environment }}
{{- end }}

{{/* Object names for each tier. Used by the objects AND by the ConfigMap. */}}
{{- define "tasktracker.dbName" -}}
{{- printf "%s-db" (include "tasktracker.fullname" .) }}
{{- end }}
{{- define "tasktracker.backendName" -}}
{{- printf "%s-backend" (include "tasktracker.fullname" .) }}
{{- end }}
{{- define "tasktracker.frontendName" -}}
{{- printf "%s-frontend" (include "tasktracker.fullname" .) }}
{{- end }}

{{/*
tasktracker.secretName: the Secret that holds the database credentials.
Contract C3: the chart never renders a Secret. In Assignment 4 the Secret is
created by the Sealed Secrets controller from a SealedSecret in platform/<env>/.
*/}}
{{- define "tasktracker.secretName" -}}
{{- required "credentials.existingSecret must name a Secret with DB_USER, DB_PASSWORD, POSTGRES_USER and POSTGRES_PASSWORD" .Values.credentials.existingSecret }}
{{- end }}

{{/*
tasktracker.image: "<repository>:<tag>". Called with (dict "ctx" $ "image" .Values.<tier>.image).
Tag order: per-tier tag, then image.tag, then appVersion.
*/}}
{{- define "tasktracker.image" -}}
{{- $tag := .image.tag | default .ctx.Values.image.tag | default .ctx.Chart.AppVersion }}
{{- printf "%s:%s" .image.repository $tag }}
{{- end }}

{{/*
tasktracker.selectorLabels: the small, stable set that selectors use.
Called with (dict "ctx" $ "tier" "backend"). Never changes after install,
because Deployment.spec.selector is immutable.
*/}}
{{- define "tasktracker.selectorLabels" -}}
app.kubernetes.io/name: {{ include "tasktracker.name" .ctx }}
app.kubernetes.io/instance: {{ .ctx.Release.Name }}
tier: {{ .tier }}
{{- end }}

{{/* tasktracker.labels: the full label set for an object of one tier. */}}
{{- define "tasktracker.labels" -}}
helm.sh/chart: {{ include "tasktracker.chart" .ctx }}
{{ include "tasktracker.selectorLabels" . }}
app.kubernetes.io/component: {{ .tier }}
app.kubernetes.io/part-of: task-tracker
app.kubernetes.io/version: {{ .ctx.Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .ctx.Release.Service }}
app.kubernetes.io/environment: {{ include "tasktracker.environment" .ctx | quote }}
{{- end }}

{{/* tasktracker.commonLabels: labels for objects that belong to no tier. */}}
{{- define "tasktracker.commonLabels" -}}
helm.sh/chart: {{ include "tasktracker.chart" . }}
app.kubernetes.io/name: {{ include "tasktracker.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/part-of: task-tracker
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/environment: {{ include "tasktracker.environment" . | quote }}
{{- end }}
