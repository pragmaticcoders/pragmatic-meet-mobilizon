export interface IGroupPostSurvey {
  id: string;
  uuid: string;
  title: string;
  description: string | null;
  schema: Record<string, unknown>;
  status: "draft" | "published" | "closed";
  contextId: string;
  groupId: string;
}
