export interface Building {
    buildingId: string;
    coordinates: number[] | number[][] | number[][][];
    createdAt: string;
    projectId: string;
    userId: string;
    _id: string;
  }

//   _id: new ObjectId('675a71d42500f277809d2b76'),
//     buildingId: 'building-1733980628107',
//     coordinates: [ [Array], [Array], [Array], [Array] ],
//     projectId: '67548bbd8ebd055db1c8d4e8',
//     userId: 'fQAXK0TgK1OsegBmEIiQ6fR8NGX2',
//     createdAt: 2024-12-12T05:17:08.113Z
//   },