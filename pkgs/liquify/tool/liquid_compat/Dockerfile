FROM ruby:3.4.10-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends git \
    && git clone https://github.com/Shopify/liquid.git /opt/liquid \
    && git -C /opt/liquid checkout --detach 15a2e32d186f713643fe86202da8da44a7bb058b \
    && rm -rf /opt/liquid/.git /var/lib/apt/lists/*

COPY render.rb /usr/local/lib/render-liquid.rb
ENTRYPOINT ["ruby", "-I", "/opt/liquid/lib", "/usr/local/lib/render-liquid.rb"]
