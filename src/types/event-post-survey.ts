export interface IEventPostSurvey {
  id: string;
  title: string;
  description: string | null;
  schema: Record<string, unknown>;
  status: "draft" | "published" | "closed";
  contextId: string;
}
