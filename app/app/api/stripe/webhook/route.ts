import Stripe from 'stripe';
import { headers } from 'next/headers';
export const runtime = 'nodejs';
export async function POST(req: Request) {
  const buf = Buffer.from(await req.arrayBuffer());
  const sig = (await headers()).get('stripe-signature') || '';
  const secret = process.env.STRIPE_WEBHOOK_SECRET!;
  const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, { apiVersion: '2024-06-20' });
  try {
    const event = stripe.webhooks.constructEvent(buf, sig, secret);
    console.log('stripe_event', event.type);
    return new Response('ok');
  } catch (e:any) {
    return new Response(`invalid signature: ${e.message}`, { status: 400 });
  }
}
