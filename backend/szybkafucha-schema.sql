--
-- PostgreSQL database dump
--

\restrict CrIN8NzhVzlqqO3IiyCTKBjhjza0miVaOYK0900x5yonUeGrZkptyHLXsHSzYUi

-- Dumped from database version 15.15
-- Dumped by pg_dump version 15.15

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

--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: contractor_profiles_kycstatus_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.contractor_profiles_kycstatus_enum AS ENUM (
    'pending',
    'verified',
    'rejected'
);


--
-- Name: credit_transactions_type_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.credit_transactions_type_enum AS ENUM (
    'topup',
    'deduction',
    'refund',
    'bonus'
);


--
-- Name: kyc_checks_result_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.kyc_checks_result_enum AS ENUM (
    'clear',
    'consider',
    'unidentified'
);


--
-- Name: kyc_checks_status_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.kyc_checks_status_enum AS ENUM (
    'pending',
    'in_progress',
    'complete',
    'failed'
);


--
-- Name: kyc_checks_type_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.kyc_checks_type_enum AS ENUM (
    'document',
    'facial_similarity',
    'bank_account'
);


--
-- Name: payments_status_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.payments_status_enum AS ENUM (
    'pending',
    'held',
    'captured',
    'refunded',
    'failed'
);


--
-- Name: ratings_role_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.ratings_role_enum AS ENUM (
    'client',
    'contractor'
);


--
-- Name: task_applications_status_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.task_applications_status_enum AS ENUM (
    'pending',
    'accepted',
    'rejected',
    'withdrawn',
    'kicked'
);


--
-- Name: tasks_status_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.tasks_status_enum AS ENUM (
    'created',
    'accepted',
    'confirmed',
    'in_progress',
    'pending_complete',
    'completed',
    'cancelled',
    'disputed'
);


