
\restrict ftIqA3mJnBkCD6NOIrg6RsPLx3JMdC6uNOJcIdvSVLJfAv3HEGZdUXphizogWSa


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE SCHEMA IF NOT EXISTS "public";


ALTER SCHEMA "public" OWNER TO "pg_database_owner";


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE TYPE "public"."booking_channel" AS ENUM (
    'tier_a_direct',
    'tier_d_concierge'
);


ALTER TYPE "public"."booking_channel" OWNER TO "postgres";


CREATE TYPE "public"."booking_state" AS ENUM (
    'NEW',
    'QUOTED',
    'HOLD_PLACED',
    'SLOT_LOCKED',
    'BOOKED',
    'CANCELLED'
);


ALTER TYPE "public"."booking_state" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_updated_at_column"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  new.updated_at := now();
  return new;
end $$;


ALTER FUNCTION "public"."update_updated_at_column"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."bookings" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "intake_id" "uuid",
    "practitioner_npi" "text" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "state" "public"."booking_state" DEFAULT 'NEW'::"public"."booking_state",
    "channel" "public"."booking_channel" DEFAULT 'tier_a_direct'::"public"."booking_channel",
    "payment_intent_id" "text",
    "platform_fee_cents" integer DEFAULT 2500,
    "slots" "jsonb" DEFAULT '[]'::"jsonb",
    "chosen_slot" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."bookings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."eligibility_snapshots" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "patient_insurance_id" "uuid" NOT NULL,
    "active" boolean DEFAULT true,
    "copay" integer,
    "coinsurance" numeric,
    "deductible_remaining" numeric,
    "visit_limit" integer,
    "telehealth_ok" boolean DEFAULT true,
    "referral_required" boolean DEFAULT false,
    "auth_required" boolean DEFAULT false,
    "network_name" "text",
    "eb12_flag" "text",
    "captured_at" timestamp with time zone DEFAULT "now"(),
    "expires_at" timestamp with time zone DEFAULT ("now"() + '48:00:00'::interval)
);


ALTER TABLE "public"."eligibility_snapshots" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."patient_insurance" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "payer_id" "text" NOT NULL,
    "plan_name" "text" NOT NULL,
    "network_name" "text",
    "member_id" "text" NOT NULL,
    "group_number" "text",
    "bh_admin" "text",
    "effective_date" "date",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."patient_insurance" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."patient_intakes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "zip" "text",
    "dob" "date",
    "modality" "text",
    "languages" "text"[],
    "goals" "text"[],
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."patient_intakes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."practitioners" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "npi" "text" NOT NULL,
    "first_name" "text" NOT NULL,
    "last_name" "text" NOT NULL,
    "license_states" "text"[],
    "languages" "text"[],
    "modalities" "text"[],
    "populations" "text"[],
    "accepts_new" boolean DEFAULT true,
    "last_verified_at" timestamp with time zone
);


ALTER TABLE "public"."practitioners" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."provider_contracts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "provider_npi" "text" NOT NULL,
    "billing_npi" "text",
    "tin" "text",
    "payer_id" "text" NOT NULL,
    "product_or_network" "text" NOT NULL,
    "places_of_service" "text"[],
    "telehealth_ok" boolean DEFAULT true,
    "accepting_new" boolean DEFAULT true,
    "last_attested_at" timestamp with time zone
);


ALTER TABLE "public"."provider_contracts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."screening_results" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "intake_id" "uuid" NOT NULL,
    "instrument" "text" NOT NULL,
    "raw" "jsonb",
    "score" integer,
    "risk_level" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."screening_results" OWNER TO "postgres";


ALTER TABLE ONLY "public"."bookings"
    ADD CONSTRAINT "bookings_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."eligibility_snapshots"
    ADD CONSTRAINT "eligibility_snapshots_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."patient_insurance"
    ADD CONSTRAINT "patient_insurance_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."patient_intakes"
    ADD CONSTRAINT "patient_intakes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."practitioners"
    ADD CONSTRAINT "practitioners_npi_key" UNIQUE ("npi");



