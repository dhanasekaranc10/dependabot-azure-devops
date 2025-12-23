FROM ruby:3.3-slim

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    BUNDLE_WITHOUT=test:development

WORKDIR /dependabot

# System dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    ca-certificates \
    build-essential \
    libssl-dev \
    libcurl4-openssl-dev \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*


RUN git clone https://github.com/dependabot/dependabot-core.git . \
    && git checkout v0.351.0


RUN gem install bundler \
    && bundle install --without test development


WORKDIR /app
COPY run.sh /app/run.sh
RUN chmod +x /app/run.sh

ENTRYPOINT ["/app/run.sh"]
