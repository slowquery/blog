{{- define "blog.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "blog.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ include "blog.name" . }}-{{ .Chart.Version | replace "+" "_" }}
{{- end }}

{{- define "blog.workloadLabels" -}}
app.kubernetes.io/name: application
app.kubernetes.io/part-of: imustdo.work
app.kubernetes.io/version: {{ .Values.images.application.tag | quote }}
version: {{ .Values.images.application.tag | quote }}
{{- end }}

{{- define "blog.image" -}}
{{- printf "%s/%s/%s:%s" .Values.global.registry .Values.global.project .Values.images.application.repository .Values.images.application.tag }}
{{- end }}

{{- define "blog.envFrom" -}}
envFrom:
  - secretRef:
      name: {{ .Values.secrets.envSecretName }}
{{- end }}

{{- define "blog.imagePullSecrets" -}}
{{- with .Values.global.imagePullSecrets }}
imagePullSecrets:
  {{- range . }}
  - name: {{ if kindIs "string" . }}{{ . }}{{ else }}{{ .name }}{{ end }}
  {{- end }}
{{- end }}
{{- end }}
