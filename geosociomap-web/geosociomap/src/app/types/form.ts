// types/form.ts

export type QuestionType = "multiple_choice" | "text" | "file_upload" | "number" | "checkbox";

export interface QuestionOption {
  label: string;
  value: string;
  color?: string;
}

export interface Question {
  id: string;
  label: string;
  type: QuestionType;
  options?: QuestionOption[]; 
  showMapToggle?: boolean;
  showOnMap?: boolean;
  answer?: string;
}

export type FormType =
  | "personal_info"
  | "community_issues"
  | "financial_info"
  | "utilities_info"
  | "tourism"
  | "health"
  | "custom";

export interface Form {
  id: string;
//   formType: FormType;
  questions: Question[]; 
}

export interface Answer {
  [questionId: string]: string | number;
}

export interface LayerData {
  buildingId: string;
  answers: Answer;
  color: string;
  layerId: string;
  coordinates: [number, number];
  _id: string;
}