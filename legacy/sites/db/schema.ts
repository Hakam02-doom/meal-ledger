import { sqliteTable, text, integer } from "drizzle-orm/sqlite-core";
export const workspaces = sqliteTable("workspaces", {
 owner: text("owner").primaryKey(), payload: text("payload").notNull(), revision: integer("revision").notNull().default(0),
 pinHash: text("pin_hash"), pinSalt: text("pin_salt"), failures: integer("failures").notNull().default(0), lockedUntil: integer("locked_until").notNull().default(0)
});
export const sessions = sqliteTable("unlock_sessions", { token: text("token").primaryKey(), owner: text("owner").notNull(), expires: integer("expires").notNull() });
