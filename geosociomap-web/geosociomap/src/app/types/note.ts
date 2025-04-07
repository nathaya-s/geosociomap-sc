export type NoteItem = MainNote | PositionNote;

export interface MainNote {
  type: "main";
  id: string;
  title: string;
  description: string;
  imageUrls: string[];
  attachments: File[];
}

export interface Attachment {
  name: string;
  type: string;
  size: number;
  lastModified: number;
  url: string;
}

export interface PositionNote {
  type: "position";
  id: string;
  latitude: number;
  longitude: number;
  attachments: Attachment[];
  note: string;
}

export interface SubNote {
  id: string;
  title: string;
  description: string;
  imageUrls?: string[];
  timestamp?: Date;
}

export interface NoteSequence {
  id: string;
  items: PositionNote[];
  note: string;
  imageUrls: string[];
  attachments: Attachment[];
  visible: boolean;
}
