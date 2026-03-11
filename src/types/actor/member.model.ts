import type { IActor, IGroup, IPerson } from ".";
import { MemberRole } from "../enums";

export interface IMember {
  id?: string;
  role: MemberRole;
  parent: IGroup;
  /** Set when the member has an account; null when invited by email and not yet registered */
  actor?: IActor | null;
  /** Email when invited by email and not yet registered; display instead of actor */
  invitedEmail?: string | null;
  invitedBy?: IPerson;
  insertedAt: string;
  updatedAt: string;
}
