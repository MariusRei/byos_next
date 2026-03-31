ARG NODE_VERSION=24
FROM node:${NODE_VERSION}-alpine AS base

LABEL org.opencontainers.image.title="TRMNL BYOS Next.js"
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
WORKDIR /app
RUN apk add --no-cache libc6-compat
RUN corepack enable pnpm

FROM base AS deps
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

FROM base AS builder
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN pnpm run build

FROM base AS runner
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 --ingroup nodejs nextjs

# --- DIESE ZEILEN SIND NUTZNOTWENDIG FÜR DIE MIGRATION ---
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/migrations ./migrations
COPY --from=builder /app/node_modules ./node_modules 
# -------------------------------------------------------

COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

RUN mkdir -p .next/cache && chown -R nextjs:nodejs .next
USER 1001:1001
EXPOSE 3000
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

# Der Befehl macht erst die Tabellen klar und startet dann den Server
CMD ["sh", "-c", "npx better-auth migrate -y && node server.js"]