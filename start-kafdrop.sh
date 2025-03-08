#!/bin/bash

set -e

# Check where the kafdrop.jar file is located
echo "🔍 Searching for Kafdrop JAR file..."
echo ""

if [[ -f "/app/kafdrop.jar" ]]; then
    JAR_PATH="/app/kafdrop.jar"
elif [[ -f "/kafdrop.jar" ]]; then
    JAR_PATH="/kafdrop.jar"
elif [[ -f "/opt/kafdrop/kafdrop.jar" ]]; then
    JAR_PATH="/opt/kafdrop/kafdrop.jar"
else
    # Try to find the JAR file
    JAR_PATH=$(find / -name "kafdrop*.jar" 2>/dev/null | head -1)
    
    if [[ -z "$JAR_PATH" ]]; then
        echo "❌ Could not find kafdrop.jar. Exiting..."
        exit 1
    fi
fi

echo "Found Kafdrop JAR at $JAR_PATH"
echo ""
echo "🚀 Initialise Kafdrop with SSL configuration..."
echo ""

# Define the Kafka properties file path
KAFKA_PROPERTIES_FILE="/tmp/kafka.properties"

# Create the kafka.properties file and write configuration
cat <<EOF > "$KAFKA_PROPERTIES_FILE"
security.protocol=SSL
ssl.truststore.location=${KAFDROP_CERTS}/truststore.jks
ssl.truststore.password=${TRUSTSTORE_PASSWORD}
ssl.keystore.location=${KAFDROP_CERTS}/${KUBERNETES_SERVICE_NAME}.${KUBERNETES_NAMESPACE}.jks
ssl.keystore.password=${KEYSTORE_PASSWORD}
ssl.key.password=${KEY_PASSWORD}
ssl.keystore.type=PKCS12
ssl.truststore.type=PKCS12
ssl.client.auth=required
ssl.endpoint.identification.algorithm=
EOF

# Ensure the kafka.properties file exists
if [[ ! -f "${KAFKA_PROPERTIES_FILE}" ]]; then
    echo "❌ kafka.properties file is missing. Exiting..."
    exit 1
fi

# Echo the content of the file to verify
echo "🔍 Generated ${KAFKA_PROPERTIES_FILE}:"
echo ""

# Ensure the file has the correct permissions
chmod 640 "${KAFKA_PROPERTIES_FILE}"

# Start Kafdrop with the properties file
exec java -jar "$JAR_PATH" \
  --server.port=9000 \
  --server.ssl.enabled=true \
  --server.ssl.key-store="${KAFDROP_CERTS}/${KUBERNETES_SERVICE_NAME}.${KUBERNETES_NAMESPACE}.jks" \
  --server.ssl.key-store-password="${KEYSTORE_PASSWORD}" \
  --server.ssl.key-store-type=PKCS12 \
  --server.ssl.key-password="${KEY_PASSWORD}" \
  --server.ssl.key-alias="${KUBERNETES_SERVICE_NAME}.${KUBERNETES_NAMESPACE}" \
  --server.ssl.trust-store="${KAFDROP_CERTS}/truststore.jks" \
  --server.ssl.trust-store-password="${TRUSTSTORE_PASSWORD}" \
  --server.ssl.client-auth=none \
  --topic.deleteEnabled=false \
  --topic.createEnabled=false \
  --kafka.brokerConnect="SSL://${KAFKA_CLUSTER}.${KUBERNETES_NAMESPACE}.svc.cluster.local:${KAFKA_CLUSTER_PORT}" \
  --kafka.propertiesFile="${KAFKA_PROPERTIES_FILE}"