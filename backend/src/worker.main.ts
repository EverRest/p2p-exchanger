/**
 * Privileged BullMQ worker entrypoint (stub).
 * Feature processors land with specs/001-exchange-platform tasks — not yet.
 * Runtime must load secrets from worker-only env (.env.worker), never from API.
 */
async function bootstrap(): Promise<void> {
  console.log(
    '[worker] stub process started — awaiting feature implementation',
  );
  await new Promise(() => undefined);
}

void bootstrap();
