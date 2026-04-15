-- Admin operations additions: support priority/assignment, support messages,
-- and provider-ready notification delivery tracking.

CREATE TYPE "SupportPriority" AS ENUM ('LOW', 'NORMAL', 'HIGH', 'URGENT');

ALTER TABLE "SupportTicket"
  ADD COLUMN "priority" "SupportPriority" NOT NULL DEFAULT 'NORMAL',
  ADD COLUMN "assignedAdminId" TEXT;

CREATE TABLE "SupportTicketMessage" (
  "id" TEXT NOT NULL,
  "ticketId" TEXT NOT NULL,
  "authorId" TEXT NOT NULL,
  "body" TEXT NOT NULL,
  "isInternal" BOOLEAN NOT NULL DEFAULT false,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT "SupportTicketMessage_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "AdminNotificationDeliveryLog" (
  "id" TEXT NOT NULL,
  "notificationId" TEXT NOT NULL,
  "provider" TEXT NOT NULL,
  "status" TEXT NOT NULL,
  "target" TEXT,
  "errorMessage" TEXT,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT "AdminNotificationDeliveryLog_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "SupportTicketMessage_ticketId_createdAt_idx"
  ON "SupportTicketMessage"("ticketId", "createdAt");

CREATE INDEX "AdminNotificationDeliveryLog_notificationId_createdAt_idx"
  ON "AdminNotificationDeliveryLog"("notificationId", "createdAt");

ALTER TABLE "SupportTicket"
  ADD CONSTRAINT "SupportTicket_assignedAdminId_fkey"
  FOREIGN KEY ("assignedAdminId") REFERENCES "User"("id")
  ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "SupportTicketMessage"
  ADD CONSTRAINT "SupportTicketMessage_ticketId_fkey"
  FOREIGN KEY ("ticketId") REFERENCES "SupportTicket"("id")
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "SupportTicketMessage"
  ADD CONSTRAINT "SupportTicketMessage_authorId_fkey"
  FOREIGN KEY ("authorId") REFERENCES "User"("id")
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "AdminNotificationDeliveryLog"
  ADD CONSTRAINT "AdminNotificationDeliveryLog_notificationId_fkey"
  FOREIGN KEY ("notificationId") REFERENCES "AdminNotification"("id")
  ON DELETE CASCADE ON UPDATE CASCADE;
