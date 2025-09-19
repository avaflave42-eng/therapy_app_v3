import Stripe from 'stripe';
export const runtime = 'nodejs';
export async function POST(req: Request) {
  const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, { apiVersion: '2024-06-20' });
  const { amount = 5000, currency = 'usd' } = await req.json().catch(() => ({}));
  const pi = await stripe.paymentIntents.create({
    amount: Number(amount),
    currency: String(currency),
    capture_method: 'manual',
    automatic_payment_methods: { enabled: true }
  });
  return Response.json({ clientSecret: pi.client_secret });
}