--
-- Name: users_status_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.users_status_enum AS ENUM (
    'pending',
    'active',
    'suspended',
    'banned',
    'deleted'
);


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: client_profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.client_profiles (
    "userId" uuid NOT NULL,
    bio text,
    "ratingAvg" numeric(3,2) DEFAULT '0'::numeric NOT NULL,
    "ratingCount" integer DEFAULT 0 NOT NULL,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: contractor_profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contractor_profiles (
    "userId" uuid NOT NULL,
    bio text,
    categories text DEFAULT ''::text NOT NULL,
    "serviceRadiusKm" integer DEFAULT 10 NOT NULL,
    "kycStatus" public.contractor_profiles_kycstatus_enum DEFAULT 'pending'::public.contractor_profiles_kycstatus_enum NOT NULL,
    "kycIdVerified" boolean DEFAULT false NOT NULL,
    "kycSelfieVerified" boolean DEFAULT false NOT NULL,
    "kycBankVerified" boolean DEFAULT false NOT NULL,
    "stripeAccountId" character varying(255),
    "ratingAvg" numeric(3,2) DEFAULT '0'::numeric NOT NULL,
    "ratingCount" integer DEFAULT 0 NOT NULL,
    "completedTasksCount" integer DEFAULT 0 NOT NULL,
    "isOnline" boolean DEFAULT false NOT NULL,
    "lastLocationLat" numeric(10,7),
    "lastLocationLng" numeric(10,7),
    "lastLocationAt" timestamp without time zone,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: credit_transactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.credit_transactions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    "userId" uuid NOT NULL,
    amount numeric(10,2) NOT NULL,
    type public.credit_transactions_type_enum NOT NULL,
    "taskId" uuid,
    "stripePaymentIntentId" character varying(255),
    description character varying(500) NOT NULL,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: deleted_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.deleted_accounts (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    "originalUserId" uuid NOT NULL,
    "userTypes" text,
    email character varying(255),
    phone character varying(15),
    name character varying(100),
    address character varying(255),
    "avatarUrl" text,
    "contractorBio" text,
    "clientBio" text,
    "contractorRatingAvg" numeric(3,2) DEFAULT '0'::numeric NOT NULL,
    "contractorRatingCount" integer DEFAULT 0 NOT NULL,
    "clientRatingAvg" numeric(3,2) DEFAULT '0'::numeric NOT NULL,
    "clientRatingCount" integer DEFAULT 0 NOT NULL,
    reviews jsonb,
    "deletedAt" timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: kyc_checks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.kyc_checks (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    "userId" uuid NOT NULL,
    type public.kyc_checks_type_enum NOT NULL,
    "onfidoApplicantId" character varying(255),
    "onfidoCheckId" character varying(255),
    "onfidoDocumentId" character varying(255),
    status public.kyc_checks_status_enum DEFAULT 'pending'::public.kyc_checks_status_enum NOT NULL,
    result public.kyc_checks_result_enum,
    "resultDetails" jsonb,
    "errorMessage" text,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "completedAt" timestamp without time zone
);


--
-- Name: messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.messages (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    "taskId" uuid NOT NULL,
    "senderId" uuid NOT NULL,
    content text NOT NULL,
    "readAt" timestamp without time zone,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    flagged boolean DEFAULT false NOT NULL,
    "recipientId" uuid
);


--
-- Name: migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.migrations (
    id integer NOT NULL,
    "timestamp" bigint NOT NULL,
    name character varying NOT NULL
);


--
-- Name: migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.migrations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.migrations_id_seq OWNED BY public.migrations.id;


--
-- Name: newsletter_subscribers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.newsletter_subscribers (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(255) NOT NULL,
    email character varying(255) NOT NULL,
    city character varying(100),
    "userType" character varying(20) NOT NULL,
    consent boolean DEFAULT true NOT NULL,
    services text,
    comments text,
    source character varying(50),
    "isActive" boolean DEFAULT true NOT NULL,
    "subscribedAt" timestamp without time zone,
    "unsubscribedAt" timestamp without time zone,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: payments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payments (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    "taskId" uuid NOT NULL,
    "stripePaymentIntentId" character varying(255),
    "stripeTransferId" character varying(255),
    amount numeric(10,2) NOT NULL,
    "commissionAmount" numeric(10,2),
    "contractorAmount" numeric(10,2),
    status public.payments_status_enum DEFAULT 'pending'::public.payments_status_enum NOT NULL,
    "refundReason" text,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: ratings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ratings (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    "taskId" uuid NOT NULL,
    "fromUserId" uuid NOT NULL,
    "toUserId" uuid NOT NULL,
    rating integer NOT NULL,
    comment text,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    role public.ratings_role_enum DEFAULT 'contractor'::public.ratings_role_enum NOT NULL
);


--
-- Name: task_applications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.task_applications (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    "taskId" uuid NOT NULL,
    "contractorId" uuid NOT NULL,
    "proposedPrice" numeric(10,2) NOT NULL,
    message text,
    status public.task_applications_status_enum DEFAULT 'pending'::public.task_applications_status_enum NOT NULL,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "respondedAt" timestamp without time zone,
    "joinedRoomAt" timestamp without time zone,
    "firstMessageSentAt" timestamp without time zone
);


--
-- Name: tasks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tasks (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    "clientId" uuid NOT NULL,
    "contractorId" uuid,
    category character varying(50) NOT NULL,
    title character varying(200) NOT NULL,
    description text,
    "locationLat" numeric(10,7) NOT NULL,
    "locationLng" numeric(10,7) NOT NULL,
    address text NOT NULL,
    "budgetAmount" numeric(10,2) NOT NULL,
    "finalAmount" numeric(10,2),
    "commissionAmount" numeric(10,2),
    "tipAmount" numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    status public.tasks_status_enum DEFAULT 'created'::public.tasks_status_enum NOT NULL,
    "completionPhotos" text,
    "scheduledAt" timestamp without time zone,
    "acceptedAt" timestamp without time zone,
    "startedAt" timestamp without time zone,
    "completedAt" timestamp without time zone,
    "cancelledAt" timestamp without time zone,
    "cancellationReason" text,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "imageUrls" text,
    "confirmedAt" timestamp without time zone,
    "estimatedDurationHours" numeric(4,1),
    "clientRated" boolean DEFAULT false NOT NULL,
    "contractorRated" boolean DEFAULT false NOT NULL,
    "maxApplications" integer DEFAULT 5 NOT NULL,
    "flatFee" numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    "matchingFee" numeric(10,2) DEFAULT '0'::numeric NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    phone character varying(15),
    email character varying(255),
    name character varying(100),
    "avatarUrl" text,
    status public.users_status_enum DEFAULT 'pending'::public.users_status_enum NOT NULL,
    "googleId" character varying(255),
    "appleId" character varying(255),
    "fcmToken" text,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL,
    types text DEFAULT 'client'::text NOT NULL,
    address character varying(255),
    "passwordHash" character varying(255),
    "passwordUpdatedAt" timestamp without time zone,
    "emailVerified" boolean DEFAULT false NOT NULL,
    "failedLoginAttempts" integer DEFAULT 0 NOT NULL,
    "lockedUntil" timestamp without time zone,
    "deletedAt" timestamp without time zone,
    "notificationPreferences" jsonb DEFAULT '{"messages": true, "payments": true, "kycUpdates": true, "taskUpdates": true, "newNearbyTasks": true, "ratingsAndTips": true}'::jsonb NOT NULL,
    "dateOfBirth" date,
    credits numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    strikes integer DEFAULT 0 NOT NULL
);


--
-- Name: migrations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.migrations ALTER COLUMN id SET DEFAULT nextval('public.migrations_id_seq'::regclass);


--
-- Name: ratings PK_0f31425b073219379545ad68ed9; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ratings
    ADD CONSTRAINT "PK_0f31425b073219379545ad68ed9" PRIMARY KEY (id);


--
-- Name: messages PK_18325f38ae6de43878487eff986; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT "PK_18325f38ae6de43878487eff986" PRIMARY KEY (id);


--
-- Name: payments PK_197ab7af18c93fbb0c9b28b4a59; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT "PK_197ab7af18c93fbb0c9b28b4a59" PRIMARY KEY (id);


--
-- Name: contractor_profiles PK_33422a2326b87941d10893457e8; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contractor_profiles
    ADD CONSTRAINT "PK_33422a2326b87941d10893457e8" PRIMARY KEY ("userId");


--
-- Name: newsletter_subscribers PK_38f9333e9961b2fdb589128d19b; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.newsletter_subscribers
    ADD CONSTRAINT "PK_38f9333e9961b2fdb589128d19b" PRIMARY KEY (id);


--
-- Name: deleted_accounts PK_84b0e56607f563d0fc8e4a6501f; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deleted_accounts
    ADD CONSTRAINT "PK_84b0e56607f563d0fc8e4a6501f" PRIMARY KEY (id);


--
-- Name: migrations PK_8c82d7f526340ab734260ea46be; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.migrations
    ADD CONSTRAINT "PK_8c82d7f526340ab734260ea46be" PRIMARY KEY (id);


--
-- Name: tasks PK_8d12ff38fcc62aaba2cab748772; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT "PK_8d12ff38fcc62aaba2cab748772" PRIMARY KEY (id);


--
-- Name: users PK_a3ffb1c0c8416b9fc6f907b7433; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT "PK_a3ffb1c0c8416b9fc6f907b7433" PRIMARY KEY (id);


--
-- Name: credit_transactions PK_a408319811d1ab32832ec86fc2c; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.credit_transactions
    ADD CONSTRAINT "PK_a408319811d1ab32832ec86fc2c" PRIMARY KEY (id);


--
-- Name: client_profiles PK_af81cdb71317b2f0f6cb6bce776; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_profiles
    ADD CONSTRAINT "PK_af81cdb71317b2f0f6cb6bce776" PRIMARY KEY ("userId");


--
-- Name: kyc_checks PK_c28137b746ea89f69376ac1b862; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.kyc_checks
    ADD CONSTRAINT "PK_c28137b746ea89f69376ac1b862" PRIMARY KEY (id);


--
-- Name: task_applications PK_cc9118fd164bc1fb5e929ff18cf; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_applications
    ADD CONSTRAINT "PK_cc9118fd164bc1fb5e929ff18cf" PRIMARY KEY (id);


--
-- Name: users UQ_60cea0d80c39eedaaaf5e21f175; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT "UQ_60cea0d80c39eedaaaf5e21f175" UNIQUE ("appleId");


--
-- Name: task_applications UQ_77aa393e5f191fe7ee681bfecd5; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_applications
    ADD CONSTRAINT "UQ_77aa393e5f191fe7ee681bfecd5" UNIQUE ("taskId", "contractorId");


--
-- Name: users UQ_97672ac88f789774dd47f7c8be3; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT "UQ_97672ac88f789774dd47f7c8be3" UNIQUE (email);


--
-- Name: users UQ_a000cca60bcf04454e727699490; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT "UQ_a000cca60bcf04454e727699490" UNIQUE (phone);


--
-- Name: users UQ_f382af58ab36057334fb262efd5; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT "UQ_f382af58ab36057334fb262efd5" UNIQUE ("googleId");


--
-- Name: IDX_0dc48416511f011f7de7b2a8f8; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "IDX_0dc48416511f011f7de7b2a8f8" ON public.newsletter_subscribers USING btree (email);


--
-- Name: IDX_7008e8645cb4e48af0773631c6; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_7008e8645cb4e48af0773631c6" ON public.task_applications USING btree ("contractorId", status);


--
-- Name: IDX_8544a5b04e47c5299eaa030695; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_8544a5b04e47c5299eaa030695" ON public.task_applications USING btree ("taskId", status);


--
-- Name: IDX_adb40e435b3f67d381a260f10c; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_adb40e435b3f67d381a260f10c" ON public.messages USING btree ("taskId", "senderId", "recipientId");


--
-- Name: IDX_f31233f25cf2015095fca7f6b6; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_f31233f25cf2015095fca7f6b6" ON public.credit_transactions USING btree ("userId", "createdAt");


--
-- Name: credit_transactions FK_03c845db40a2d75145d46deb9b3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.credit_transactions
    ADD CONSTRAINT "FK_03c845db40a2d75145d46deb9b3" FOREIGN KEY ("taskId") REFERENCES public.tasks(id);


--
-- Name: tasks FK_0b0e41e0b7293cb872b09163531; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT "FK_0b0e41e0b7293cb872b09163531" FOREIGN KEY ("contractorId") REFERENCES public.users(id);


--
-- Name: task_applications FK_1b7e1ceadfa57b909d3f9690530; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_applications
    ADD CONSTRAINT "FK_1b7e1ceadfa57b909d3f9690530" FOREIGN KEY ("contractorId") REFERENCES public.users(id);


--
-- Name: payments FK_1d49f62d71893e18c3d71fe1689; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT "FK_1d49f62d71893e18c3d71fe1689" FOREIGN KEY ("taskId") REFERENCES public.tasks(id);


--
-- Name: credit_transactions FK_2121be176f72337ccf7cc4ef04e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.credit_transactions
    ADD CONSTRAINT "FK_2121be176f72337ccf7cc4ef04e" FOREIGN KEY ("userId") REFERENCES public.users(id);


--
-- Name: messages FK_2db9cf2b3ca111742793f6c37ce; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT "FK_2db9cf2b3ca111742793f6c37ce" FOREIGN KEY ("senderId") REFERENCES public.users(id);


--
-- Name: contractor_profiles FK_33422a2326b87941d10893457e8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contractor_profiles
    ADD CONSTRAINT "FK_33422a2326b87941d10893457e8" FOREIGN KEY ("userId") REFERENCES public.users(id);


--
-- Name: tasks FK_4e7cd3aff0dbd7708e02b14ecb8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT "FK_4e7cd3aff0dbd7708e02b14ecb8" FOREIGN KEY ("clientId") REFERENCES public.users(id);


--
-- Name: kyc_checks FK_a463726544e1e1a43b7aeefc185; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.kyc_checks
    ADD CONSTRAINT "FK_a463726544e1e1a43b7aeefc185" FOREIGN KEY ("userId") REFERENCES public.users(id);


--
-- Name: client_profiles FK_af81cdb71317b2f0f6cb6bce776; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_profiles
    ADD CONSTRAINT "FK_af81cdb71317b2f0f6cb6bce776" FOREIGN KEY ("userId") REFERENCES public.users(id);


--
-- Name: ratings FK_cb300f7c8a62eb3f1e394ce4c6c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ratings
    ADD CONSTRAINT "FK_cb300f7c8a62eb3f1e394ce4c6c" FOREIGN KEY ("taskId") REFERENCES public.tasks(id);


--
-- Name: task_applications FK_dc586d54c00ce75195403cdee10; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_applications
    ADD CONSTRAINT "FK_dc586d54c00ce75195403cdee10" FOREIGN KEY ("taskId") REFERENCES public.tasks(id);


--
-- Name: ratings FK_f1d8c3473dc910170bd67a76558; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ratings
    ADD CONSTRAINT "FK_f1d8c3473dc910170bd67a76558" FOREIGN KEY ("toUserId") REFERENCES public.users(id);


--
-- Name: messages FK_f548818d46a1315d4e1d5e62da5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT "FK_f548818d46a1315d4e1d5e62da5" FOREIGN KEY ("recipientId") REFERENCES public.users(id);


--
-- Name: messages FK_fd2c4496fbb610e44408e279537; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT "FK_fd2c4496fbb610e44408e279537" FOREIGN KEY ("taskId") REFERENCES public.tasks(id);


--
-- Name: ratings FK_fd94d05641b3a6bdabf02aca740; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ratings
    ADD CONSTRAINT "FK_fd94d05641b3a6bdabf02aca740" FOREIGN KEY ("fromUserId") REFERENCES public.users(id);


--
-- PostgreSQL database dump complete
--

\unrestrict CrIN8NzhVzlqqO3IiyCTKBjhjza0miVaOYK0900x5yonUeGrZkptyHLXsHSzYUi

