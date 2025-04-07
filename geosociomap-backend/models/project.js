const mongoose = require('mongoose');
const { Schema } = mongoose;


const projectSchema = new Schema({
  projectName: String,
  userId: String,
  selectedPoints: [{
    lat: Number,
    lng: Number
  }],
  createdAt: Date
});


const Project = mongoose.model('projects', projectSchema);


module.exports = Project;
