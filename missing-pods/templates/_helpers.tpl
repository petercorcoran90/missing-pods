{{/*
Common name helpers
*/}}
{{- define "case.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "case.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "case.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "case.namespace" -}}
{{- .Release.Namespace -}}
{{- end -}}

{{/*
Standard labels applied to every game resource. The `game: missing-pods`
label is the one the player can use with `-l game=missing-pods` if they
ever need to scope their queries.
*/}}
{{- define "case.labels" -}}
app.kubernetes.io/name: {{ include "case.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
game: missing-pods
{{- end -}}

{{/*
Resource defaults pulled from values.yaml so every workload is identically
modest. Keeps things friendly on a tiny dev cluster.
*/}}
{{- define "case.resources" -}}
resources:
{{ toYaml .Values.resources.default | indent 2 }}
{{- end -}}

{{/*
DNS name for the validator (Precinct HQ) inside the cluster. The player
curls this from the detective-terminal pod.
*/}}
{{- define "case.validatorHost" -}}
{{ .Values.validator.serviceName }}.{{ .Release.Namespace }}.svc.cluster.local
{{- end -}}
