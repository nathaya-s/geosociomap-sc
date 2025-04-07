// สร้าง interface สำหรับ Project

  export interface Point {
    lat: number;
    lng: number;
  }
  
  export interface Project {
    _id: string;
    projectName: string;
    userIds: [];
    selectedPoints: Point[];
    createdAt: string;
    lastUpdate: string;
  }
  