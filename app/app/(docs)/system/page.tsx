export default function Page() {
  return (
    <main className="p-8 space-y-6">
      <h1 className="text-2xl font-bold">System Map</h1>
      <ul className="list-disc pl-6 space-y-2">
        <li><a className="underline" href="/docs/02-dataflow.png">Dataflow</a></li>
        <li><a className="underline" href="/docs/03-sequence-booking.png">Booking Sequence</a></li>
        <li><a className="underline" href="/docs/04-state-booking.png">Booking State</a></li>
        <li><a className="underline" href="https://github.com/avaflave42-eng/therapy_app_v3/tree/main/spec">API Contracts</a></li>
      </ul>
    </main>
  );
}
