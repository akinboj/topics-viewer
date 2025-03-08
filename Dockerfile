FROM obsidiandynamics/kafdrop:4.1.0

ARG IMAGE_BUILD_TIMESTAMP
ENV IMAGE_BUILD_TIMESTAMP=${IMAGE_BUILD_TIMESTAMP}
RUN echo IMAGE_BUILD_TIMESTAMP=${IMAGE_BUILD_TIMESTAMP}

# Set working directory and certs
WORKDIR /opt/kafdrop
RUN mkdir -p /etc/kafdrop && chmod 755 /etc/kafdrop
ENV KAFDROP_CERTS=/etc/kafdrop
ENV TZ="Australia/Sydney"

# Copy startup script
COPY start-kafdrop.sh /usr/local/bin/start-kafdrop.sh
RUN chmod +x /usr/local/bin/start-kafdrop.sh

# Entrypoint
ENTRYPOINT ["/usr/local/bin/start-kafdrop.sh"]