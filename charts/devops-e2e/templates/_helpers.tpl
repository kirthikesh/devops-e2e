{{- define "e2e.labels" -}}
app.kubernetes.io/part-of: {{ .Chart.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end -}}

{{- define "e2e.dbSecretName" -}}
{{ .Release.Name }}-db
{{- end -}}

{{- define "e2e.podSecurity" -}}
securityContext:
  runAsNonRoot: true
  seccompProfile: { type: RuntimeDefault }
{{- end -}}

{{- define "e2e.containerSecurity" -}}
securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: false
  capabilities: { drop: ["ALL"] }
{{- end -}}
