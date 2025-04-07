const mongoose = require('mongoose');
const { Schema } = mongoose;

const noteSequenceSchema = new Schema({
    projectId: { type: String, required: true },
    items: { type: Array, required: true },
    note: { type: String, required: true },
    imageUrls: { type: [String], default: [] }, 
    attachments: { type: [Buffer], default: [] },
    visible: { type: Boolean, default: true }, 
});

const Note = mongoose.model('Note', noteSequenceSchema);

module.exports = Note;
