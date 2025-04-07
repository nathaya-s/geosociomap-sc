export interface BaseStat {
    label: string;
    type: "multiple_choice" | "number" | "text" | "checkbox";
  }
  
  export interface MultipleChoiceStat extends BaseStat {
    type: "multiple_choice";
    data: Record<string, number>;
  }
  
  export interface NumberStat extends BaseStat {
    type: "number";
    data: {
      mean: number;
      median: number;
      max: number;
      min: number;
    };
  }
  
  export interface TextStat extends BaseStat {
    type: "text";
    data: string[];
  }
  
  export interface CheckboxStat extends BaseStat {
    type: "checkbox";
    data:  Record<string, number>;
  }
  
  export type Stat =
    | MultipleChoiceStat
    | NumberStat
    | TextStat
    | CheckboxStat;
  
  export interface LayerData {
    id: string;
    values: Stat[]; 
  }