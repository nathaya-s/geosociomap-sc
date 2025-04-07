const express = require('express');
const cors = require('cors');
const { MongoClient } = require('mongodb');
const { default: Project } = require('./models/project.js');
const Layer = require('./models/Layer.js');
const { CloudinaryStorage } = require('multer-storage-cloudinary');
const cloudinary = require('./cloudinary');


require('dotenv').config();

const app = express();
const multer = require("multer");
const path = require("path");
const fs = require("fs");
const firebaseAdmin = require('firebase-admin');



const uri = process.env.MONGODB_URI;
let client;

async function connectToMongoDB() {
  if (!client) {
    client = new MongoClient(uri); 
    await client.connect();
    console.log('Connected to MongoDB');
  } else if (!client.topology || client.topology.isDestroyed()) {
    client = new MongoClient(uri);
    await client.connect();
    console.log('Reconnected to MongoDB');
  }
  return client;
}


app.use(cors());
app.options("*", cors());
app.use(express.json());
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = "uploads";
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir);
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    cb(null, Date.now() + path.extname(file.originalname));
  },
});


const storagee = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: {
    folder: 'uploads',
    allowed_formats: ['jpg', 'png', 'jpeg'], 
    public_id: (req, file) => file.originalname.split('.')[0], 
  },
});
const upload = multer({ storage: storagee });
app.post('/upload', upload.single('file'), (req, res) => {
  try {
    res.status(200).json({
      message: 'File uploaded successfully!',
      fileUrl: req.file.path,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = upload;

app.use("/uploads", express.static(path.join(__dirname, 'uploads')));

app.get('/users', async (req, res) => {
  try {
    const db = client.db('geosociomap');
    const collection = db.collection('users');
    const data = await collection.find({}).toArray();
    res.json(data);
  } catch (e) {
    res.status(500).send('Error fetching data');
  }
});

app.post('/createUser', async (req, res) => {
  const { uid, email } = req.body;
  console.log(uid, email);

  if (!uid || !email) {
    return res.status(400).json({ error: 'Missing uid or email' });
  }

  try {
    const client = await connectToMongoDB();
    const db = client.db('geosociomap');
    const collection = db.collection('users');

    const existingUser = await collection.findOne({ uid });
    console.log(existingUser);

    if (existingUser) {
      return res.status(200).json({ message: 'User already exists', data: existingUser });
    }

    const result = await collection.insertOne({ uid, email });
    res.status(201).json({ message: 'User created successfully', data: result.ops[0] });
  } catch (e) {
    console.error(e);
    res.status(500).send('Error inserting data');
  }
});


async function deleteUser(uid) {
  try {
    await client.connect();
    const db = client.db('geosociomap');
    const collection = db.collection('users');
    const result = await collection.deleteOne({ uid: uid });
    console.log('User deleted:', result.deletedCount > 0);
  } catch (error) {
    console.error('Error deleting user:', error);
  }
}

app.post('/deleteUser', async (req, res) => {
  const { uid } = req.body;
  if (!uid) {
    return res.status(400).json({ error: 'Missing UID' });
  }
  try {
    await deleteUser(uid);
    res.status(200).json({ message: 'User deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Error deleting user' });
  }
});

app.post("/create-project", async (req, res) => {
  try {
    const client = await connectToMongoDB();
    const db = client.db("geosociomap");
    const { projectName, userId, selectedPoints, selectedEmails } = req.body;
    console.log("/create-project", projectName, userId, selectedPoints, selectedEmails)
    if (!projectName || !userId || !Array.isArray(selectedPoints) || !Array.isArray(selectedEmails)) {
      return res.status(400).json({ error: "Invalid input" });
    }

    const userIds = await Promise.all(
      selectedEmails.map(async (email) => {
        try {
          const user = await getUserIdByEmail(email); 
          return user ? user.uid : null;
        } catch (error) {
          console.warn(`Error getting UID for email ${email}:`, error);
          return null;
        }
      })
    );

    const validUserIds = userIds.filter((uid) => uid !== null);

    const projectCollection = db.collection("projects");
    const projectResult = await projectCollection.insertOne({
      projectName,
      userIds: [userId, ...validUserIds],
      selectedPoints,
      lastUpdate: new Date(),
      createdAt: new Date(),
    });

    const projectId = projectResult.insertedId.toString();

    const noteCollection = db.collection("notes");
    const notes = [userId, ...validUserIds].map((uid) => ({
      projectId,
      userId: uid,
      id: "note",
      items: [],
      note: "",
      imageUrls: [],
      attachments: [],
      visible: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    }));

    const noteResult = await noteCollection.insertMany(notes);

    res.status(200).json({
      message: "Project and associated notes created successfully",
      projectData: {
        projectName,
        userIds: [userId, ...validUserIds],
        selectedPoints,
        lastUpdate: new Date(),
        createdAt: new Date(),
      },
      noteData: {
        projectId,
        userId: userId,
        id: "note",
        items: [],
        note: "",
        imageUrls: [],
        attachments: [],
        visible: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      },
    });
  } catch (error) {
    console.error("Error creating project and note:", error);
    res.status(500).json({ error: "Error creating project and note" });
  }
});
app.get('/api/getUserIdsByEmails', async (req, res) => {
  let emails = req.query.emails;

  if (typeof emails === 'string') {
    emails = [emails];
  }

  console.log(emails);

  if (!emails || !Array.isArray(emails)) {
    return res.status(400).json({ message: 'Invalid or missing emails' });
  }

  try {
    const client = await connectToMongoDB();
    const db = client.db('geosociomap');
    const collection = db.collection('users');

   
    const users = await collection
      .find({ email: { $in: emails } }) 
      .toArray(); 

   
    if (users.length === 0) {
      return res.status(404).json({ message: 'No users found for the provided emails' });
    }

   
    return res.status(200).json({
      message: 'User IDs retrieved successfully',
      userIds: users.map(user => user.uid), 
    });
  } catch (error) {
    console.error('Error fetching user IDs by emails:', error);
    return res.status(500).json({ message: 'Failed to fetch user IDs', error: error.message });
  }
});



app.post("/update-project", async (req, res) => {
  try {
    const client = await connectToMongoDB();
    const db = client.db("geosociomap");
    const { projectId, projectName, selectedPoints, selectedEmails, userId } = req.body;

    console.log("/update-project", projectId, projectName, selectedPoints, selectedEmails, userId);

    if (!projectId || !projectName || !userId || !Array.isArray(selectedPoints)) {
      return res.status(400).json({ error: "Invalid input" });
    }

    const userIds = await Promise.all(
      selectedEmails.map(async (email) => {
        try {
          const user = await getUserIdByEmail(email); 
          console.log(user)
          return user ? user.uid : null;
        } catch (error) {
          console.warn(`Error getting UID for email ${email}:`, error);
          return null;
        }
      })
    );

    const myuserid = userId;
    const validUserIds = userIds.filter((uid) => uid !== null);

    const projectCollection = db.collection("projects");
    const projectResult = await projectCollection.updateOne(
      { _id: new ObjectId(projectId) }, 
      {
        $set: {
          projectName,
          userIds: [myuserid, ...validUserIds],
          selectedPoints,
          lastUpdate: new Date(), 
        },
      }
    );
    if (projectResult.matchedCount === 0) {
      return res.status(404).json({ error: "Project not found" });
    }

    const noteCollection = db.collection("notes");
    const noteResult = await noteCollection.updateMany(
      { projectId: projectId },
      {
        $set: {
          userId: userId,
          updatedAt: new Date(),
        },
      }
    );

    res.status(200).json({
      message: "Project and associated notes updated successfully",
      projectData: projectResult,
      noteData: noteResult.modifiedCount,
    });
  } catch (error) {
    console.error("Error updating project and notes:", error);
    res.status(500).json({ error: "Error updating project and notes" });
  }
});



async function getUserIdByEmail(email) {
  try {
    const client = await connectToMongoDB();
    const database = client.db('geosociomap');
    const usersCollection = database.collection('users'); 

    const user = await usersCollection.findOne({ email: email });
    if (user) {
      return { uid: user.uid };
    }

    return null;
  } catch (error) {
    console.error('Error fetching user by email:', error);
    throw new Error('Database error');
  }
}

app.delete('/projects/:projectId', async (req, res) => {
  try {
    const { projectId } = req.params; 

    const client = await connectToMongoDB();
    const db = client.db('geosociomap');
    const projectCollection = db.collection('projects'); 
    const project = await projectCollection.findOne({ _id: new ObjectId(projectId) });

    if (!project) {
      return res.status(404).json({ message: 'Project not found' });
    }

    const deleteResult = await projectCollection.deleteOne({ _id: new ObjectId(projectId) });
    if (deleteResult.deletedCount === 0) {
      return res.status(404).json({ message: 'Project could not be deleted' });
    }

    res.json({ message: 'Project deleted successfully' });
  } catch (error) {
    console.error('Error deleting project:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

app.get('/projects', async (req, res) => {
  try {
    const projects = await Project.find();
    res.json(projects);
  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
});

app.get('/projects/:userId', async (req, res) => {
  try {
    const client = await connectToMongoDB();
    console.log("/projects/:userId");

    const userId = req.params.userId;
    console.log('User ID:', userId);

    const db = client.db('geosociomap');
    const userCollection = db.collection('users'); 
    const projectCollection = db.collection('projects');

    const user = await userCollection.findOne({ uid: userId });

    if (!user) {
      console.log('User not found');
      return res.status(404).json({ message: 'User not found' });
    }

    const email = user.email;
    const projects = await projectCollection.find({ userIds: userId }).toArray();
    if (projects.length === 0) {
      console.log('No projects found for this user');
      return res.status(404).json({ message: 'No projects found for this user' });
    } else {
      console.log('Projects found:', projects);
    }

    const projectsWithEmail = await Promise.all(projects.map(async (project) => {
      const updatedUserIds = await Promise.all(project.userIds.map(async (id) => {
        const user = await userCollection.findOne({ uid: id });
        return user ? user.email : id; 
      }));

      return { ...project, userIds: updatedUserIds };
    }));

   
    res.json(projectsWithEmail);

  } catch (error) {
    console.error('Error fetching projects:', error);
    res.status(500).json({ error: 'Error fetching projects' });
  }
});

app.post('/api/getUserEmails', async (req, res) => {
  const { userIds } = req.body; 
  console.log(userIds);

  if (!Array.isArray(userIds) || userIds.length === 0) {
    return res.status(400).json({ message: 'Invalid or missing userIds' });
  }

  try {
    const client = await connectToMongoDB();
    const db = client.db('geosociomap');
    const collection = db.collection('users');

    const users = await collection
      .find({ uid: { $in: userIds } }) 
      .project({ email: 1, _id: 0 }) 
      .toArray();

    return res.status(200).json({
      message: 'Emails retrieved successfully',
      emails: users,
    });
  } catch (error) {
    console.error('Error fetching user emails:', error);
    return res.status(500).json({ message: 'Failed to fetch user emails', error: error.message });
  }
});




const { ObjectId } = require('mongodb');
app.get('/project/:projectId', async (req, res) => {
  try {
    const client = await connectToMongoDB();

    const projectId = req.params.projectId; 
    const db = client.db('geosociomap');
    const collection = db.collection('projects');

    const project = await collection.findOne({ _id: new ObjectId(projectId) });

    if (!project) {
      console.log('Project not found');
      return res.status(404).json({ message: 'Project not found' });
    } else {
      console.log('Project found:', project);
      return res.json(project);
    }
  } catch (error) {
    console.error('Error fetching project:', error);
    res.status(500).json({ message: 'Error fetching project' });
  }
});

app.post('/add-layer', async (req, res) => {
  try {
    const client = await connectToMongoDB();
    const db = client.db('geosociomap');
    const collection = db.collection('layers');

    const { projectId, layer } = req.body;  
    console.log("add-layer", projectId, layer); 

    if (!projectId || !layer) {
      return res.status(400).json({ error: 'Missing projectId or layer data' });
    }

    const layerWithProjectId = {
      ...layer,
      projectId, 
      createdAt: new Date(),
    };

    console.log("layerWithProjectId", layerWithProjectId);

    const result = await collection.insertOne(layerWithProjectId);
    if (result && result.insertedId) {
      res.status(201).json({ message: 'Layer added successfully', layer: { ...layerWithProjectId, _id: result.insertedId } });
    } else {
      throw new Error('Failed to insert layer');
    }
  } catch (error) {
    console.error('Failed to add layer:', error); 
    res.status(500).json({ error: 'Failed to add layer' }); 
  }
});


app.post('/share-layer', async (req, res) => {
  try {
    // เชื่อมต่อกับ MongoDB
    const client = await connectToMongoDB();
    const db = client.db('geosociomap');
    const collection = db.collection('layers');
    const projectCollection = db.collection('projects');
    const buildingAnswersCollection = db.collection('buildingAnswers');
    const relationshipsCollection = db.collection('relationships'); 


    const { projectId, layer, userId } = req.body; 
    console.log(projectId, layer, userId);

    if (!projectId || !layer || !userId) {
      return res.status(400).json({ error: 'Missing projectId, layer, or userId' });
    }

   
    const project = await projectCollection.findOne({ _id: new ObjectId(projectId) });
    if (!project) {
      return res.status(404).json({ error: 'Project not found' });
    }

   
    const teamMembers = project.userIds.filter(id => id !== userId);

   
    const newLayers = await Promise.all(teamMembers.map(async (memberId) => {
     
      const existingLayer = await collection.findOne({ id: layer.id, userId: memberId });

      if (existingLayer) {
        const updatedLayer = {
          ...layer,
          userId: memberId,
          sharedWith: [],
        };
        delete updatedLayer._id;

      
        await collection.updateOne(
          { id: layer.id, userId: memberId },
          { $set: updatedLayer }
        );

        await buildingAnswersCollection.deleteMany({ userId: memberId, layerId: layer.id });
        const buildingAnswers = await buildingAnswersCollection.find({ userId, layerId: layer.id }).toArray();
        const newBuildingAnswers = buildingAnswers.map(async (answer) => {
          const { _id, ...newAnswer } = answer;
          newAnswer.userId = memberId; 
          try {
            const answerResult = await buildingAnswersCollection.insertOne(newAnswer);
            return await buildingAnswersCollection.findOne({ _id: answerResult.insertedId });
          } catch (err) {
            console.error('Error inserting new building answer:', err);
            throw new Error('Failed to create new building answer');
          }
        });

      
        const newAnswers = await Promise.all(newBuildingAnswers);
        await relationshipsCollection.deleteMany({ userId: memberId, layerId: layer.id });
        const relationships = await relationshipsCollection.find({ userId, layerId: layer.id }).toArray();
        const newRelationships = relationships.map(async (relation) => {
          const { _id, ...newRelation } = relation;
          newRelation.userId = memberId;
          try {
            const result = await relationshipsCollection.insertOne(newRelation);
            return await relationshipsCollection.findOne({ _id: result.insertedId });
          } catch (err) {
            console.error('Error inserting new relationship:', err);
            throw new Error('Failed to create new relationship');
          }
        });
        const newRelations = await Promise.all(newRelationships);

        console.log(`Building answers and relationships updated for member ${memberId}, layer ID: ${layer.id}`);



        return { memberId, layerId: layer._id, newAnswers, newRelations };
      } else {
      
        const newLayer = {
          ...layer,
          userId: memberId,
          sharedWith: [],
          createdAt: new Date(),
        };

      
        const maxOrderLayer = await collection.find({ projectId }).sort({ order: -1 }).limit(1).toArray();
        const newOrder = maxOrderLayer.length > 0 ? maxOrderLayer[0].order + 1 : 1;
        newLayer.order = newOrder;

       
        const result = await collection.insertOne(newLayer);

      
        if (result.insertedId) {
          console.log(`Layer created for member ${memberId}, ID: ${result.insertedId}`);

         
          const buildingAnswers = await buildingAnswersCollection.find({ userId, layerId: layer.id }).toArray();
          console.log(buildingAnswers)
        
          const newBuildingAnswers = buildingAnswers.map(async (answer) => {
          
            const { _id, ...newAnswer } = answer;
            newAnswer.userId = memberId; 

            try {
            
              const answerResult = await buildingAnswersCollection.insertOne(newAnswer);

        
              const insertedAnswer = await buildingAnswersCollection.findOne({ _id: answerResult.insertedId });

              return insertedAnswer; 
            } catch (err) {
              console.error('Error inserting new building answer:', err);
              throw new Error('Failed to create new building answer');
            }
          });

      
          const newAnswers = await Promise.all(newBuildingAnswers);
       
          const relationships = await relationshipsCollection.find({ userId, layerId: layer.id }).toArray();
          console.log(relationships);

          const newRelationships = relationships.map(async (relation) => {
            const { _id, ...newRelation } = relation;
            newRelation.userId = memberId;
            try {
              const result = await relationshipsCollection.insertOne(newRelation);
              return await relationshipsCollection.findOne({ _id: result.insertedId });
            } catch (err) {
              console.error('Error inserting new relationship:', err);
              throw new Error('Failed to create new relationship');
            }
          });

     
          const createdRelationships = await Promise.all(newRelationships);
          console.log(`Relationships created for member ${memberId}, layer ID: ${result.insertedId}`);


          return { memberId, layerId: result.insertedId, answers: newAnswers, createdRelationships };
        } else {
          throw new Error('Failed to create layer for member');
        }
      }
    }));


  
    const updatedLayer = {
      ...layer,
      userId: userId,
      sharedWith: teamMembers,
    };

    delete updatedLayer._id;
    console.log("userId");
    console.log(userId);

    const updatedLayerResult = await collection.findOneAndUpdate(
      { _id: new ObjectId(layer._id), userId: userId },
      { $set: updatedLayer },
      { returnDocument: 'after' } 
    );

    console.log(updatedLayerResult);

    res.status(201).json({ message: 'Layer updated or added successfully', layers: updatedLayerResult });
  } catch (error) {
    console.error('Failed to add layer:', error);
    res.status(500).json({ error: 'Failed to add or update layer' });
  }
});



app.delete('/layers/:id', async (req, res) => {
  const { id } = req.params; 
  //done
  try {
    const client = await connectToMongoDB();
    const db = client.db('geosociomap');
    const collection = db.collection('layers');

 
    const result = await collection.deleteOne({ id });

    if (result.deletedCount > 0) {
      return res.status(200).json({ message: 'Layer deleted successfully' });
    } else {
      return res.status(404).json({ message: 'Layer not found' });
    }
  } catch (error) {
    console.error('Error deleting layer:', error);
    res.status(500).json({ message: 'Failed to delete layer', error: error.message });
  }
});

app.get('/layers/:projectId', async (req, res) => {
  const client = await connectToMongoDB();

  const projectId = req.params.projectId; 
  const userId = req.query.userId; 
  const db = client.db('geosociomap');
  const collection = db.collection('layers');

  console.log("Get layers from projectId:", projectId, "for userId:", userId);

  try {
    const layers = await collection
      .find({ projectId, userId })  
      .sort({ order: 1 }) 
      .toArray(); 

    if (layers.length === 0) {
      console.log('No layers found for this project and user');
      return res.status(200).json([]); 
    }

    res.status(200).json(layers);
  } catch (error) {
    console.error('Failed to fetch layers:', error);
 
    return res.status(200).json({ layers: [] }); 
  }
});

app.get('/layers', async (req, res) => {
  const client = await connectToMongoDB();
  const userId = req.query.userId; 
  const db = client.db('geosociomap');
  const layersCollection = db.collection('layers');
  const usersCollection = db.collection('users'); 

  console.log("Get all layers grouped by projectId for userId:", userId);

  try {
    const layers = await layersCollection
      .find({ userId })
      .sort({ projectId: 1, order: 1 }) 
      .toArray();

    if (layers.length === 0) {
      console.log('No layers found for this user');
      return res.status(200).json({ projects: [] }); 
    }

  
    const user = await usersCollection.findOne({ uid: userId });
    const userEmail = user ? user.email : null;

    if (!userEmail) {
      console.log('User email not found');
      return res.status(404).json({ error: 'User email not found' });
    }

    const groupedLayers = layers.reduce((result, layer) => {
      const projectId = layer.projectId;
      if (!result[projectId]) {
        result[projectId] = []; 
      }

      if (layer.sharedWith && Array.isArray(layer.sharedWith)) {
        layer.sharedWith = layer.sharedWith.map(async (sharedUserId) => {
          const sharedUser = await usersCollection.findOne({ uid: sharedUserId });
          return sharedUser ? sharedUser.email : sharedUserId;
        });
      }

      layer.userId = userEmail; 

      result[projectId].push(layer);
      return result;
    }, {});

  
    const projects = Object.keys(groupedLayers).map((projectId) => ({
      projectId,
      layers: groupedLayers[projectId],
    }));

    res.status(200).json({ projects }); 
  } catch (error) {
    console.error('Failed to fetch layers:', error);
   
    return res.status(200).json({ projects: [] }); 
  }
});



app.get('/users/emails', async (req, res) => {


  try {
  
    const client = await connectToMongoDB();

    const db = client.db('geosociomap');
    const collection = db.collection('users');

    console.log("Fetching all user emails...");
    const users = await collection.find({}, { projection: { email: 1, _id: 0 } }).toArray();

    if (users.length === 0) {
      console.log('No users found');
      return res.status(200).json({ emails: [] }); 
    }

  
    const emails = users.map(user => user.email);
    res.status(200).json({ emails });
  } catch (error) {
    console.error('Failed to fetch user emails:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

app.post('/textbuilding/save', async (req, res) => {
  const { userId, projectId, coordinates, description } = req.body;  

  if (!userId || !projectId || !coordinates || !description) {
    return res.status(400).json({ message: 'Missing required fields' });
  }

  try {
    const client = await connectToMongoDB();  
    const db = client.db('geosociomap');
    const collection = db.collection('TextBuilding');

    const existingTextBuilding = await collection.findOne({
      userId,
      projectId,
      coordinates: { $eq: coordinates } 
    });

 
    if (existingTextBuilding) {
    
      const result = await collection.updateOne(
        { _id: existingTextBuilding._id }, 
        { $set: { description } } 
      );

      if (result.modifiedCount > 0) {
        res.status(200).json({ message: 'TextBuilding updated successfully', data: result });
      } else {
        res.status(404).json({ message: 'No changes detected' });
      }
    } else {
    
      const dataToSave = {
        userId,
        projectId,
        coordinates,
        description
      };

      const result = await collection.insertOne(dataToSave);  

      res.status(201).json({ message: 'TextBuilding created successfully', data: result });
    }
  } catch (error) {
    console.error('Error saving data to MongoDB:', error);
    res.status(500).json({ message: 'Failed to save data', error: error.message });
  }
});

app.delete('/textbuilding/delete', async (req, res) => {
  const { userId, projectId, coordinates } = req.body; 

  if (!userId || !projectId || !coordinates) {
    return res.status(400).json({ message: 'Missing required fields' });
  }

  try {
    const client = await connectToMongoDB(); 
    const db = client.db('geosociomap');
    const collection = db.collection('TextBuilding');

   
    const existingTextBuilding = await collection.findOne({
      userId,
      projectId,
      coordinates: { $eq: coordinates },  
    });

    if (!existingTextBuilding) {
     
      return res.status(404).json({ message: 'TextBuilding not found' });
    }

   
    const result = await collection.deleteOne({ _id: existingTextBuilding._id }); 

    if (result.deletedCount > 0) {
      res.status(200).json({ message: 'TextBuilding deleted successfully' });
    } else {
      res.status(500).json({ message: 'Failed to delete TextBuilding' });
    }
  } catch (error) {
    console.error('Error deleting data from MongoDB:', error);
    res.status(500).json({ message: 'Failed to delete data', error: error.message });
  }
});

app.put('/layers/update/:id', async (req, res) => {
  const { id } = req.params; 
  const { userId, isDeleted } = req.body; 
  const updatedLayer = req.body; 

  try {
    const client = await connectToMongoDB(); 
    const db = client.db('geosociomap');
    const collection = db.collection('layers');

    delete updatedLayer._id;

    const currentLayer = await collection.findOne({ id, userId });

    if (!currentLayer) {
      return res.status(404).json({ message: 'Layer not found for this user' });
    }

    if (id.startsWith('layer-symbol-') && Array.isArray(updatedLayer.markers)) {
      const uniqueMarkers = [];
      const markerSet = new Set();

      updatedLayer.markers.forEach((marker) => {
        const key = `${marker.lat}-${marker.lng}`;
        if (!markerSet.has(key)) {
          markerSet.add(key);
          uniqueMarkers.push(marker);
        }
      });

      updatedLayer.markers = uniqueMarkers;
    }

    const changes = { updatedAt: new Date() }; 

    Object.keys(updatedLayer).forEach((key) => {
      if (updatedLayer[key] !== currentLayer[key]) {
        changes[key] = updatedLayer[key];
      }
    });

    if (typeof isDeleted !== 'undefined') {
      changes.isDeleted = isDeleted;
    }

    if (Object.keys(changes).length > 0) {
      const result = await collection.updateOne(
        { id, userId },
        { $set: changes } 
      );

      if (result.modifiedCount > 0) {
        return res.status(200).json({ 
          message: 'Layer updated successfully', 
          updatedFields: changes 
        });
      } else {
        return res.status(404).json({ message: 'Layer not found or no changes detected' });
      }
    } else {
      return res.status(200).json({ message: 'No changes detected' });
    }
  } catch (error) {
    console.error('Error updating layer:', error);
    return res.status(500).json({ message: 'Failed to update layer', error: error.message });
  }
});



app.post('/layers/sync', async (req, res) => {
  try {
    const { projectId, layers } = req.body;

    if (!projectId || !Array.isArray(layers)) {
      return res.status(400).json({ message: 'Invalid data. projectId and layers are required.' });
    }

    const client = await connectToMongoDB();
    const db = client.db('geosociomap');
    const collection = db.collection('layers');

    const existingLayers = await collection.find({ projectId }).toArray();
    const existingLayerIds = new Set(existingLayers.map(layer => layer.id)); 

    const layersToAdd = [];
    const layersToUpdate = [];
    const incomingLayerIds = new Set();

    layers.forEach(layer => {
      incomingLayerIds.add(layer.id); 

      if (!existingLayerIds.has(layer.id)) {
        layersToAdd.push({ ...layer, projectId, createdAt: new Date() });
      } else {
        const existingLayer = existingLayers.find(l => l.id === layer.id);
        if (new Date(layer.lastUpdate) > new Date(existingLayer.lastUpdate)) {
          layersToUpdate.push(layer);
        }
      }
    });

    const layersToDelete = existingLayers.filter(layer => !incomingLayerIds.has(layer.id));

    if (layersToAdd.length > 0) {
      await collection.insertMany(layersToAdd);
    }

    for (const layer of layersToUpdate) {
      const { id, ...updateData } = layer;
      await collection.updateOne(
        { id, projectId },
        { $set: updateData }
      );
    }

    if (layersToDelete.length > 0) {
      const idsToDelete = layersToDelete.map(layer => layer.id);
      await collection.deleteMany({ id: { $in: idsToDelete }, projectId });
    }

    res.status(200).json({
      message: 'Sync completed successfully',
      added: layersToAdd.length,
      updated: layersToUpdate.length,
      deleted: layersToDelete.length,
    });
  } catch (error) {
    console.error('Error during sync:', error);
    res.status(500).json({ message: 'Failed to sync layers', error: error.message });
  }
});

app.get('/textbuilding/data', async (req, res) => {
  const { projectId, userId } = req.query;

  if (!projectId || !userId) {
    return res.status(400).json({ message: 'Project ID and User ID are required' });
  }

  try {
    const client = await connectToMongoDB();
    const db = client.db('geosociomap');
    const collection = db.collection('TextBuilding');

    const documents = await collection.find({ projectId, userId }).toArray();

    if (documents.length === 0) {
      return res.status(404).json({ message: 'No data found for this project and user' });
    }

    res.status(200).json(documents);
  } catch (error) {
    console.error('Error fetching data:', error);
    res.status(500).json({ message: 'Failed to fetch data', error: error.message });
  }
});

app.post('/relationships/sync', async (req, res) => {
  try {
    const { projectId, relationships } = req.body;

    if (!projectId || !Array.isArray(relationships)) {
      return res.status(400).json({ message: 'Invalid data. projectId and relationships are required.' });
    }

    const client = await connectToMongoDB();
    const db = client.db('geosociomap');
    const collection = db.collection('relationships');

    const existingRelationships = await collection.find({ projectId }).toArray();
    const existingRelationshipIds = new Set(existingRelationships.map(relationship => relationship.id)); 

    const relationshipsToAdd = [];
    const relationshipsToUpdate = [];
    const incomingRelationshipIds = new Set();

    relationships.forEach(relationship => {
      incomingRelationshipIds.add(relationship.id); 

      if (!existingRelationshipIds.has(relationship.id)) {
        relationshipsToAdd.push({ ...relationship, projectId, createdAt: new Date() });
      } else {
        const existingRelationship = existingRelationships.find(r => r.id === relationship.id);
        if (new Date(relationship.lastUpdate) > new Date(existingRelationship.lastUpdate)) {
          relationshipsToUpdate.push(relationship);
        }
      }
    });

    const relationshipsToDelete = existingRelationships.filter(relationship => !incomingRelationshipIds.has(relationship.id));

    if (relationshipsToAdd.length > 0) {
      await collection.insertMany(relationshipsToAdd);
    }

    for (const relationship of relationshipsToUpdate) {
      const { id, ...updateData } = relationship;
      await collection.updateOne(
        { id, projectId },
        { $set: updateData }
      );
    }

    if (relationshipsToDelete.length > 0) {
      const idsToDelete = relationshipsToDelete.map(relationship => relationship.id);
      await collection.deleteMany({ id: { $in: idsToDelete }, projectId });
    }

    res.status(200).json({
      message: 'Sync completed successfully',
      added: relationshipsToAdd.length,
      updated: relationshipsToUpdate.length,
      deleted: relationshipsToDelete.length,
    });
  } catch (error) {
    console.error('Error during sync:', error);
    res.status(500).json({ message: 'Failed to sync relationships', error: error.message });
  }
});


app.post('/buildings/sync', async (req, res) => {
  try {
    const { layerId, buildingAnswers } = req.body;
    console.log(buildingAnswers);

    
    if (!layerId || !Array.isArray(buildingAnswers)) {
      return res.status(400).json({ message: 'Invalid data. layerId and buildingAnswers are required.' });
    }

    const client = await connectToMongoDB();
    const db = client.db('geosociomap');
    const collection = db.collection('buildingAnswers');

   
    const receivedBuildingIds = buildingAnswers.map((b) => b.id);
    const bulkOps = await Promise.all(buildingAnswers.map(async (building) => {
      if (building.id && ObjectId.isValid(building.id)) {
        const existingBuilding = await collection.findOne({ _id: new ObjectId(building.id)});

        if (existingBuilding) {
          return {
            updateOne: {
              filter: {_id: new ObjectId(building.id)},
              update: {
                $set: {
                  answers: building.answers,
                  color: building.color,
                  coordinates: building.coordinates,
                  lastModified: new Date(),
                  // projectId: building.projectId,
                  // userId: building.userId,
                },
              },
              upsert: false, 
            },
          };
        }
      }

      return {
        insertOne: {
          document: {
            layerId,
            buildingId: building.buildingId,
            answers: building.answers,
            color: building.color,
            coordinates: building.coordinates,
            lastModified: new Date(),
            projectId: building.projectId,
            userId: building.userId,
          },
        },
      };
    }));

    if (bulkOps.length > 0) {
      await collection.bulkWrite(bulkOps);
    }

    return res.status(200).json({
      message: 'Sync completed',
      inserted: bulkOps.filter(op => op.insertOne).length,
      updated: bulkOps.filter(op => op.updateOne).length,
      // deleted: deleteResult.deletedCount,
    });

  } catch (error) {
    console.error('Sync error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});



app.put('/layers/:layerId/order', async (req, res) => {
  const { layerId } = req.params;
  const { newOrder } = req.body;

  try {
    const layer = await Layer.findById(layerId);
    if (!layer) return res.status(404).json({ error: 'Layer not found' });
    layer.order = newOrder;
    await layer.save();

    res.status(200).json({ message: 'Layer order updated successfully', layer });
  } catch (error) {
    res.status(500).json({ error: 'Failed to update layer order' });
  }
});

app.put('/notes/save/:projectId', async (req, res) => {
  const { projectId } = req.params;
  const layer = req.body; 
  console.log("Incoming layer data:", layer);
  console.log("Project ID:", projectId);

  try {
    const client = await connectToMongoDB(); 
    const db = client.db('geosociomap'); 
    const collection = db.collection('notes'); 

    const existingLayer = await collection.findOne({
      projectId,
      userId: layer.userId, 
    });


    const isChanged =
      existingLayer &&
      (JSON.stringify(existingLayer.items) !== JSON.stringify(layer.items) ||
        existingLayer.note !== layer.note ||
        JSON.stringify(existingLayer.imageUrls) !== JSON.stringify(layer.imageUrls) ||
        JSON.stringify(existingLayer.attachments) !== JSON.stringify(layer.attachments) ||
        existingLayer.visible !== layer.visible);

    if (isChanged) {
      console.log("Data has changed, updating in database");

      const result = await collection.updateOne(
        { projectId, userId: layer.userId }, 
        {
          $set: {
            items: layer.items,
            note: layer.note,
            imageUrls: layer.imageUrls,
            attachments: layer.attachments,
            visible: layer.visible,
            userId: layer.userId, 
            updatedAt: new Date(),
          },
        },
        { upsert: true } 
      );

      res.status(200).json({ message: "Note updated successfully", result });
    } else {
      console.log("No changes detected, not updating.");
      res.status(200).json({ message: "No changes detected, data not updated" });
    }
  } catch (error) {
    console.error("Error saving note:", error);
    res.status(500).json({ error: "Failed to save note data" });
  }
});


app.get('/notes/:projectId/:userId', async (req, res) => {
  const { projectId, userId } = req.params; 

  try {
    const client = await connectToMongoDB();
    const db = client.db('geosociomap');
    const collection = db.collection('notes');
    const note = await collection.findOne({ projectId: projectId, userId: userId });

    if (!note) {
      return res.status(404).json({ message: 'Note not found' });
    }

    return res.status(200).json(note);
  } catch (error) {
    console.error('Error fetching note:', error);
    return res.status(500).json({ message: 'Failed to fetch note', error: error.message });
  }
});


app.post('/layers/:layerId/buildings/:buildingId/answers', async (req, res) => {
  console.log("Selected Layer ID:", req.params);

  try {
    const client = await connectToMongoDB();
    const { layerId, buildingId } = req.params;
    const { buildingAnswers, color, coordinates, userId, projectId, lastModified } = req.body;
    console.log(layerId, buildingId, buildingAnswers, color, coordinates, userId, projectId)
    const db = client.db('geosociomap');
    const collection = db.collection('buildingAnswers');
    const layersCollection = db.collection('layers');

    const layer = await layersCollection.findOne({ id: layerId });

    if (!layer) {
      return res.status(404).json({ message: 'Layer not found' });
    }

    await layersCollection.updateOne(
      { id: layerId },
      { $set: { sharedWith: [] } }
    );
    await collection.updateOne(
      { layerId, buildingId }, 
      {
        $set: {
          answers: buildingAnswers,
          color: color || "#d1d5db", 
          coordinates: coordinates || [0, 0], 
          userId: userId,
          projectId: projectId,
          lastModified: lastModified,
          isDelete: false,
        },
      },
      { upsert: true } 
    );

    return res.status(200).json({ message: 'Data saved successfully' });
  } catch (error) {
    console.error('Error saving data:', error);
    return res.status(500).json({ message: 'Failed to save data', error: error.message });
  }
});

app.get('/layers/:layerId/buildings/:buildingId/answers', async (req, res) => {
  const { layerId, buildingId } = req.params;

  try {
    const client = await connectToMongoDB();
    const db = client.db('geosociomap');
    const collection = db.collection('buildingAnswers');

    const data = await collection.findOne({ layerId, buildingId });

    if (!data) {
      return res.status(404).json({ message: 'Data not found' });
    }

    return res.status(200).json(data);
  } catch (error) {
    console.error('Error fetching data:', error);
    return res.status(500).json({ message: 'Failed to fetch data', error: error.message });
  }
});

app.get('/layers/:layerId/buildings', async (req, res) => {
  const { layerId } = req.params;
  const { userId } = req.query;  

  try {
    const client = await connectToMongoDB();
    const db = client.db('geosociomap');
    const collection = db.collection('buildingAnswers');

    const query = { layerId };
    if (userId) {
      query.userId = userId;  
    }

    const data = await collection.find(query).toArray();

    if (!data || data.length === 0) {
      return res.status(404).json({ message: 'No data found for the specified layer and user' });
    }

    return res.status(200).json(data);
  } catch (error) {
    console.error('Error fetching data:', error);
    return res.status(500).json({ message: 'Failed to fetch data', error: error.message });
  }
});

app.get('/project/:projectId/layers/buildings', async (req, res) => {
  const { projectId } = req.params;

  try {
    const client = await connectToMongoDB();
    const db = client.db('geosociomap');
    const collection = db.collection('buildingAnswers');

    const layers = await db.collection('layers').find({ projectId }).toArray(); 

    if (!layers || layers.length === 0) {
      return res.status(404).json({ message: 'No layers found for the specified project' });
    }

    const layerDataPromises = layers.map(async (layer) => {
      const data = await collection.find({ layerId: layer.id }).toArray();
      return { layerId: layer.id, data };
    });

    const allLayerData = await Promise.all(layerDataPromises);

    return res.status(200).json(allLayerData);
  } catch (error) {
    console.error('Error fetching project layers data:', error);
    return res.status(500).json({ message: 'Failed to fetch data', error: error.message });
  }
});

app.post('/api/relationships', async (req, res) => {
  const newRelationship = {
    ...req.body,
    createdAt: new Date(),
  };

  if (!newRelationship.layerId || !newRelationship.points || !Array.isArray(newRelationship.points) || newRelationship.points.length === 0 ||
    !newRelationship.userId) {
    return res.status(400).json({ message: 'layerId and points are required, and points must be a non-empty array' });
  }

  if (!newRelationship.type || !newRelationship.description) {
    return res.status(400).json({ message: 'type and description are required' });
  }

  console.log("Received new relationship:", newRelationship);

  try {
    const client = await connectToMongoDB();
    const db = client.db('geosociomap');
    const collection = db.collection('relationships');

    const existingRelationship = await collection.findOne({
      layerId: newRelationship.layerId,
      userId: newRelationship.userId,
      points: { $in: [newRelationship.points] }
    });

    if (existingRelationship) {
      return res.status(400).json({ message: 'Relationship with the same points already exists' });
    }

    const result = await collection.insertOne(newRelationship);

    console.log("Insert result:", result);

    return res.status(201).json({
      message: 'Relationship added successfully',
      data: {
        id: result.insertedId,  
        ...newRelationship, 
      },
    });
  } catch (error) {
    console.error('Error inserting relationship:', error);
    return res.status(500).json({ message: 'Failed to insert relationship', error: error.message });
  }
});


app.get('/api/relationships', async (req, res) => {
  const { projectId, userId } = req.query; 
  console.log("/api/relationships", projectId, userId)
  try {
    const client = await connectToMongoDB();
    const db = client.db('geosociomap');
    const collection = db.collection('relationships');

    if (!projectId || !userId) {
      return res.status(400).json({ message: 'Missing required query parameters: projectId or userId' });
    }
    const filter = { projectId, userId };
    const relationships = await collection.find(filter).toArray();

    if (relationships.length === 0) {
      return res.status(404).json({ message: 'No relationships found for the specified criteria' });
    }
    return res.status(200).json(relationships);
  } catch (error) {
    console.error('Error fetching relationships:', error);
    return res.status(500).json({
      message: 'Failed to fetch relationships',
      error: error.message,
    });
  }
});


app.get('/api/relationships/:layerId', async (req, res) => {
  const { layerId } = req.params;

  try {
    const client = await connectToMongoDB();
    const db = client.db('geosociomap');
    const collection = db.collection('relationships');

    const data = await collection.find({ layerId }).toArray();

    if (!data || data.length === 0) {
      return res.status(404).json({ message: 'No relationships found for the specified layerId' });
    }

    return res.status(200).json(data);
  } catch (error) {
    console.error('Error fetching data by layerId:', error);
    return res.status(500).json({ message: 'Failed to fetch data', error: error.message });
  }
});

app.delete('/api/relationships/:id', async (req, res) => {
  // done
  const { id } = req.params;
  const { userId } = req.body;  

  try {
    const client = await connectToMongoDB();
    const db = client.db('geosociomap'); 
    const collection = db.collection('relationships'); 

   
    const result = await collection.deleteOne({ id: id, userId: userId });
    if (result.deletedCount === 0) {
      return res.status(404).json({ message: 'Relationship not found or unauthorized' });
    }

    return res.status(200).json({ message: `Relationship with id ${id} deleted successfully` });
  } catch (error) {
    console.error('Error deleting relationship:', error);
    return res.status(500).json({ message: 'Failed to delete relationship', error: error.message });
  }
});

app.put('/api/relationships/:id', async (req, res) => {
  const { id } = req.params;
  const { description, type, userId, isDelete } = req.body; 

  try {
    const client = await connectToMongoDB();
    const db = client.db('geosociomap');
    const collection = db.collection('relationships');

    const relationship = await collection.findOne({ id, userId });

    if (!relationship) {
      return res.status(404).json({ message: 'Relationship not found or unauthorized' });
    }

    const result = await collection.updateOne(
      { id, userId },
      { 
        $set: { 
          description, 
          type, 
          isDelete,
          updatedAt: new Date() 
        } 
      }
    );

    if (result.modifiedCount === 0) {
      return res.status(404).json({ message: 'Relationship not updated' });
    }

    return res.status(200).json({
      message: `Relationship with id ${id} updated successfully`,
      updatedFields: { description, type, isDelete, updatedAt: new Date() }, 
    });
  } catch (error) {
    console.error('Error updating relationship:', error);
    return res.status(500).json({ message: 'Failed to update relationship', error: error.message });
  }
});



app.post('/api/createBuilding', async (req, res) => {
  const { buildingId, coordinates, projectId, userId } = req.body;

  if (!buildingId || !coordinates || coordinates.length !== 4 || !projectId || !userId) {
    return res.status(400).json({ message: 'Invalid data. Please provide buildingId, coordinates (with 4 points), and projectId.' });
  }

  try {
    const client = await connectToMongoDB();
    const db = client.db('geosociomap');
    const collection = db.collection('buildings'); 

   
    const buildingData = {
      buildingId,
      coordinates,
      projectId, 
      userId,
      createdAt: new Date(),
    };

  
    const result = await collection.insertOne(buildingData);

    if (!result.acknowledged) {
      return res.status(500).json({ message: 'Failed to insert building.' });
    }

    return res.status(201).json({
      message: 'Building created successfully',
      building: {
        ...buildingData,
        _id: result.insertedId, 
      },
    });
  } catch (error) {
    console.error('Error creating building:', error);
    return res.status(500).json({ message: 'Failed to create building', error: error.message });
  }
});


app.get('/api/getBuildings/:projectId', async (req, res) => {
  const { projectId } = req.params;
  const { userId } = req.query; 

  try {
    const client = await connectToMongoDB();
    const db = client.db('geosociomap');
    const collection = db.collection('buildings');
    const filter = { projectId };
    if (userId) {
      filter.userId = userId; 
    }

  
    const buildings = await collection.find(filter).toArray();
    if (buildings.length === 0) {
      return res.status(404).json({ message: 'No buildings found' });
    }

   
    const buildingsWithStringId = buildings.map((building) => ({
      ...building,
      _id: building._id.toString(),
    }));

    return res.status(200).json({
      message: 'Buildings retrieved successfully',
      buildings: buildingsWithStringId, 
    });
  } catch (error) {
    console.error('Error retrieving buildings:', error);
    return res.status(500).json({ message: 'Failed to retrieve buildings', error: error.message });
  }
});


app.delete('/api/deleteBuilding', async (req, res) => {
  const { buildingId } = req.body;

  if (!buildingId) {
    return res.status(400).json({ message: 'Invalid data. Please provide a valid buildingId.' });
  }

  try {
    const client = await connectToMongoDB(); 
    const db = client.db('geosociomap'); 
    const collection = db.collection('buildings'); 

   
    const result = await collection.deleteOne({ buildingId });

    if (result.deletedCount === 0) {
      return res.status(404).json({ message: 'Building not found or already deleted.' });
    }

    return res.status(200).json({ message: 'Building deleted successfully.' });
  } catch (error) {
    console.error('Error deleting building:', error);
    return res.status(500).json({ message: 'Failed to delete building', error: error.message });
  }
});

const port = process.env.PORT || 4000;

app.listen(port, () => {
  console.log(`Server running on http://localhost:${port}`);
});