ALTER TABLE ONLY "public"."practitioners"
    ADD CONSTRAINT "practitioners_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."provider_contracts"
    ADD CONSTRAINT "provider_contracts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."screening_results"
    ADD CONSTRAINT "screening_results_pkey" PRIMARY KEY ("id");



CREATE OR REPLACE TRIGGER "update_bookings_updated_at" BEFORE UPDATE ON "public"."bookings" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



ALTER TABLE ONLY "public"."bookings"
    ADD CONSTRAINT "bookings_intake_id_fkey" FOREIGN KEY ("intake_id") REFERENCES "public"."patient_intakes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."eligibility_snapshots"
    ADD CONSTRAINT "eligibility_snapshots_patient_insurance_id_fkey" FOREIGN KEY ("patient_insurance_id") REFERENCES "public"."patient_insurance"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."screening_results"
    ADD CONSTRAINT "screening_results_intake_id_fkey" FOREIGN KEY ("intake_id") REFERENCES "public"."patient_intakes"("id") ON DELETE CASCADE;



CREATE POLICY "Public can view practitioners" ON "public"."practitioners" FOR SELECT USING (true);



CREATE POLICY "Public can view provider contracts" ON "public"."provider_contracts" FOR SELECT USING (true);



CREATE POLICY "Users can manage their own bookings" ON "public"."bookings" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can manage their own insurance" ON "public"."patient_insurance" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can manage their own intakes" ON "public"."patient_intakes" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can manage their own screening results" ON "public"."screening_results" USING ((EXISTS ( SELECT 1
   FROM "public"."patient_intakes" "pi"
  WHERE (("pi"."id" = "screening_results"."intake_id") AND ("pi"."user_id" = "auth"."uid"()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."patient_intakes" "pi"
  WHERE (("pi"."id" = "screening_results"."intake_id") AND ("pi"."user_id" = "auth"."uid"())))));



CREATE POLICY "Users can view their own eligibility" ON "public"."eligibility_snapshots" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."patient_insurance" "pi"
  WHERE (("pi"."id" = "eligibility_snapshots"."patient_insurance_id") AND ("pi"."user_id" = "auth"."uid"())))));



ALTER TABLE "public"."bookings" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."eligibility_snapshots" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."patient_insurance" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."patient_intakes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."practitioners" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."provider_contracts" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."screening_results" ENABLE ROW LEVEL SECURITY;


GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";



GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "service_role";



GRANT ALL ON TABLE "public"."bookings" TO "anon";
GRANT ALL ON TABLE "public"."bookings" TO "authenticated";
GRANT ALL ON TABLE "public"."bookings" TO "service_role";



GRANT ALL ON TABLE "public"."eligibility_snapshots" TO "anon";
GRANT ALL ON TABLE "public"."eligibility_snapshots" TO "authenticated";
GRANT ALL ON TABLE "public"."eligibility_snapshots" TO "service_role";



GRANT ALL ON TABLE "public"."patient_insurance" TO "anon";
GRANT ALL ON TABLE "public"."patient_insurance" TO "authenticated";
GRANT ALL ON TABLE "public"."patient_insurance" TO "service_role";



GRANT ALL ON TABLE "public"."patient_intakes" TO "anon";
GRANT ALL ON TABLE "public"."patient_intakes" TO "authenticated";
GRANT ALL ON TABLE "public"."patient_intakes" TO "service_role";



GRANT ALL ON TABLE "public"."practitioners" TO "anon";
GRANT ALL ON TABLE "public"."practitioners" TO "authenticated";
GRANT ALL ON TABLE "public"."practitioners" TO "service_role";



GRANT ALL ON TABLE "public"."provider_contracts" TO "anon";
GRANT ALL ON TABLE "public"."provider_contracts" TO "authenticated";
GRANT ALL ON TABLE "public"."provider_contracts" TO "service_role";



GRANT ALL ON TABLE "public"."screening_results" TO "anon";
GRANT ALL ON TABLE "public"."screening_results" TO "authenticated";
GRANT ALL ON TABLE "public"."screening_results" TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";






\unrestrict ftIqA3mJnBkCD6NOIrg6RsPLx3JMdC6uNOJcIdvSVLJfAv3HEGZdUXphizogWSa

RESET ALL;
