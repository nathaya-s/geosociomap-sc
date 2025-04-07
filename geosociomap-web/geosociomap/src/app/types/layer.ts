import { StaticImageData } from "next/image";
import { Question } from "./form";

// types/layer.ts

export interface IconMarker {
    name: string;
    description: string;
    iconName: string;
    color: string; 
    lng: number;
    lat: number;
    imageUrls?: string[];
  }
  
  export interface Path {
    id: string;
    points: { lng: number; lat: number }[];
    thickness: number; 
    color: string; 
    name: string;
    description: string; 
  }
  
  export interface Layer {
    id: string;
    title: string;
    description: string;
    imageUrl: string | StaticImageData;
    visible: boolean; 
    markers: IconMarker[];
    paths: Path[]; 
    order: number;
    questions: Question[]; 
    sharedWith: string[];
    isDeleted: boolean;
  }
