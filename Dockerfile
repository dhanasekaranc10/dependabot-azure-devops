FROM ruby:3.3

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    BUNDLE_WITHOUT="test development"

RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl ca-certificates build-essential pkg-config \
    libssl-dev libcurl4-openssl-dev libxml2-dev libxslt1-dev \
    zlib1g-dev libffi-dev nodejs npm \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /dependabot

# Copy vendored dependabot-core
COPY dependabot-core/ /dependabot/dependabot-core/

RUN cd dependabot-core && \
    gem install bundler && \
    bundle config set path vendor/bundle && \
    bundle config set without "test development" && \
    bundle install --jobs 4 --retry 3

# Copy our custom runner
COPY runner.rb /dependabot/runner.rb

ENTRYPOINT ["ruby", "/dependabot/runner.rb"]
