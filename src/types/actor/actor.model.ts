import type { IMedia } from "@/types/media.model";
import { ActorType, ApprovalStatus } from "../enums";

export interface IActor {
  id?: string;
  url: string;
  name: string;
  domain: string | null;
  mediaSize?: number;
  summary: string;
  preferredUsername: string;
  suspended: boolean;
  approvalStatus?: ApprovalStatus;
  avatar?: IMedia | null;
  banner?: IMedia | null;
  type: ActorType;
}

export type IMinimalActor = Pick<IActor, "preferredUsername" | "domain">;
export type IMinimalActorWithName = Pick<
  IActor,
  "preferredUsername" | "domain" | "name"
>;

export class Actor implements IActor {
  id?: string;

  avatar: IMedia | null = null;

  banner: IMedia | null = null;

  domain: string | null = null;

  mediaSize = 0;

  name = "";

  preferredUsername = "";

  summary = "";

  suspended = false;

  approvalStatus?: ApprovalStatus = ApprovalStatus.APPROVED;

  url = "";

  type: ActorType = ActorType.PERSON;

  constructor(hash: IActor | Record<any, unknown> = {}) {
    Object.assign(this, hash);
  }

  get displayNameAndUsername(): string {
    return `${this.name} (${this.usernameWithDomain})`;
  }

  usernameWithDomain(): string {
    if (!this.preferredUsername) return "";
    const domain = this.domain ? `@${this.domain}` : "";
    return `@${this.preferredUsername}${domain}`;
  }

  public displayName(): string {
    return displayName(this);
  }
}

export function usernameWithDomain(
  actor: IMinimalActor | undefined,
  force = false
): string {
  console.log(
    "[usernameWithDomain] Called with actor:",
    actor,
    "force:",
    force
  );

  if (!actor || !actor.preferredUsername) {
    console.log(
      "[usernameWithDomain] No actor or preferredUsername, returning empty string"
    );
    return "";
  }

  if (actor?.domain) {
    const result = `${actor.preferredUsername}@${actor.domain}`;
    console.log("[usernameWithDomain] Using domain, returning:", result);
    return result;
  }

  if (force) {
    const result = `${actor.preferredUsername}@${window.location.hostname}`;
    console.log("[usernameWithDomain] Force mode, returning:", result);
    return result;
  }

  console.log(
    "[usernameWithDomain] Using preferredUsername only:",
    actor.preferredUsername
  );
  return actor.preferredUsername;
}

export function displayName(actor: IMinimalActorWithName | undefined): string {
  console.log("[displayName] Called with actor:", actor);

  const hasValidName =
    actor &&
    actor.name != null &&
    actor.name !== "" &&
    actor.name !== "undefined";

  console.log("[displayName] Actor name validation:", {
    actorExists: !!actor,
    nameExists: actor?.name != null,
    nameNotEmpty: actor?.name !== "",
    nameNotUndefined: actor?.name !== "undefined",
    hasValidName: hasValidName,
    actualName: actor?.name,
  });

  const result = hasValidName ? actor.name : usernameWithDomain(actor);
  console.log("[displayName] Returning:", result);

  return result;
}

export function displayNameAndUsername(actor: IMinimalActorWithName): string {
  if (actor.name && actor.name !== "undefined" && actor.name.trim() !== "") {
    return `${actor.name} (@${usernameWithDomain(actor)})`;
  }
  return usernameWithDomain(actor);
}
