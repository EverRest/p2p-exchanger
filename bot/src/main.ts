/**
 * Telegram bot stub — thin client over /api/v1 (implementation later).
 * Do not put business rules or secrets beyond TELEGRAM_BOT_TOKEN here.
 */
import 'dotenv/config';

const apiBase = process.env.API_BASE_URL ?? 'http://localhost:3000/api/v1';

async function main(): Promise<void> {
  console.log(`[bot] stub ready; API_BASE_URL=${apiBase}`);
  console.log(
    '[bot] feature work deferred — see specs/001-exchange-platform/tasks.md US3',
  );
  // Keep process alive in docker; exit in local one-shot if BOT_EXIT=1
  if (process.env.BOT_EXIT === '1') {
    return;
  }
  await new Promise(() => undefined);
}

void main();
