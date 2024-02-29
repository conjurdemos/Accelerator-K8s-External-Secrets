#!/usr/bin/env bash

set -euo pipefail
cat << EOL
---
apiVersion: v1
kind: Service
metadata:
  name: demo-app
  namespace: ${APP_NAMESPACE_NAME}
  labels:
    app: demo-app
spec:
  ports:
  - protocol: TCP
    port: 8080
    targetPort: 8080
  selector:
    app: demo-app
  type: NodePort
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: demo-app
  name: demo-app
  namespace: ${APP_NAMESPACE_NAME}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: demo-app
  template:
    metadata:
      labels:
        app: demo-app
    spec:
      serviceAccountName: ${APP_SERVICE_ACCOUNT_NAME}
      containers:
      - name: demo-app
        image: cyberark/demo-app:latest
        imagePullPolicy: IfNotPresent
        ports:
        - name: http
          containerPort: 8080
        readinessProbe:
          httpGet:
            path: /pets
            port: http
          initialDelaySeconds: 15
          timeoutSeconds: 5
        env:
          - name: DB_URL
            valueFrom:
              secretKeyRef:
                name: db-credentials
                key: url
          - name: DB_USERNAME
            valueFrom:
              secretKeyRef:
                name: db-credentials
                key: username
          - name: DB_PASSWORD
            valueFrom:
              secretKeyRef:
                name: db-credentials
                key: password
          - name: DB_PLATFORM
            valueFrom:
              secretKeyRef:
                name: db-credentials
                key: platform
EOL
