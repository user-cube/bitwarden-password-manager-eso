{{/*
Expand the name of the chart.
*/}}
{{- define "bitwarden-password-manager-eso.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "bitwarden-password-manager-eso.fullname" -}}
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

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "bitwarden-password-manager-eso.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "bitwarden-password-manager-eso.labels" -}}
helm.sh/chart: {{ include "bitwarden-password-manager-eso.chart" . }}
{{ include "bitwarden-password-manager-eso.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "bitwarden-password-manager-eso.selectorLabels" -}}
app.kubernetes.io/name: {{ include "bitwarden-password-manager-eso.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "bitwarden-password-manager-eso.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "bitwarden-password-manager-eso.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
{{/*
Startup script used when bwServe.disableOriginProtection is true: the image's
entrypoint.sh verbatim, plus --disable-origin-protection on `bw serve`.
*/}}
{{- define "bitwarden-password-manager-eso.serveScript" -}}
set -e
bw config server "$BW_HOST"
if [ -n "$BW_CLIENTID" ] && [ -n "$BW_CLIENTSECRET" ]; then
  echo "Using apikey to log in"
  bw login --apikey --raw
  export BW_SESSION=$(bw unlock --passwordenv BW_PASSWORD --raw)
else
  echo "Using username and password to log in"
  export BW_SESSION=$(bw login "$BW_USER" --passwordenv BW_PASSWORD --raw)
fi
bw unlock --check
echo 'Running `bw serve` on port 8087'
bw serve --hostname all --disable-origin-protection
{{- end }}

{{/*
Name of the Secret holding the Bitwarden credentials
*/}}
{{- define "bitwarden-password-manager-eso.credentialsSecretName" -}}
{{- .Values.bitwarden.existingSecret | default (printf "%s-credentials" (include "bitwarden-password-manager-eso.fullname" .)) }}
{{- end }}
