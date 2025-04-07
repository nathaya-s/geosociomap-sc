// // pages/api/saveUser.ts
// import type { NextApiRequest, NextApiResponse } from 'next';
// import clientPromise from '../mongodb';

// export default async function handler(req: NextApiRequest, res: NextApiResponse) {
//     if (req.method === 'POST') {
//       const { uid, email } = req.body;
  
//       try {
//         const client = await clientPromise;
//         const db = client.db('geosociomap');
//         const collection = db.collection('users');
  
//         // ตรวจสอบว่าผู้ใช้มีอยู่แล้วหรือไม่
//         const existingUser = await collection.findOne({ uid });
  
//         if (existingUser) {
//           res.status(200).json({ message: 'User already exists' });
//         } else {
//           // บันทึกข้อมูลผู้ใช้
//           await collection.insertOne({ uid, email, createdAt: new Date() });
//           res.status(201).json({ message: 'User saved successfully' });
//         }
//       } catch (error) {
//         res.status(500).json({ message: 'Internal Server Error' });
//       }
//     } else {
//       res.status(405).json({ message: 'Method Not Allowed' });
//     }
//   }