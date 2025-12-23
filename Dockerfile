FROM ruby:3.3

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    BUNDLE_WITHOUT="test development"

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    ca-certificates \
    build-essential \
    pkg-config \
    libssl-dev \
    libcurl4-openssl-dev \
    libxml2-dev \
    libxslt1-dev \
    zlib1g-dev \
    libffi-dev \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*


WORKDIR /dependabot
RUN git clone https://github.com/dependabot/dependabot-core.git . \
    && git checkout v0.351.0


RUN gem install bundler \
 && bundle config set path vendor/bundle \
 && bundle config set without "test development" \
 && bundle install --jobs 4 --retry 3


WORKDIR /app
COPY run.sh /app/run.sh
RUN chmod +x /app/run.sh

ENTRYPOINT ["/app/run.sh"]
