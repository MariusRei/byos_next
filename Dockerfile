# ... (alles vor dem runner stage bleibt gleich)

# Production image, copy all the files and run next
FROM base AS runner

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 --ingroup nodejs nextjs

# --- NEU: Wir brauchen diese Dateien für die Migration ---
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/migrations ./migrations
# Wir kopieren die node_modules für die CLI-Tools (Better Auth)
COPY --from=builder /app/node_modules ./node_modules 
# -------------------------------------------------------

# Copy built application
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

RUN mkdir -p .next/cache
RUN chown -R nextjs:nodejs .next

USER 1001:1001

EXPOSE 3000

ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

# --- NEU: Der Befehl führt erst die Migration aus, dann den Server ---
CMD ["sh", "-c", "npx better-auth migrate -y && node server.js"]