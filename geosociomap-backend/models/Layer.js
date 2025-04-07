// models/Layer.js
const mongoose = require('mongoose');

const layerSchema = new mongoose.Schema({
  projectId: { type: mongoose.Schema.Types.ObjectId, required: true },
  id: { type: String, required: true },
  title: String,
  description: String,
  imageUrl: Object,
  markers: Array,
  paths: Array,
  visible: Boolean,
  order: Number,
});

module.exports = mongoose.model('Layer', layerSchema);
